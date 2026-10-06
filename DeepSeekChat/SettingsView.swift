import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: ChatStore
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @State private var selectedModel: String = ChatModel.chat.rawValue
    @State private var checkResult: String?
    @State private var checking = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("DeepSeek API")) {
                    SecureField("sk-…", text: $apiKey)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    HStack {
                        Button(checking ? "检测中…" : "验证 Key") {
                            Task {
                                checking = true
                                checkResult = nil
                                let ok = await DeepSeekAPI.validate(apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
                                checkResult = ok ? "Key 有效 ✅" : "Key 无效或网络异常 ❌"
                                checking = false
                            }
                        }
                        .disabled(apiKey.isEmpty || checking)
                        if let r = checkResult {
                            Text(r).font(.caption).foregroundColor(.secondary)
                        }
                    }
                    Button("保存") {
                        let k = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        if k.isEmpty {
                            KeychainHelper.delete(forKey: DeepSeekAPI.apiKeyChainKey)
                        } else {
                            KeychainHelper.save(k, forKey: DeepSeekAPI.apiKeyChainKey)
                        }
                        dismiss()
                    }
                }

                Section(header: Text("默认模型（新对话）")) {
                    Picker("模型", selection: $selectedModel) {
                        ForEach(ChatModel.allCases) { m in
                            Text(m.displayName).tag(m.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedModel) { _ in
                        UserDefaults.standard.set(selectedModel, forKey: "default_model")
                    }
                }

                Section(header: Text("关于")) {
                    Text("Key 只保存在本机钥匙串，不上传到任何服务器。")
                        .font(.caption).foregroundColor(.secondary)
                    Text("版本 1.0")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear {
                apiKey = KeychainHelper.load(forKey: DeepSeekAPI.apiKeyChainKey) ?? ""
                selectedModel = UserDefaults.standard.string(forKey: "default_model") ?? ChatModel.chat.rawValue
            }
        }
    }
}
