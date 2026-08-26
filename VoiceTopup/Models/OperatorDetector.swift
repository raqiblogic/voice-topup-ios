import Foundation

enum MobileOperator: String, CaseIterable, Identifiable {
    // Bangladesh Operators
    case grameenphone = "Grameenphone (GP)"
    case robi = "Robi"
    case banglalink = "Banglalink"
    case teletalk = "Teletalk"
    case airtel = "Airtel"

    // Malaysia Operators
    case maxis = "Maxis / Hotlink"
    case celcomDigi = "CelcomDigi"
    case uMobile = "U Mobile"
    case unifi = "Unifi Mobile"
    case yes5G = "Yes 5G"

    case unknown = "Unknown"

    var id: String { rawValue }

    var suggestedCurrency: String {
        switch self {
        case .grameenphone, .robi, .banglalink, .teletalk, .airtel:
            return "৳"
        case .maxis, .celcomDigi, .uMobile, .unifi, .yes5G:
            return "RM"
        case .unknown:
            return "৳"
        }
    }

    /// Detects operator from a phone number using BD and MY prefix tables.
    static func detect(from phoneNumber: String) -> MobileOperator {
        let raw = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = raw.filter { $0.isNumber }
        guard !digits.isEmpty else { return .unknown }

        let country = PhoneNormalizer.detectCountry(from: raw)

        if country == .malaysia {
            return detectMalaysianOperator(digits: digits)
        } else if country == .bangladesh {
            return detectBangladeshiOperator(digits: digits)
        }

        // Fallback detection: try BD first, then MY
        let bdOp = detectBangladeshiOperator(digits: digits)
        if bdOp != .unknown { return bdOp }
        return detectMalaysianOperator(digits: digits)
    }

    private static func detectBangladeshiOperator(digits: String) -> MobileOperator {
        // Strip 880 if present
        var local = digits
        if local.hasPrefix("880") {
            local = String(local.dropFirst(3))
        }
        if !local.hasPrefix("0") && local.hasPrefix("1") {
            local = "0" + local
        }
        guard local.count >= 3 else { return .unknown }
        let prefix3 = String(local.prefix(3))

        switch prefix3 {
        case "017", "013": return .grameenphone
        case "018":        return .robi
        case "016":        return .airtel
        case "019", "014": return .banglalink
        case "015":        return .teletalk
        default:           return .unknown
        }
    }

    private static func detectMalaysianOperator(digits: String) -> MobileOperator {
        // Strip 60 if present
        var local = digits
        if local.hasPrefix("60") {
            local = String(local.dropFirst(2))
        }
        if !local.hasPrefix("0") && local.hasPrefix("1") {
            local = "0" + local
        }
        guard local.count >= 3 else { return .unknown }

        let prefix4 = local.count >= 4 ? String(local.prefix(4)) : ""
        let prefix3 = String(local.prefix(3))

        // Check 4-digit prefixes first
        if prefix4 == "0142" { return .maxis }
        if ["0143", "0146", "0148", "0149"].contains(prefix4) { return .celcomDigi }
        if ["0114", "0117"].contains(prefix4) { return .uMobile }
        if ["0111", "0115"].contains(prefix4) { return .unifi }
        if ["0118"].contains(prefix4) { return .yes5G }

        // Check 3-digit prefixes
        switch prefix3 {
        case "012", "017":        return .maxis
        case "019", "013", "016", "010": return .celcomDigi
        case "018":               return .uMobile
        case "011":               return .celcomDigi
        default:                  return .unknown
        }
    }
}

// Backward compatibility alias if needed
typealias BDOperator = MobileOperator
