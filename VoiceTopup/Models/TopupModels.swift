import Foundation

struct ContactInfo: Codable, Equatable {
    let identifier: String
    let displayName: String
    let phoneNumber: String
}

struct ParsedTopup {
    let name: String
    let amount: Decimal
}

enum ParseResult {
    case success(ParsedTopup)
    case ambiguous(ParsedTopup)
    case noResult
}

struct TopupTransaction: Codable, Equatable {
    let contact: ContactInfo
    let amount: Decimal
    let currency: String
    let operatorName: String
    let date: Date
}

enum TopupResult {
    case success
    case failure(String)
}
