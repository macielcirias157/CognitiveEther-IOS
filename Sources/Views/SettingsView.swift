import SwiftUI

struct SettingsView: View {
    @ObservedObject private var config = ConfigManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var aiManager = AIManager.shared

    @State private var isShowingClearAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                providerSection
                requestSection
                servicesSection
                diagnosticsSection
                behaviorSection
                privacySection
            }
            .padding()
        }
        .background(theme.surface.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await aiManager.refreshAllCatalogs()
        }
        .alert("Clear chat history?", isPresented: $isShowingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                ConversationStore.shared.clearHistory()
            }
        } message: {
            Text("This removes all locally persisted conversations.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Runtime Configuration")
                .font(theme.appFont(size: 30, weight: .bold))
                .foregroundColor(theme.onSurface)

            Text("API keys are stored in Keychain. Provider diagnostics and model catalogs refresh against the real services.")
                .font(theme.appFont(size: 14))
                .foregroundColor(theme.onSurface.opacity(0.6))
        }
    }

    private var providerSection: some View {
        SettingSection(title: "Provider Routing") {
            VStack(spacing: 18) {
                PickerRow(
                    label: "Preferred Provider",
                    selection: Binding(
                        get: { config.selectedProvider },
                        set: { config.selectedProvider = $0 }
                    ),
                    options: AIProvider.allCases
                )

                ForEach(AIProvider.allCases, id: \.self) { provider in
                    ProviderModelSelector(provider: provider)
                }
            }
        }
    }

    private var requestSection: some View {
        SettingSection(title: "Request Tuning") {
            VStack(spacing: 24) {
                SliderSetting(label: "Temperature", value: $config.temperature, range: 0...2, step: 0.1)
                SliderSetting(label: "Top-P", value: $config.topP, range: 0...1, step: 0.05)
                PickerSetting(label: "Context Window", value: $config.contextWindow, options: [4096, 8192, 16384, 32768])
            }
        }
    }

    private var servicesSection: some View {
        SettingSection(title: "Services & Credentials") {
            VStack(spacing: 18) {
                SecureSetting(label: "OpenAI API Key", value: $config.openAIKey)
                SecureSetting(label: "DeepSeek API Key", value: $config.deepSeekKey)
                SecureSetting(label: "Gemini API Key", value: $config.geminiKey)
                SecureSetting(label: "Hugging Face Token", value: $config.huggingFaceToken)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Ollama Endpoint")
                        .font(theme.appFont(size: 16))
                        .foregroundColor(theme.onSurface.opacity(0.85))

                    TextField("http://192.168.1.x:11434", text: $config.ollamaEndpoint)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(theme.surfaceContainerLow)
                        .cornerRadius(12)
                        .foregroundColor(theme.onSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.outlineVariant.opacity(0.15), lineWidth: 1)
                        )

                    Text("For a physical iPhone, use your computer's LAN IP instead of localhost.")
                        .font(theme.appFont(size: 12))
                        .foregroundColor(theme.onSurface.opacity(0.5))
                }

                ToggleSetting(label: "Enable Ollama", isOn: $config.isOllamaEnabled)
            }
        }
    }

    private var diagnosticsSection: some View {
        SettingSection(title: "Provider Diagnostics") {
            VStack(spacing: 16) {
                LuminaButton(
                    label: aiManager.isRefreshingCatalogs ? "Refreshing..." : "Refresh Provider Diagnostics",
                    action: {
                        Task {
                            await aiManager.refreshAllCatalogs()
                        }
                    },
                    isPrimary: true
                )

                ForEach(AIProvider.allCases, id: \.self) { provider in
                    ProviderDiagnosticRow(provider: provider)
                }
            }
        }
    }

    private var behaviorSection: some View {
        SettingSection(title: "Behavior") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Default System Prompt")
                    .font(theme.appFont(size: 16))
                    .foregroundColor(theme.onSurface.opacity(0.82))

                TextEditor(text: $config.defaultSystemPrompt)
                    .frame(minHeight: 140)
                    .padding(12)
                    .background(theme.surfaceContainerLow)
                    .cornerRadius(14)
                    .foregroundColor(theme.onSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(theme.outlineVariant.opacity(0.15), lineWidth: 1)
                    )

                VStack(spacing: 12) {
                    ToggleSetting(label: "Cross-session Memory", isOn: $config.isSemanticMemoryEnabled)
                    ToggleSetting(label: "Web Browsing", isOn: $config.isWebBrowsingEnabled)
                }

                LuminaButton(label: "Reset Prompt", action: config.resetPromptToDefault, isPrimary: false)
            }
        }
    }

    private var privacySection: some View {
        SettingSection(title: "Local Data") {
            VStack(alignment: .leading, spacing: 14) {
                Text("Conversation history is persisted inside the app's local storage to support resuming chats and export.")
                    .font(theme.appFont(size: 14))
                    .foregroundColor(theme.onSurface.opacity(0.62))

                LuminaButton(label: "Clear Saved Conversations", action: {
                    isShowingClearAlert = true
                }, isPrimary: false)
            }
        }
    }
}

private struct ProviderModelSelector: View {
    let provider: AIProvider

    @ObservedObject private var config = ConfigManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var aiManager = AIManager.shared

    private var models: [String] {
        aiManager.providerCatalogs[provider] ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(provider.displayName) Model")
                    .font(theme.appFont(size: 16))
                    .foregroundColor(theme.onSurface.opacity(0.82))

                Spacer()

                if config.selectedProvider == provider {
                    Text("Preferred")
                        .font(theme.appFont(size: 12, weight: .semibold))
                        .foregroundColor(theme.primary)
                }
            }

            if !models.isEmpty {
                Picker(provider.displayName, selection: Binding(
                    get: { config.modelName(for: provider) },
                    set: { config.setModelName($0, for: provider) }
                )) {
                    ForEach(models, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)
                .tint(theme.primary)
            } else {
                TextField("\(provider.displayName) model", text: Binding(
                    get: { config.modelName(for: provider) },
                    set: { config.setModelName($0, for: provider) }
                ))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(theme.surfaceContainerLow)
                .cornerRadius(12)
                .foregroundColor(theme.onSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.outlineVariant.opacity(0.15), lineWidth: 1)
                )
            }

            Text(models.isEmpty ? "Type a model manually or refresh diagnostics to load a catalog." : "\(models.count) models detected.")
                .font(theme.appFont(size: 12))
                .foregroundColor(theme.onSurface.opacity(0.5))
        }
    }
}

private struct ProviderDiagnosticRow: View {
    let provider: AIProvider

    @ObservedObject private var aiManager = AIManager.shared
    @ObservedObject private var config = ConfigManager.shared
    @ObservedObject private var theme = ThemeManager.shared

    private var status: ProviderConnectionStatus {
        aiManager.status(for: provider)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(provider.displayName)
                    .font(theme.appFont(size: 16, weight: .semibold))
                    .foregroundColor(theme.onSurface)

                Spacer()

                Button(action: refresh) {
                    Text("Test")
                        .font(theme.appFont(size: 13, weight: .semibold))
                        .foregroundColor(theme.primary)
                }
                .buttonStyle(.plain)
                .disabled(!config.isConfigured(for: provider))
                .opacity(config.isConfigured(for: provider) ? 1 : 0.45)
            }

            Text(status.message)
                .font(theme.appFont(size: 13))
                .foregroundColor(theme.onSurface.opacity(0.62))

            HStack {
                Text(statusLabel)
                    .font(theme.appFont(size: 12, weight: .semibold))
                    .foregroundColor(statusColor)

                Spacer()

                if let checkedAt = status.checkedAt {
                    Text(checkedAt.formatted(date: .omitted, time: .shortened))
                        .font(theme.appFont(size: 12))
                        .foregroundColor(theme.onSurface.opacity(0.45))
                }
            }
        }
        .padding(16)
        .background(theme.surfaceContainerLow)
        .cornerRadius(18)
    }

    private var statusLabel: String {
        switch status.phase {
        case .idle:
            return "Idle"
        case .checking:
            return "Checking"
        case .connected:
            return "Connected"
        case .failed:
            return "Failed"
        case .notConfigured:
            return "Not configured"
        }
    }

    private var statusColor: Color {
        switch status.phase {
        case .connected:
            return .green
        case .checking:
            return theme.primary
        case .failed:
            return .red
        case .notConfigured:
            return .orange
        case .idle:
            return theme.onSurface.opacity(0.55)
        }
    }

    private func refresh() {
        Task {
            await aiManager.refreshCatalog(for: provider)
        }
    }
}

private struct PickerRow<Option: Hashable & CustomStringConvertible>: View {
    let label: String
    @Binding var selection: Option
    let options: [Option]

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        HStack {
            Text(label)
                .font(theme.appFont(size: 16))
                .foregroundColor(theme.onSurface.opacity(0.82))

            Spacer()

            Picker(label, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option.description).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(theme.primary)
        }
    }
}

struct SecureSetting: View {
    let label: String
    @Binding var value: String

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(theme.appFont(size: 16))
                .foregroundColor(theme.onSurface.opacity(0.82))

            SecureField("Enter value...", text: $value)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(theme.surfaceContainerLow)
                .cornerRadius(12)
                .foregroundColor(theme.onSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.outlineVariant.opacity(0.15), lineWidth: 1)
                )
        }
    }
}

struct SettingSection<Content: View>: View {
    let title: String
    let content: Content

    @ObservedObject private var theme = ThemeManager.shared

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title)
                .font(theme.appFont(size: 18, weight: .semibold))
                .foregroundColor(theme.onSurface)

            content
                .padding(22)
                .background(theme.surfaceContainer)
                .cornerRadius(28)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(theme.outlineVariant.opacity(0.15), lineWidth: 1)
                )
        }
    }
}

struct SliderSetting: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(label)
                    .font(theme.appFont(size: 16))
                    .foregroundColor(theme.onSurface.opacity(0.82))

                Spacer()

                Text(String(format: "%.2f", value))
                    .font(theme.appFont(size: 14, weight: .bold))
                    .foregroundColor(theme.primary)
            }

            Slider(value: $value, in: range, step: step)
                .tint(theme.primary)
        }
    }
}

struct PickerSetting: View {
    let label: String
    @Binding var value: Int
    let options: [Int]

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        HStack {
            Text(label)
                .font(theme.appFont(size: 16))
                .foregroundColor(theme.onSurface.opacity(0.82))

            Spacer()

            Picker(label, selection: $value) {
                ForEach(options, id: \.self) { option in
                    Text("\(option / 1024)k").tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(theme.primary)
        }
    }
}

struct ToggleSetting: View {
    let label: String
    @Binding var isOn: Bool

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        Toggle(label, isOn: $isOn)
            .font(theme.appFont(size: 15))
            .foregroundColor(theme.onSurface.opacity(0.82))
            .toggleStyle(SwitchToggleStyle(tint: theme.primary))
    }
}

extension AIProvider: CustomStringConvertible {
    var description: String {
        displayName
    }
}
