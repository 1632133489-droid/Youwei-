import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ChatStore
    @State private var showSettings = false
    @State private var searchText = ""

    var filtered: [Conversation] {
        if searchText.isEmpty { return store.conversations }
        return store.conversations.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { conv in
                    NavigationLink {
                        ChatView(conversationId: conv.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(conv.title).font(.headline).lineLimit(1)
                            Text(conv.updatedAt, style: .relative)
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    for i in offsets { store.delete(filtered[i]) }
                }
            }
            .navigationTitle("DeepSeek Chat")
            .searchable(text: $searchText, prompt: "搜索对话")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { store.newConversation() } label: { Image(systemName: "square.and.pencil") }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }
}
