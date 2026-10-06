import Foundation

enum DeepSeekAPI {
    static let baseURL = "https://api.deepseek.com/v1"
    static let apiKeyChainKey = "deepseek_api_key"

    struct StreamError: Error {
        let message: String
    }

    /// Streams a chat completion. Calls onToken with each text delta.
    static func streamChat(
        apiKey: String,
        model: String,
        messages: [[String: String]],
        onToken: @escaping (String) -> Void
    ) async throws {
        guard let url = URL(string: baseURL + "/chat/completions") else {
            throw StreamError(message: "URL 无效")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "stream": true
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw StreamError(message: "网络异常")
        }
        guard (200...299).contains(http.statusCode) else {
            var errText = "HTTP \(http.statusCode)"
            // try to read error body
            var errData = Data()
            for try await chunk in bytes { errData.append(chunk) }
            if let s = String(data: errData, encoding: .utf8), !s.isEmpty {
                errText = s
            }
            throw StreamError(message: errText)
        }

        for try await line in bytes.lines {
            guard line.hasPrefix("data:") else { continue }
            let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
            if payload == "[DONE]" { break }
            guard let data = payload.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let delta = choices.first?["delta"] as? [String: Any] else { continue }
            // reasoning models may put text in reasoning_content; prefer content
            if let text = delta["content"] as? String, !text.isEmpty {
                onToken(text)
            }
        }
    }

    /// Quick non-streaming check that the key works.
    static func validate(apiKey: String) async -> Bool {
        guard let url = URL(string: baseURL + "/models") else { return false }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}
