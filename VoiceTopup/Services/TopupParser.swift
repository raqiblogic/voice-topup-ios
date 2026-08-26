import Foundation

enum TopupParser {

    static func parse(_ transcript: String) -> ParseResult {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .noResult }

        // Try structured English patterns
        if let result = parseEnglish(trimmed) {
            return .success(result)
        }

        // Try Bangla patterns
        if let result = parseBangla(trimmed) {
            return .success(result)
        }

        // Relaxed: just find *any* number and *any* remaining word
        if let result = parseRelaxed(trimmed) {
            return .ambiguous(result)
        }

        return .noResult
    }

    // MARK: - English

    private static func parseEnglish(_ text: String) -> ParsedTopup? {
        let lowered = text.lowercased()
        // "send 500 to Ammu", "send Tk 500 to Rahim", "send RM 50 to Mom", "reload 20 to John", "top up 100 for Sister"
        let patterns: [(pattern: String, amountGroup: Int, nameGroup: Int)] = [
            (#"(?:send|top\s*up|recharge|reload)\s+(?:tk\.?\s*|bdt\s*|৳\s*|rm\s*|myr\s*|ringgit\s*)?(\d[\d,]*\.?\d*)\s+(?:to|for)\s+(.+)"#, 1, 2),
            (#"(?:send|top\s*up|recharge|reload)\s+(.+?)\s+(\d[\d,]*\.?\d*)\s*(?:tk\.?|bdt|taka|৳|rm|myr|ringgit)?"#, 2, 1),
        ]

        for p in patterns {
            guard let regex = try? NSRegularExpression(pattern: p.pattern, options: .caseInsensitive) else { continue }
            let range = NSRange(lowered.startIndex..., in: lowered)
            guard let match = regex.firstMatch(in: lowered, range: range),
                  match.numberOfRanges > max(p.amountGroup, p.nameGroup),
                  let amtRange = Range(match.range(at: p.amountGroup), in: lowered),
                  let nameRange = Range(match.range(at: p.nameGroup), in: text) else { continue }

            let amountStr = String(lowered[amtRange])
            guard let amount = parseAmount(amountStr) else { continue }
            let name = cleanName(String(text[nameRange]))
            guard !name.isEmpty else { continue }
            return ParsedTopup(name: name, amount: amount)
        }
        return nil
    }

    // MARK: - Bangla

    private static func parseBangla(_ text: String) -> ParsedTopup? {
        let converted = convertBanglaDigits(text)

        let patterns: [(pattern: String, nameGroup: Int, amountGroup: Int)] = [
            // "আম্মুকে ৫০০ টাকা পাঠাও" or "আম্মুকে ৫০ রিঙ্গিত পাঠাও"
            (#"(.+?)(?:কে|ke)\s+(\d[\d,]*\.?\d*)\s*(?:টাকা|taka|রিঙ্গিত|ringgit|rm|৳)"#, 1, 2),
            (#"(\d[\d,]*\.?\d*)\s*(?:টাকা|taka|রিঙ্গিত|ringgit|rm|৳)\s+(.+?)(?:কে|ke)\s*(?:পাঠাও|pathao|দাও|dao|পাঠা)"#, 2, 1),
        ]

        for p in patterns {
            guard let regex = try? NSRegularExpression(pattern: p.pattern, options: .caseInsensitive) else { continue }
            let range = NSRange(converted.startIndex..., in: converted)
            guard let match = regex.firstMatch(in: converted, range: range),
                  match.numberOfRanges > max(p.nameGroup, p.amountGroup),
                  let nameRange = Range(match.range(at: p.nameGroup), in: converted),
                  let amtRange = Range(match.range(at: p.amountGroup), in: converted) else { continue }

            let amountStr = String(converted[amtRange])
            guard let amount = parseAmount(amountStr) else { continue }
            let name = cleanName(String(converted[nameRange]))
            guard !name.isEmpty else { continue }
            return ParsedTopup(name: name, amount: amount)
        }
        return nil
    }

    // MARK: - Relaxed (fallback → ambiguous)

    private static func parseRelaxed(_ text: String) -> ParsedTopup? {
        let converted = convertBanglaDigits(text)

        guard let regex = try? NSRegularExpression(pattern: #"(\d[\d,]*\.?\d*)"#),
              let match = regex.firstMatch(in: converted, range: NSRange(converted.startIndex..., in: converted)),
              let amtRange = Range(match.range(at: 1), in: converted),
              let amount = parseAmount(String(converted[amtRange])) else {
            return nil
        }

        var remaining = converted
        if let r = Range(match.range(at: 0), in: remaining) {
            remaining.replaceSubrange(r, with: " ")
        }

        let noise = [
            "send", "to", "tk", "bdt", "taka", "টাকা", "পাঠাও", "কে", "দাও",
            "recharge", "top", "up", "৳", "for", "reload", "rm", "myr", "ringgit", "রিঙ্গিত"
        ]
        for word in noise {
            remaining = remaining.replacingOccurrences(of: word, with: " ", options: .caseInsensitive)
        }

        let name = remaining
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        guard !name.isEmpty else { return nil }
        return ParsedTopup(name: name, amount: amount)
    }

    // MARK: - Helpers

    private static func parseAmount(_ str: String) -> Decimal? {
        let cleaned = str.replacingOccurrences(of: ",", with: "")
        guard let d = Decimal(string: cleaned), d > 0 else { return nil }
        return d
    }

    private static func cleanName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .punctuationCharacters)
    }

    private static func convertBanglaDigits(_ text: String) -> String {
        let map: [Character: Character] = [
            "০": "0", "১": "1", "২": "2", "৩": "3", "৪": "4",
            "৫": "5", "৬": "6", "৭": "7", "৮": "8", "৯": "9",
        ]
        return String(text.map { map[$0] ?? $0 })
    }
}
