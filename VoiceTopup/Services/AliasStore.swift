import Foundation
import Observation

@Observable
final class AliasStore {
    private let storageKey = "voicetopup_aliases"

    /// Maps alias name → CNContact identifier.
    var aliases: [String: String] {
        didSet { persist() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            self.aliases = decoded
        } else {
            self.aliases = [:]
        }
    }

    // MARK: - CRUD

    func addAlias(_ alias: String, contactIdentifier: String) {
        aliases[alias] = contactIdentifier
    }

    func removeAlias(_ alias: String) {
        aliases.removeValue(forKey: alias)
    }

    /// Case-insensitive lookup. Returns the contact identifier if found.
    func resolve(_ name: String) -> String? {
        let lowered = name.lowercased()
        for (alias, contactId) in aliases where alias.lowercased() == lowered {
            return contactId
        }
        return nil
    }

    // MARK: - Persistence

    private func persist() {
        if let data = try? JSONEncoder().encode(aliases) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
