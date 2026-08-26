import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Quick Reload (if exists)
                    if let last = viewModel.lastTransaction {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("QUICK RELOAD")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(last.contact.displayName)
                                        .font(.headline)
                                    Text("\(last.operatorName) • \(last.currency) \(last.amount.formatted())")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button {
                                    viewModel.executeQuickReload()
                                } label: {
                                    if viewModel.isQuickReloading {
                                        ProgressView()
                                            .tint(.white)
                                            .padding(.horizontal, 12)
                                    } else {
                                        HStack(spacing: 4) {
                                            Image(systemName: "bolt.fill")
                                            Text("Reload")
                                        }
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(viewModel.isQuickReloading)
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }

                    // MARK: - Voice Record Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("VOICE TOP-UP")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()

                            // Speech Locale Toggle
                            Picker("Locale", selection: $viewModel.speechService.selectedLocale) {
                                Text("English (US)").tag(Locale(identifier: "en-US"))
                                Text("বাংলা (BD)").tag(Locale(identifier: "bn-BD"))
                            }
                            .pickerStyle(.menu)
                            .font(.caption)
                        }
                        .padding(.horizontal, 4)

                        VStack(spacing: 16) {
                            // Mic Button
                            Button {
                                viewModel.toggleRecording()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(viewModel.speechService.isRecording ? Color.red.opacity(0.2) : Color.blue.opacity(0.15))
                                        .frame(width: 88, height: 88)

                                    Circle()
                                        .fill(viewModel.speechService.isRecording ? Color.red : Color.blue)
                                        .frame(width: 68, height: 68)

                                    Image(systemName: viewModel.speechService.isRecording ? "stop.fill" : "mic.fill")
                                        .font(.title)
                                        .foregroundStyle(.white)
                                }
                            }
                            .buttonStyle(.plain)

                            // Status / Transcript text
                            if viewModel.speechService.isRecording {
                                VStack(spacing: 6) {
                                    Text("Listening...")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.red)

                                    Text(viewModel.speechService.transcript.isEmpty ? "Say e.g. 'Send 500 to Ammu' or 'আম্মুকে ৫০০ টাকা পাঠাও'" : viewModel.speechService.transcript)
                                        .font(.body)
                                        .foregroundStyle(viewModel.speechService.transcript.isEmpty ? .secondary : .primary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            } else if viewModel.isProcessingAI {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("Analyzing with Groq...")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                Text("Tap mic & speak (e.g. \"Send 500 to Mom\" or \"Send RM 50 to John\")")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)

                    // MARK: - Manual Contact Search
                    VStack(alignment: .leading, spacing: 10) {
                        Text("OR SELECT CONTACT MANUALLY")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Search name or phone number", text: $viewModel.searchQuery)
                                .onChange(of: viewModel.searchQuery) { _, _ in
                                    viewModel.performSearch()
                                }
                            if !viewModel.searchQuery.isEmpty {
                                Button {
                                    viewModel.searchQuery = ""
                                    viewModel.searchResults = []
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        // Search Results List
                        if !viewModel.searchResults.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(viewModel.searchResults, id: \.identifier) { contact in
                                    Button {
                                        viewModel.selectContact(contact)
                                    } label: {
                                        HStack {
                                            Image(systemName: "person.circle")
                                                .font(.title2)
                                                .foregroundStyle(.tint)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(contact.displayName)
                                                    .font(.headline)
                                                    .foregroundStyle(.primary)
                                                Text(contact.phoneNumber)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 12)
                                    }

                                    if contact.identifier != viewModel.searchResults.last?.identifier {
                                        Divider().padding(.leading, 44)
                                    }
                                }
                            }
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("VoiceTopup")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showSettings) {
                AliasSettingsView(
                    aliasStore: viewModel.aliasStore,
                    contactsService: viewModel.contactsService
                )
            }
            .navigationDestination(isPresented: $viewModel.navigateToConfirm) {
                if let contact = viewModel.pendingTopupContact {
                    ConfirmView(
                        contact: contact,
                        initialAmount: viewModel.pendingAmount,
                        initialCurrency: viewModel.pendingCurrency,
                        onComplete: { tx in
                            viewModel.saveLastTransaction(tx)
                        },
                        onDismiss: {
                            viewModel.navigateToConfirm = false
                            viewModel.pendingTopupContact = nil
                        }
                    )
                }
            }
            .navigationDestination(isPresented: $viewModel.navigateToQuickResult) {
                if let last = viewModel.lastTransaction, let res = viewModel.quickReloadResult {
                    ResultView(
                        transaction: last,
                        result: res,
                        onRetry: {
                            viewModel.executeQuickReload()
                        },
                        onDone: {
                            viewModel.navigateToQuickResult = false
                        }
                    )
                }
            }
            .alert("Notice", isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.alertMessage ?? "An error occurred.")
            }
            .onDisappear {
                // Ensure audio engine stops if view navigates or disappears
                viewModel.speechService.stopRecording()
            }
        }
    }
}
