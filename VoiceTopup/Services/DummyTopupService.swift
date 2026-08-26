import Foundation

enum DummyTopupService {
    /// Set to `true` to force success, `false` to force failure, `nil` for random.
    static var shouldSucceed: Bool? = nil

    static func executeTopup(transaction: TopupTransaction) async -> TopupResult {
        // Simulate network delay 1–2 seconds
        try? await Task.sleep(for: .seconds(Double.random(in: 1.0...2.0)))

        let success: Bool
        if let forced = shouldSucceed {
            success = forced
        } else {
            success = Bool.random()
        }

        return success
            ? .success
            : .failure("Transaction failed. The server returned an error. Please try again.")
    }
}
