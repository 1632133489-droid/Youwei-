import SwiftUI

struct ChatView: View {
    @EnvironmentObject var store: ChatStore
    let conversationId: UUID
    @State private var inputText = ""
    @FocusState private var inputFocused: Bool

    private var conversation: Conversation? {
        store.conversations.first(where: { $0.id == conversationId })
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if let conv = conversation {
                            ForEach(conv.messages) { msg in
                                MessageBubble(message: msg)
                                    .id(msg.id)
                            }
                        }
                        if store.isStreaming && store.activeId == conversationId {
                            StreamingBubble(text: store.streamingText)
                                .id("streaming")
                        }
                    }
                    .padding()
                }
                .onChange(of: conversation?.messages.count) { _ in scrollToBottom(proxy) }
                .onChange(of: store.streamingText) { _ in scrollToBottom(proxy) }
                .onAppear { scrollToBottom(proxy) }
            }

            if let err = store.lastError {
                Text(err)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            Divider()
            HStack(alignment: .bottom, spacing: 8) {
                TextField("输入消息…", text: $inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($inputFocused)
                    .lineLimit(1...6)
                    .submitLabel(.send)
                    .onSubmit { send() }

                Button(action: send) {
                    Image(systemName: store.isStreaming ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !store.isStreaming)
            }
            .padding()
        }
        .navigationTitle(conversation?.title ?? "对话")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.activeId = conversationId }
    }

    private func send() {
        if store.isStreaming {
            store.stop()
            return
        }
        let text = inputText
        inputText = ""
        store.activeId = conversationId
        store.send(text)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if store.isStreaming {
                proxy.scrollTo("streaming", anchor: .bottom)
            } else if let last = conversation?.messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 4) {
                richText(message.content)
            }
            .padding(12)
            .background(message.isUser ? Color.blue : Color(.secondarySystemBackground))
            .foregroundColor(message.isUser ? .white : .primary)
            .cornerRadius(16)
            if !message.isUser { Spacer(minLength: 40) }
        }
    }

    @ViewBuilder
    private func richText(_ s: String) -> some View {
        if let attr = try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            Text(attr)
        } else {
            Text(s)
        }
    }
}

struct StreamingBubble: View {
    let text: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if text.isEmpty {
                    ProgressView().padding(4)
                } else {
                    Text(text)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            Spacer(minLength: 40)
        }
    }
}
