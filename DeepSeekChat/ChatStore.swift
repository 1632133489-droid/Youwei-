import Foundation
import SwiftUI

@MainActor
final class ChatStore: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var activeId: UUID?
    @Published var isStreaming: Bool = false
    @Published var streamingText: String = ""
    @Published var lastError: String?

    var active: Conversation? {
        conversations.first(where: { $0.id == activeId })
    }

    private var saveURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("conversations.json")
    }

    init() {
        load()
        if conversations.isEmpty {
            newConversation()
        } else if activeId == nil {
            activeId = conversations.first?.id
        }
    }

    func newConversation(model: String? = nil) {
        let m = model ?? UserDefaults.standard.string(forKey: "default_model") ?? ChatModel.chat.rawValue
        let c = Conversation(title: "新的对话", messages: [], model: m)
        conversations.insert(c, at: 0)
        activeId = c.id
        save()
    }

    func delete(_ conversation: Conversation) {
        conversations.removeAll { $0.id == conversation.id }
        if activeId == conversation.id {
            activeId = conversations.first?.id
        }
        if conversations.isEmpty { newConversation() }
        save()
    }

    func renameActive(to title: String) {
        guard let i = conversations.firstIndex(where: { $0.id == activeId }) else { return }
        conversations[i].title = title
        save()
    }

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isStreaming else { return }
        guard let key = KeychainHelper.load(forKey: DeepSeekAPI.apiKeyChainKey), !key.isEmpty else {
            lastError = "请先在设置里填写 DeepSeek API Key"
            return
        }
        guard let idx = conversations.firstIndex(where: { $0.id == activeId }) else { return }

        conversations[idx].messages.append(ChatMessage(role: "user", content: trimmed))
        if conversations[idx].messages.count == 1 {
            conversations[idx].title = String(trimmed.prefix(18))
        }
        conversations[idx].updatedAt = Date()
        let model = conversations[idx].model
        let history = conversations[idx].messages.map { ["role": $0.role, "content": $0.content] }
        let convId = conversations[idx].id

        isStreaming = true
        streamingText = ""
        lastError = nil

        Task {
            do {
                try await DeepSeekAPI.streamChat(apiKey: key, model: model, messages: history) { token in
                    Task { @MainActor in
                        self.streamingText += token
                    }
                }
                let final = self.streamingText
                if let i = self.conversations.firstIndex(where: { $0.id == convId }), !final.isEmpty {
                    self.conversations[i].messages.append(ChatMessage(role: "assistant", content: final))
                    self.conversations[i].updatedAt = Date()
                    self.save()
                }
            } catch {
                self.lastError = "请求失败：\(error.localizedDescription)"
            }
            self.isStreaming = false
            self.streamingText = ""
        }
    }

    func stop() {
        // streaming task cancellation is best-effort; flag reset stops UI
        isStreaming = false
        streamingText = ""
    }

    // MARK: - persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(conversations)
            try data.write(to: saveURL, options: .atomic)
        } catch {
            print("save failed: \(error)")
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: saveURL)
            conversations = try JSONDecoder().decode([Conversation].self, from: data)
            conversations.sort { $0.updatedAt > $1.updatedAt }
        } catch {
            conversations = []
        }
    }
}
