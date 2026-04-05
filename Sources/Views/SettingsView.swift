import SwiftUI

struct SettingsView: View {
    @ObservedObject private var config = ConfigManager.shared
    @ObservedObject private var theme = ThemeManager.shared

    @State private var isShowingClearAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                providerSection
                requestSection
                servicesSection
                behaviorSection
                privacySection
            }
            .padding()
        }
        .background(theme.surface.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
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

            Text("API keys are stored in Keychain. Non-sensitive preferences stay in local app storage.")
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

                ModelFieldRow(label: "Ollama Model", text: $config.ollamaModelName, helper: "Used when Ollama is the active provider.")
                ModelFieldRow(label: "OpenAI Model", text: $config.openAIModelName, helper: "Example: gpt-4o")
                ModelFieldRow(label: "DeepSeek Model", text: $config.deepSeekModelName, helper: "Example: deepseek-chat")
                ModelFieldRow(label: "Gemini Model", text: $config.geminiModelName, helper: "Example: gemini-1.5-flash")
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

                HStack(spacing: 12) {
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
                Text("Conversation history is persisted inside the app's local storage to support resuming chats.")
                    .font(theme.appFont(size: 14))
                    .foregroundColor(theme.onSurface.opacity(0.62))

                LuminaButton(label: "Clear Saved Conversations", action: {
                    isShowingClearAlert = true
                }, isPrimary: false)
            }
        }
    }
}

private struct ModelFieldRow: View {
    let label: String
    @Binding var text: String
    let helper: String

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(theme.appFont(size: 16))
                .foregroundColor(theme.onSurface.opacity(0.82))

            TextField(label, text: $text)
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

            Text(helper)
                .font(theme.appFont(size: 12))
                .foregroundColor(theme.onSurface.opacity(0.5))
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
