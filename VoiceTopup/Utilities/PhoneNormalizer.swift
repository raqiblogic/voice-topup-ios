import Foundation

enum Country {
    case bangladesh
    case malaysia
    case unknown
}

enum PhoneNormalizer {
    /// Normalizes Bangladeshi and Malaysian phone numbers.
    static func normalize(_ phone: String) -> String {
        let cleaned = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = cleaned.filter { $0.isNumber }

        // Bangladesh: +8801XXXXXXXXX or 8801XXXXXXXXX → 01XXXXXXXXX (11 digits)
        if digits.count == 13, digits.hasPrefix("880") {
            return "0" + String(digits.dropFirst(3))
        }

        // Malaysia: +601XXXXXXXX or 601XXXXXXXX (11-12 digits with 60 prefix)
        // e.g. 60123456789 (11 digits) → +60123456789 or 0123456789
        if digits.hasPrefix("601") {
            if digits.count >= 11 && digits.count <= 13 {
                return "+60" + String(digits.dropFirst(2))
            }
        }

        // Bangladesh 11-digit starting with 01
        if digits.count == 11, digits.hasPrefix("01") {
            return digits
        }

        // Malaysia 10-digit starting with 01 (e.g. 0123456789)
        if digits.count == 10, digits.hasPrefix("01") {
            return digits
        }

        // 10 digits starting with 1 (missing leading 0 for BD)
        if digits.count == 10, digits.hasPrefix("1") {
            return "0" + digits
        }

        return digits
    }

    /// Detects whether the number is Bangladesh or Malaysia
    static func detectCountry(from phoneNumber: String) -> Country {
        let cleaned = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = cleaned.filter { $0.isNumber }

        if cleaned.hasPrefix("+60") || digits.hasPrefix("601") {
            return .malaysia
        }
        if cleaned.hasPrefix("+880") || digits.hasPrefix("880") {
            return .bangladesh
        }

        // 10-digit starting with 01 is typical Malaysian mobile (e.g. 012-xxx xxxx)
        if digits.count == 10, digits.hasPrefix("01") {
            return .malaysia
        }

        // 11-digit starting with 011 is Malaysian 011-xxxx xxxx
        if digits.count == 11, digits.hasPrefix("011") {
            return .malaysia
        }

        // 11-digit starting with 013-019 is typical Bangladesh
        if digits.count == 11, digits.hasPrefix("01") {
            return .bangladesh
        }

        return .unknown
    }
}
