import Foundation
import Combine

enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case spanish = "es"
    case portuguese = "pt"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .portuguese: return "Português"
        }
    }
    
    var nativeName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .portuguese: return "Portuguese"
        }
    }
}

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
    
    // Web Search
    @Published var searxngEndpoint: String { didSet { saveDefaults() } }
    
    // Language
    @Published var appLanguageRawValue: String { didSet { saveDefaults() } }
    
    // Custom prompts
    @Published var customPrompts: [CustomPrompt] { didSet { saveDefaults() } }
    @Published var activeCustomPromptID: UUID? { didSet { saveDefaults() } }

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
        
        searxngEndpoint = defaults.string(forKey: Keys.searxngEndpoint) ?? ""
        
        appLanguageRawValue = defaults.string(forKey: Keys.appLanguageRawValue) ?? AppLanguage.english.rawValue
        
        if let promptsData = defaults.data(forKey: Keys.customPrompts),
           let prompts = try? JSONDecoder().decode([CustomPrompt].self, from: promptsData) {
            customPrompts = prompts
        } else {
            customPrompts = []
        }
        
        if let activeIDData = defaults.data(forKey: Keys.activeCustomPromptID),
           let activeID = try? JSONDecoder().decode(UUID?.self, from: activeIDData) {
            activeCustomPromptID = activeID
        } else {
            activeCustomPromptID = nil
        }

        huggingFaceToken = secureStorage.string(for: Keys.huggingFaceToken)
        openAIKey = secureStorage.string(for: Keys.openAIKey)
        deepSeekKey = secureStorage.string(for: Keys.deepSeekKey)
        geminiKey = secureStorage.string(for: Keys.geminiKey)
        anthropicKey = secureStorage.string(for: Keys.anthropicKey)

        normalizeProviderSelection()
    }
    
    var appLanguage: AppLanguage {
        get { AppLanguage(rawValue: appLanguageRawValue) ?? .english }
        set { appLanguageRawValue = newValue.rawValue }
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
        activeCustomPromptID = nil
    }
    
    func addCustomPrompt(title: String, content: String) {
        let prompt = CustomPrompt(title: title, content: content)
        customPrompts.append(prompt)
    }
    
    func removeCustomPrompt(id: UUID) {
        customPrompts.removeAll { $0.id == id }
        if activeCustomPromptID == id {
            activeCustomPromptID = nil
        }
    }
    
    func useCustomPrompt(id: UUID) {
        guard let prompt = customPrompts.first(where: { $0.id == id }) else { return }
        defaultSystemPrompt = prompt.content
        activeCustomPromptID = id
    }
    
    func activeCustomPrompt() -> CustomPrompt? {
        guard let id = activeCustomPromptID else { return nil }
        return customPrompts.first { $0.id == id }
    }
    
    func effectiveSystemPrompt() -> String {
        if let active = activeCustomPrompt() {
            return active.content
        }
        return defaultSystemPrompt
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
        
        defaults.set(searxngEndpoint, forKey: Keys.searxngEndpoint)
        
        defaults.set(appLanguageRawValue, forKey: Keys.appLanguageRawValue)
        
        if let promptsData = try? JSONEncoder().encode(customPrompts) {
            defaults.set(promptsData, forKey: Keys.customPrompts)
        }
        
        if let activeIDData = try? JSONEncoder().encode(activeCustomPromptID) {
            defaults.set(activeIDData, forKey: Keys.activeCustomPromptID)
        }
    }

    private func sanitizedModelName(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}

struct CustomPrompt: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var content: String
    let createdAt: Date
    
    init(id: UUID = UUID(), title: String, content: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
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
    
    static let searxngEndpoint = "searxngEndpoint"
    static let appLanguageRawValue = "appLanguageRawValue"
    static let customPrompts = "customPrompts"
    static let activeCustomPromptID = "activeCustomPromptID"
}