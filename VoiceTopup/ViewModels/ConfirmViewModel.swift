import Foundation
import Observation

@MainActor
@Observable
final class ConfirmViewModel {
    let contact: ContactInfo
    var amountText: String
    var selectedCurrency: String
    var detectedOperator: MobileOperator

    var isProcessing: Bool = false
    var transactionResult: TopupResult?
    var navigateToResult: Bool = false
    var errorMessage: String?
    var showErrorAlert: Bool = false

    var currentTransaction: TopupTransaction? {
        guard let amount = Decimal(string: amountText), amount > 0 else { return nil }
        return TopupTransaction(
            contact: contact,
            amount: amount,
            currency: selectedCurrency,
            operatorName: detectedOperator.rawValue,
            date: Date()
        )
    }

    init(contact: ContactInfo, initialAmount: Decimal, initialCurrency: String) {
        self.contact = contact
        self.amountText = "\(initialAmount)"
        self.selectedCurrency = initialCurrency
        self.detectedOperator = MobileOperator.detect(from: contact.phoneNumber)

        // If currency wasn't explicitly set, default to operator suggested currency
        if initialCurrency.isEmpty {
            self.selectedCurrency = self.detectedOperator.suggestedCurrency
        }
    }

    func confirmTopup(onSuccess: @escaping (TopupTransaction) -> Void) {
        guard let tx = currentTransaction else {
            errorMessage = "Please enter a valid amount greater than 0."
            showErrorAlert = true
            return
        }

        guard !isProcessing else { return }
        isProcessing = true

        Task { @MainActor in
            let result = await DummyTopupService.executeTopup(transaction: tx)
            self.isProcessing = false
            self.transactionResult = result

            if case .success = result {
                onSuccess(tx)
            }

            self.navigateToResult = true
        }
    }
}
