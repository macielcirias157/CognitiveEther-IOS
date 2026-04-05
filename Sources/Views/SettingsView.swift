import SwiftUI

struct SettingsView: View {
    @State private var temperature: Double = 0.7
    @State private var topP: Double = 0.9
    @State private var contextWindow: Int = 8192
    @State private var kvCache: Bool = true
    @State private var hardwareAcceleration: Bool = true
    
    @ObservedObject var config = ConfigManager.shared
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("Settings")
                    .font(theme.appFont(size: 32, weight: .bold))
                    .foregroundColor(theme.onSurface)
                
                VStack(alignment: .leading, spacing: 24) {
                    SettingSection(title: "AI Personality") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Default System Prompt")
                                .font(theme.appFont(size: 16))
                                .foregroundColor(theme.onSurface.opacity(0.8))
                            
                            TextEditor(text: $config.defaultSystemPrompt)
                                .frame(height: 100)
                                .padding(12)
                                .background(theme.surfaceContainerLow)
                                .cornerRadius(12)
                                .foregroundColor(theme.onSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(theme.outlineVariant.opacity(0.15), lineWidth: 1)
                                )
                            
                            Text("This prompt defines how the AI behaves across all sessions.")
                                .font(theme.appFont(size: 12))
                                .foregroundColor(theme.onSurface.opacity(0.5))
                        }
                    }
                    
                    SettingSection(title: "Model Parameters") {
                        VStack(spacing: 24) {
                            SliderSetting(label: "Temperature", value: $temperature, range: 0...2, step: 0.1)
                            SliderSetting(label: "Top-P", value: $topP, range: 0...1, step: 0.05)
                        }
                    }
                    
                    SettingSection(title: "External Services") {
                        VStack(spacing: 20) {
                            SecureSetting(label: "Hugging Face Token", value: $config.huggingFaceToken)
                            SecureSetting(label: "OpenAI API Key", value: $config.openAIKey)
                            SecureSetting(label: "DeepSeek API Key", value: $config.deepSeekKey)
                            SecureSetting(label: "Gemini API Key", value: $config.geminiKey)
                            
                            HStack {
                                Text("Ollama Local Endpoint")
                                    .font(theme.appFont(size: 16))
                                    .foregroundColor(theme.onSurface.opacity(0.8))
                                Spacer()
                                TextField("http://localhost:11434", text: $config.ollamaEndpoint)
                                    .font(theme.appFont(size: 14))
                                    .foregroundColor(theme.primary)
                                    .multilineTextAlignment(.trailing)
                            }
                            
                            ToggleSetting(label: "Enable Ollama Local", isOn: $config.isOllamaEnabled)
                        }
                    }
                    
                    SettingSection(title: "System Config") {
                        VStack(spacing: 20) {
                            PickerSetting(label: "Context Window", value: $contextWindow, options: [4096, 8192, 16384, 32768])
                            ToggleSetting(label: "KV Cache", isOn: $kvCache)
                            ToggleSetting(label: "Hardware Acceleration", isOn: $hardwareAcceleration)
                        }
                    }
                }
            }
            .padding()
        }
        .background(theme.surface.ignoresSafeArea())
        .onDisappear {
            config.save()
        }
    }
}

struct SecureSetting: View {
    let label: String
    @Binding var value: String
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(theme.appFont(size: 16))
                .foregroundColor(theme.onSurface.opacity(0.8))
            
            SecureField("Enter API Key...", text: $value)
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
    @ObservedObject var theme = ThemeManager.shared
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(theme.appFont(size: 18, weight: .semibold))
                .foregroundColor(theme.onSurface)
            
            content
                .padding(24)
                .background(theme.surfaceContainer)
                .cornerRadius(32)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
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
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(label)
                    .font(theme.appFont(size: 16))
                    .foregroundColor(theme.onSurface.opacity(0.8))
                Spacer()
                Text(String(format: "%.2f", value))
                    .font(theme.appFont(size: 14, weight: .bold))
                    .foregroundColor(theme.primary)
            }
            
            Slider(value: $value, in: range, step: step)
                .accentColor(theme.primary)
        }
    }
}

struct PickerSetting: View {
    let label: String
    @Binding var value: Int
    let options: [Int]
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        HStack {
            Text(label)
                .font(theme.appFont(size: 16))
                .foregroundColor(theme.onSurface.opacity(0.8))
            Spacer()
            Picker("", selection: $value) {
                ForEach(options, id: \.self) { option in
                    Text("\(option / 1024)k").tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .accentColor(theme.primary)
        }
    }
}

struct ToggleSetting: View {
    let label: String
    @Binding var isOn: Bool
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        Toggle(label, isOn: $isOn)
            .font(theme.appFont(size: 16))
            .foregroundColor(theme.onSurface.opacity(0.8))
            .toggleStyle(SwitchToggleStyle(tint: theme.primary))
    }
}
