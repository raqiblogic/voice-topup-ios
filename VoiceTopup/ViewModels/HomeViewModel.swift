import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
final class HomeViewModel {
    // MARK: - Dependencies
    var speechService = SpeechService()
    let contactsService = ContactsService()
    let aliasStore = AliasStore()

    // MARK: - State
    var searchQuery: String = ""
    var searchResults: [ContactInfo] = []
    var isSearching: Bool = false

    var isProcessingAI: Bool = false
    var alertMessage: String?
    var showAlert: Bool = false

    // Navigation triggers
    var pendingTopupContact: ContactInfo?
    var pendingAmount: Decimal = 100
    var pendingCurrency: String = "৳"
    var navigateToConfirm: Bool = false

    // Quick reload navigation
    var quickReloadResult: TopupResult?
    var lastTransaction: TopupTransaction?
    var navigateToQuickResult: Bool = false
    var isQuickReloading: Bool = false

    // Sheet
    var showSettings: Bool = false

    // MARK: - Init
    init() {
        loadLastTransaction()
    }

    func loadLastTransaction() {
        if let data = UserDefaults.standard.data(forKey: "voicetopup_last_transaction"),
           let tx = try? JSONDecoder().decode(TopupTransaction.self, from: data) {
            self.lastTransaction = tx
        }
    }

    func saveLastTransaction(_ tx: TopupTransaction) {
        if let data = try? JSONEncoder().encode(tx) {
            UserDefaults.standard.set(data, forKey: "voicetopup_last_transaction")
            self.lastTransaction = tx
        }
    }

    // MARK: - Contact Search
    func performSearch() {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }

        Task { @MainActor in
            let granted = await contactsService.requestAccess()
            guard granted else {
                self.showError("Contacts permission is required to search contacts. Please enable it in Settings.")
                return
            }

            do {
                self.searchResults = try self.contactsService.searchContacts(query: trimmed)
            } catch {
                self.showError(error.localizedDescription)
            }
        }
    }

    func selectContact(_ contact: ContactInfo, initialAmount: Decimal = 100) {
        self.pendingTopupContact = contact
        self.pendingAmount = initialAmount

        // Auto-detect currency from operator
        let op = MobileOperator.detect(from: contact.phoneNumber)
        self.pendingCurrency = op.suggestedCurrency

        self.navigateToConfirm = true
    }

    // MARK: - Voice Actions
    func toggleRecording() {
        if speechService.isRecording {
            speechService.stopRecording()
            processVoiceTranscript()
        } else {
            Task { @MainActor in
                let granted = await speechService.requestPermissions()
                guard granted else {
                    self.showError(speechService.errorMessage ?? "Microphone and Speech Recognition permissions are required.")
                    return
                }
                self.speechService.startRecording()
            }
        }
    }

    func processVoiceTranscript() {
        let transcript = speechService.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !transcript.isEmpty else {
            // Empty transcript, do nothing or silent ignore
            return
        }

        // 1. Try local regex parsing first
        let parseResult = TopupParser.parse(transcript)

        switch parseResult {
        case .success(let parsed):
            resolveAndProceed(parsed: parsed)

        case .ambiguous, .noResult:
            // 2. Fallback to Groq API
            fallbackToGroq(transcript: transcript)
        }
    }

    private func fallbackToGroq(transcript: String) {
        Task { @MainActor in
            self.isProcessingAI = true
            defer { self.isProcessingAI = false }

            do {
                let parsed = try await GroqService.extractTopup(from: transcript)
                self.resolveAndProceed(parsed: parsed)
            } catch {
                // If local parser had an ambiguous guess, fallback to it if Groq fails
                if case .ambiguous(let localFallback) = TopupParser.parse(transcript) {
                    self.resolveAndProceed(parsed: localFallback)
                } else {
                    self.showError("Could not extract recipient and amount: \(error.localizedDescription)")
                }
            }
        }
    }

    private func resolveAndProceed(parsed: ParsedTopup) {
        Task { @MainActor in
            let contactsGranted = await contactsService.requestAccess()
            guard contactsGranted else {
                self.showError("Contacts permission is required to find '\(parsed.name)'.")
                return
            }

            // Check if name is in AliasStore
            if let contactId = aliasStore.resolve(parsed.name),
               let contact = contactsService.fetchContact(identifier: contactId) {
                self.selectContact(contact, initialAmount: parsed.amount)
                return
            }

            // Otherwise search contacts matching name
            do {
                let matches = try contactsService.searchContacts(query: parsed.name)
                if let firstMatch = matches.first {
                    self.selectContact(firstMatch, initialAmount: parsed.amount)
                } else {
                    self.showError("Found command to send \(parsed.amount), but no contact matching '\(parsed.name)' was found.")
                }
            } catch {
                self.showError("Failed to search contacts: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Quick Reload
    func executeQuickReload() {
        guard let last = lastTransaction, !isQuickReloading else { return }
        isQuickReloading = true

        Task { @MainActor in
            let result = await DummyTopupService.executeTopup(transaction: last)
            self.isQuickReloading = false
            self.quickReloadResult = result

            if case .success = result {
                // Update timestamp
                let updated = TopupTransaction(
                    contact: last.contact,
                    amount: last.amount,
                    currency: last.currency,
                    operatorName: last.operatorName,
                    date: Date()
                )
                self.saveLastTransaction(updated)
            }

            self.navigateToQuickResult = true
        }
    }

    // MARK: - Helpers
    func showError(_ msg: String) {
        self.alertMessage = msg
        self.showAlert = true
    }
}
