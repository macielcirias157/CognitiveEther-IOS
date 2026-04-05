import Foundation
import Combine

final class ConfigManager: ObservableObject {
    static let shared = ConfigManager()

    // Local runtime
    @Published var ollamaEndpoint: String { didSet { saveDefaults() } }
    @Published var isOllamaEnabled: Bool { didSet { saveDefaults() } }
    @Published var selectedProviderRawValue: String { didSet { saveDefaults() } }

    // Model routing
    @Published var ollamaModelName: String { didSet { saveDefaults() } }
    @Published var openAIModelName: String { didSet { saveDefaults() } }
    @Published var deepSeekModelName: String { didSet { saveDefaults() } }
    @Published var geminiModelName: String { didSet { saveDefaults() } }

    // API Keys
    @Published var huggingFaceToken: String { didSet { secureStorage.setString(huggingFaceToken, for: Keys.huggingFaceToken) } }
    @Published var openAIKey: String { didSet { secureStorage.setString(openAIKey, for: Keys.openAIKey) } }
    @Published var deepSeekKey: String { didSet { secureStorage.setString(deepSeekKey, for: Keys.deepSeekKey) } }
    @Published var geminiKey: String { didSet { secureStorage.setString(geminiKey, for: Keys.geminiKey) } }
    @Published var anthropicKey: String { didSet { secureStorage.setString(anthropicKey, for: Keys.anthropicKey) } }

    // Request tuning
    @Published var temperature: Double { didSet { saveDefaults() } }
    @Published var topP: Double { didSet { saveDefaults() } }
    @Published var contextWindow: Int { didSet { saveDefaults() } }

    // Behavior
    @Published var defaultSystemPrompt: String { didSet { saveDefaults() } }
    @Published var isSemanticMemoryEnabled: Bool { didSet { saveDefaults() } }
    @Published var isWebBrowsingEnabled: Bool { didSet { saveDefaults() } }

    private let defaults: UserDefaults
    private let secureStorage: SecureStorage

    private init(
        defaults: UserDefaults = .standard,
        secureStorage: SecureStorage = .shared
    ) {
        self.defaults = defaults
        self.secureStorage = secureStorage

        ollamaEndpoint = defaults.string(forKey: Keys.ollamaEndpoint) ?? "http://localhost:11434"
        isOllamaEnabled = defaults.object(forKey: Keys.isOllamaEnabled) as? Bool ?? false
        selectedProviderRawValue = defaults.string(forKey: Keys.selectedProviderRawValue) ?? AIProvider.ollama.rawValue

        ollamaModelName = defaults.string(forKey: Keys.ollamaModelName) ?? "llama3"
        openAIModelName = defaults.string(forKey: Keys.openAIModelName) ?? "gpt-4o"
        deepSeekModelName = defaults.string(forKey: Keys.deepSeekModelName) ?? "deepseek-chat"
        geminiModelName = defaults.string(forKey: Keys.geminiModelName) ?? "gemini-2.5-flash"

        temperature = defaults.object(forKey: Keys.temperature) as? Double ?? 0.7
        topP = defaults.object(forKey: Keys.topP) as? Double ?? 0.9
        contextWindow = defaults.object(forKey: Keys.contextWindow) as? Int ?? 8192

        defaultSystemPrompt = defaults.string(forKey: Keys.defaultSystemPrompt)
            ?? "You are Cognitive Ether, a pragmatic AI assistant. Give useful, direct answers and preserve context across the conversation."
        isSemanticMemoryEnabled = defaults.object(forKey: Keys.isSemanticMemoryEnabled) as? Bool ?? true
        isWebBrowsingEnabled = defaults.object(forKey: Keys.isWebBrowsingEnabled) as? Bool ?? false

        huggingFaceToken = secureStorage.string(for: Keys.huggingFaceToken)
        openAIKey = secureStorage.string(for: Keys.openAIKey)
        deepSeekKey = secureStorage.string(for: Keys.deepSeekKey)
        geminiKey = secureStorage.string(for: Keys.geminiKey)
        anthropicKey = secureStorage.string(for: Keys.anthropicKey)

        normalizeProviderSelection()
    }

    var selectedProvider: AIProvider {
        get { AIProvider(rawValue: selectedProviderRawValue) ?? .ollama }
        set { selectedProviderRawValue = newValue.rawValue }
    }

    func preferredProvider() -> AIProvider? {
        let selected = selectedProvider
        if isConfigured(for: selected) {
            return selected
        }

        return availableProviders().first
    }

    func availableProviders() -> [AIProvider] {
        AIProvider.allCases.filter { isConfigured(for: $0) }
    }

    func isConfigured(for provider: AIProvider) -> Bool {
        switch provider {
        case .ollama:
            return isOllamaEnabled
        case .openAI:
            return !openAIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .deepSeek:
            return !deepSeekKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .gemini:
            return !geminiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    func modelName(for provider: AIProvider) -> String {
        switch provider {
        case .ollama:
            return sanitizedModelName(ollamaModelName, fallback: "llama3")
        case .openAI:
            return sanitizedModelName(openAIModelName, fallback: "gpt-4o")
        case .deepSeek:
            return sanitizedModelName(deepSeekModelName, fallback: "deepseek-chat")
        case .gemini:
            return sanitizedModelName(geminiModelName, fallback: "gemini-2.5-flash")
        }
    }

    func setModelName(_ model: String, for provider: AIProvider) {
        switch provider {
        case .ollama:
            ollamaModelName = model
        case .openAI:
            openAIModelName = model
        case .deepSeek:
            deepSeekModelName = model
        case .gemini:
            geminiModelName = model
        }
    }

    func updatePreferredOllamaModel(from availableModels: [OllamaModel]) {
        guard !availableModels.isEmpty else { return }

        if !availableModels.contains(where: { $0.name == ollamaModelName }) {
            ollamaModelName = availableModels[0].name
        }
    }

    func resetPromptToDefault() {
        defaultSystemPrompt = "You are Cognitive Ether, a pragmatic AI assistant. Give useful, direct answers and preserve context across the conversation."
    }

    private func normalizeProviderSelection() {
        guard let resolved = preferredProvider() else { return }
        if resolved.rawValue != selectedProviderRawValue {
            selectedProviderRawValue = resolved.rawValue
        }
    }

    private func saveDefaults() {
        defaults.set(ollamaEndpoint, forKey: Keys.ollamaEndpoint)
        defaults.set(isOllamaEnabled, forKey: Keys.isOllamaEnabled)
        defaults.set(selectedProviderRawValue, forKey: Keys.selectedProviderRawValue)

        defaults.set(ollamaModelName, forKey: Keys.ollamaModelName)
        defaults.set(openAIModelName, forKey: Keys.openAIModelName)
        defaults.set(deepSeekModelName, forKey: Keys.deepSeekModelName)
        defaults.set(geminiModelName, forKey: Keys.geminiModelName)

        defaults.set(temperature, forKey: Keys.temperature)
        defaults.set(topP, forKey: Keys.topP)
        defaults.set(contextWindow, forKey: Keys.contextWindow)

        defaults.set(defaultSystemPrompt, forKey: Keys.defaultSystemPrompt)
        defaults.set(isSemanticMemoryEnabled, forKey: Keys.isSemanticMemoryEnabled)
        defaults.set(isWebBrowsingEnabled, forKey: Keys.isWebBrowsingEnabled)
    }

    private func sanitizedModelName(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}

private enum Keys {
    static let ollamaEndpoint = "ollamaEndpoint"
    static let isOllamaEnabled = "isOllamaEnabled"
    static let selectedProviderRawValue = "selectedProviderRawValue"

    static let ollamaModelName = "ollamaModelName"
    static let openAIModelName = "openAIModelName"
    static let deepSeekModelName = "deepSeekModelName"
    static let geminiModelName = "geminiModelName"

    static let huggingFaceToken = "huggingFaceToken"
    static let openAIKey = "openAIKey"
    static let deepSeekKey = "deepSeekKey"
    static let geminiKey = "geminiKey"
    static let anthropicKey = "anthropicKey"

    static let temperature = "temperature"
    static let topP = "topP"
    static let contextWindow = "contextWindow"

    static let defaultSystemPrompt = "defaultSystemPrompt"
    static let isSemanticMemoryEnabled = "isSemanticMemoryEnabled"
    static let isWebBrowsingEnabled = "isWebBrowsingEnabled"
}
