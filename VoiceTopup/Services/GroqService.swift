import Foundation

enum GroqService {

    // MARK: - Types

    private struct ChatCompletion: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String?
            }
            let message: Message
        }
        let choices: [Choice]?
    }

    private struct ExtractedJSON: Decodable {
        let name: String?
        let amount: Double?
    }

    enum GroqError: LocalizedError {
        case noAPIKey
        case networkError(String)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .noAPIKey:            return "Groq API key not configured. Set it in Secrets.swift."
            case .networkError(let m): return "Network error: \(m)"
            case .invalidResponse:     return "Could not parse AI response."
            }
        }
    }

    // MARK: - Public

    static func extractTopup(from transcript: String) async throws -> ParsedTopup {
        let apiKey = Secrets.groqAPIKey
        guard !apiKey.isEmpty else { throw GroqError.noAPIKey }

        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            throw GroqError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        let body: [String: Any] = [
            "model": "llama-3.1-8b-instant",
            "messages": [
                [
                    "role": "system",
                    "content": "Extract the recipient name and amount from this mobile top-up request. Return ONLY valid JSON: {\"name\":\"<name>\",\"amount\":<number>}",
                ],
                ["role": "user", "content": transcript],
            ],
            "temperature": 0,
            "max_tokens": 60,
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let data: Data
        do {
            let (d, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw GroqError.invalidResponse
            }
            data = d
        } catch let e as GroqError {
            throw e
        } catch {
            throw GroqError.networkError(error.localizedDescription)
        }

        // Decode chat-completion wrapper
        guard let completion = try? JSONDecoder().decode(ChatCompletion.self, from: data),
              let content = completion.choices?.first?.message.content else {
            throw GroqError.invalidResponse
        }

        // Extract JSON from content (may be wrapped in markdown fences)
        let jsonString = extractJSONBlock(from: content)

        guard let jsonData = jsonString.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(ExtractedJSON.self, from: jsonData),
              let name = parsed.name, !name.isEmpty,
              let amount = parsed.amount, amount > 0 else {
            throw GroqError.invalidResponse
        }

        return ParsedTopup(name: name, amount: Decimal(amount))
    }

    // MARK: - Helpers

    private static func extractJSONBlock(from text: String) -> String {
        var cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let start = cleaned.firstIndex(of: "{"),
           let end = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[start...end])
        }
        return cleaned
    }
}
