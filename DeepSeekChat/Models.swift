import Foundation

struct ChatMessage: Identifiable, Codable {
    var id: UUID = UUID()
    var role: String // "user" or "assistant"
    var content: String
    var timestamp: Date = Date()

    var isUser: Bool { role == "user" }
}

struct Conversation: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var messages: [ChatMessage]
    var model: String
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

enum ChatModel: String, CaseIterable, Identifiable {
    case chat = "deepseek-chat"
    case reasoner = "deepseek-reasoner"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .chat: return "DeepSeek V3"
        case .reasoner: return "DeepSeek R1"
        }
    }
}
