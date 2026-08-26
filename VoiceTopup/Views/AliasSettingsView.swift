import SwiftUI

struct AliasSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let aliasStore: AliasStore
    let contactsService: ContactsService

    @State private var newAliasName: String = ""
    @State private var contactSearchQuery: String = ""
    @State private var searchResults: [ContactInfo] = []
    @State private var selectedContact: ContactInfo?
    @State private var isAddingAlias: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Saved Aliases"), footer: Text("Aliases let you say 'Send 500 to Ammu' and automatically resolve to your chosen contact.")) {
                    if aliasStore.aliases.isEmpty {
                        Text("No aliases added yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(aliasStore.aliases.keys.sorted()), id: \.self) { alias in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(alias)
                                        .font(.headline)
                                    if let contactId = aliasStore.aliases[alias],
                                       let contact = contactsService.fetchContact(identifier: contactId) {
                                        Text("\(contact.displayName) • \(contact.phoneNumber)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("Contact not found in address book")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .onDelete { indexSet in
                            let keys = Array(aliasStore.aliases.keys.sorted())
                            for index in indexSet {
                                let key = keys[index]
                                aliasStore.removeAlias(key)
                            }
                        }
                    }
                }

                if isAddingAlias {
                    Section("Add New Alias") {
                        TextField("Alias Name (e.g. Ammu, Mom, Abbu)", text: $newAliasName)

                        TextField("Search Contact", text: $contactSearchQuery)
                            .onChange(of: contactSearchQuery) { _, newValue in
                                searchContacts(query: newValue)
                            }

                        if let sel = selectedContact {
                            HStack {
                                Label(sel.displayName, systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Spacer()
                                Text(sel.phoneNumber)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if !searchResults.isEmpty && selectedContact == nil {
                            ForEach(searchResults, id: \.identifier) { contact in
                                Button {
                                    selectedContact = contact
                                } label: {
                                    HStack {
                                        Text(contact.displayName)
                                        Spacer()
                                        Text(contact.phoneNumber)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }

                        HStack {
                            Button("Cancel", role: .cancel) {
                                resetAddForm()
                            }
                            Spacer()
                            Button("Save Alias") {
                                saveNewAlias()
                            }
                            .disabled(newAliasName.trimmingCharacters(in: .whitespaces).isEmpty || selectedContact == nil)
                        }
                    }
                }
            }
            .navigationTitle("Contact Aliases")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !isAddingAlias {
                        Button {
                            isAddingAlias = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
    }

    private func searchContacts(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }
        Task { @MainActor in
            _ = await contactsService.requestAccess()
            if let results = try? contactsService.searchContacts(query: trimmed) {
                self.searchResults = results
            }
        }
    }

    private func saveNewAlias() {
        let trimmed = newAliasName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let contact = selectedContact else { return }
        aliasStore.addAlias(trimmed, contactIdentifier: contact.identifier)
        resetAddForm()
    }

    private func resetAddForm() {
        newAliasName = ""
        contactSearchQuery = ""
        searchResults = []
        selectedContact = nil
        isAddingAlias = false
    }
}
