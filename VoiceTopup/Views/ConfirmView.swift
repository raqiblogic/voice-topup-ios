import SwiftUI

struct ConfirmView: View {
    let contact: ContactInfo
    let initialAmount: Decimal
    let initialCurrency: String
    let onComplete: (TopupTransaction) -> Void
    let onDismiss: () -> Void

    @State private var viewModel: ConfirmViewModel

    init(
        contact: ContactInfo,
        initialAmount: Decimal = 100,
        initialCurrency: String = "৳",
        onComplete: @escaping (TopupTransaction) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.contact = contact
        self.initialAmount = initialAmount
        self.initialCurrency = initialCurrency
        self.onComplete = onComplete
        self.onDismiss = onDismiss
        _viewModel = State(initialValue: ConfirmViewModel(
            contact: contact,
            initialAmount: initialAmount,
            initialCurrency: initialCurrency
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    // Recipient Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("RECIPIENT")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 44, height: 44)
                                    .foregroundStyle(.tint)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(contact.displayName)
                                        .font(.headline)
                                    Text(contact.phoneNumber)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }

                            Divider()

                            HStack {
                                Label("Operator", systemImage: "antenna.radiowaves.left.and.right")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(viewModel.detectedOperator.rawValue)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(viewModel.detectedOperator == .unknown ? .orange : .primary)
                            }
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Top-up Amount Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TOP-UP AMOUNT")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        VStack(spacing: 16) {
                            // Currency Toggle
                            HStack {
                                Text("Currency")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Picker("Currency", selection: $viewModel.selectedCurrency) {
                                    Text("৳ BDT").tag("৳")
                                    Text("RM MYR").tag("RM")
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 160)
                            }

                            // Amount Input
                            HStack(alignment: .firstTextBaseline) {
                                Text(viewModel.selectedCurrency)
                                    .font(.title.bold())
                                    .foregroundStyle(.secondary)

                                TextField("Amount", text: $viewModel.amountText)
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    #if os(iOS)
                                    .keyboardType(.decimalPad)
                                    #endif
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.vertical, 8)

                            // Quick Amount Buttons
                            HStack(spacing: 8) {
                                ForEach([50, 100, 200, 500], id: \.self) { val in
                                    Button("\(val)") {
                                        viewModel.amountText = "\(val)"
                                    }
                                    .buttonStyle(.bordered)
                                    .font(.subheadline)
                                }
                            }
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }

            // Bottom Confirm Button
            VStack {
                Divider()
                Button(action: {
                    viewModel.confirmTopup(onSuccess: onComplete)
                }) {
                    HStack {
                        if viewModel.isProcessing {
                            ProgressView()
                                .padding(.trailing, 4)
                            Text("Processing...")
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                            Text("Confirm Top-up")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isProcessing)
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(Color.appBackground)
        }
        .navigationTitle("Confirm Top-up")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationDestination(isPresented: $viewModel.navigateToResult) {
            if let tx = viewModel.currentTransaction, let res = viewModel.transactionResult {
                ResultView(
                    transaction: tx,
                    result: res,
                    onRetry: {
                        viewModel.confirmTopup(onSuccess: onComplete)
                    },
                    onDone: onDismiss
                )
            }
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Invalid input.")
        }
    }
}
