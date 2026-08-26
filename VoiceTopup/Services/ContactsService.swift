import Foundation
import Contacts

final class ContactsService {
    private let store = CNContactStore()

    enum ContactsError: LocalizedError {
        case accessDenied
        case noResults
        case noPhoneNumber

        var errorDescription: String? {
            switch self {
            case .accessDenied:   return "Contacts access denied. Please enable in Settings."
            case .noResults:      return "No matching contacts found."
            case .noPhoneNumber:  return "Selected contact has no phone number."
            }
        }
    }

    private var isAuthorized: Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        #if os(iOS)
        if #available(iOS 18.0, *) {
            return status == .authorized || status == .limited
        } else {
            return status == .authorized
        }
        #else
        return status == .authorized
        #endif
    }

    func requestAccess() async -> Bool {
        do {
            return try await store.requestAccess(for: .contacts)
        } catch {
            return false
        }
    }

    func searchContacts(query: String) throws -> [ContactInfo] {
        guard isAuthorized else {
            throw ContactsError.accessDenied
        }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor,
        ]

        let predicate = CNContact.predicateForContacts(matchingName: trimmed)
        let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)

        return contacts.compactMap { contact -> ContactInfo? in
            guard let phone = contact.phoneNumbers.first?.value.stringValue else { return nil }
            let name = [contact.givenName, contact.familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            return ContactInfo(
                identifier: contact.identifier,
                displayName: name.isEmpty ? "Unknown" : name,
                phoneNumber: phone
            )
        }
    }

    func fetchContact(identifier: String) -> ContactInfo? {
        guard isAuthorized else { return nil }

        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor,
        ]

        guard let contact = try? store.unifiedContact(withIdentifier: identifier, keysToFetch: keysToFetch),
              let phone = contact.phoneNumbers.first?.value.stringValue else {
            return nil
        }

        let name = [contact.givenName, contact.familyName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return ContactInfo(
            identifier: contact.identifier,
            displayName: name.isEmpty ? "Unknown" : name,
            phoneNumber: phone
        )
    }
}
