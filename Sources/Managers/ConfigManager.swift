import Foundation
import Combine

class ConfigManager: ObservableObject {
    static let shared = ConfigManager()
    
    // Ollama Config
    @Published var ollamaEndpoint: String = "http://localhost:11434"
    @Published var isOllamaEnabled: Bool = false
    
    // API Keys
    @Published var huggingFaceToken: String = ""
    @Published var openAIKey: String = ""
    @Published var deepSeekKey: String = ""
    @Published var geminiKey: String = ""
    @Published var anthropicKey: String = ""
    
    // Remote Models visibility
    @Published var showHFModels: Bool = false
    
    // AI Behavior
    @Published var defaultSystemPrompt: String = "You are Cognitive Ether, a helpful local AI assistant."
    
    // Skills State
    @Published var isSemanticMemoryEnabled: Bool = false
    @Published var isWebBrowsingEnabled: Bool = false
    
    private init() {
        // Load from UserDefaults or Keychain if needed
        self.ollamaEndpoint = UserDefaults.standard.string(forKey: "ollamaEndpoint") ?? "http://localhost:11434"
        self.isOllamaEnabled = UserDefaults.standard.bool(forKey: "isOllamaEnabled")
        self.huggingFaceToken = UserDefaults.standard.string(forKey: "huggingFaceToken") ?? ""
        self.openAIKey = UserDefaults.standard.string(forKey: "openAIKey") ?? ""
        self.deepSeekKey = UserDefaults.standard.string(forKey: "deepSeekKey") ?? ""
        self.geminiKey = UserDefaults.standard.string(forKey: "geminiKey") ?? ""
        self.anthropicKey = UserDefaults.standard.string(forKey: "anthropicKey") ?? ""
        
        self.defaultSystemPrompt = UserDefaults.standard.string(forKey: "defaultSystemPrompt") ?? "You are Cognitive Ether, a helpful local AI assistant."
        self.isSemanticMemoryEnabled = UserDefaults.standard.bool(forKey: "isSemanticMemoryEnabled")
        self.isWebBrowsingEnabled = UserDefaults.standard.bool(forKey: "isWebBrowsingEnabled")
    }
    
    func save() {
        UserDefaults.standard.set(ollamaEndpoint, forKey: "ollamaEndpoint")
        UserDefaults.standard.set(isOllamaEnabled, forKey: "isOllamaEnabled")
        UserDefaults.standard.set(huggingFaceToken, forKey: "huggingFaceToken")
        UserDefaults.standard.set(openAIKey, forKey: "openAIKey")
        UserDefaults.standard.set(deepSeekKey, forKey: "deepSeekKey")
        UserDefaults.standard.set(geminiKey, forKey: "geminiKey")
        UserDefaults.standard.set(anthropicKey, forKey: "anthropicKey")
        
        UserDefaults.standard.set(defaultSystemPrompt, forKey: "defaultSystemPrompt")
        UserDefaults.standard.set(isSemanticMemoryEnabled, forKey: "isSemanticMemoryEnabled")
        UserDefaults.standard.set(isWebBrowsingEnabled, forKey: "isWebBrowsingEnabled")
    }
}
