import SwiftUI

struct ResultView: View {
    let transaction: TopupTransaction
    let result: TopupResult
    let onRetry: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            switch result {
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.green)

                Text("Top-up Successful!")
                    .font(.title2.bold())

                Text("Your recharge request has been completed successfully.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

            case .failure(let errorMsg):
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.red)

                Text("Top-up Failed")
                    .font(.title2.bold())

                Text(errorMsg)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Summary Card
            VStack(spacing: 12) {
                HStack {
                    Text("Recipient")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(transaction.contact.displayName)
                        .bold()
                }

                HStack {
                    Text("Phone Number")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(transaction.contact.phoneNumber)
                        .font(.system(.body, design: .monospaced))
                }

                HStack {
                    Text("Operator")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(transaction.operatorName)
                }

                Divider()

                HStack {
                    Text("Amount")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(transaction.currency) \(transaction.amount.formatted())")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)

            Spacer()

            // Actions
            VStack(spacing: 12) {
                switch result {
                case .success:
                    Button(action: onDone) {
                        Text("Done")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)

                case .failure:
                    Button(action: onRetry) {
                        Text("Retry Top-up")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: onDone) {
                        Text("Back to Home")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .navigationBarBackButtonHidden(true)
    }
}
