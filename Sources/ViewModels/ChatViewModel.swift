import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var isProcessing: Bool = false
    
    init() {
        // Welcome message
        messages.append(Message(
            content: "Welcome to Cognitive Ether. How can I assist you today?",
            role: .assistant,
            timestamp: Date()
        ))
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let userMessage = Message(
            content: inputText,
            role: .user,
            timestamp: Date()
        )
        messages.append(userMessage)
        let currentInput = inputText
        inputText = ""
        isProcessing = true
        
        callAI(prompt: currentInput)
    }
    
    private func callAI(prompt: String) {
        let config = ConfigManager.shared
        
        // Determine provider and model
        let provider: AIProvider
        let model: String
        
        if config.isOllamaEnabled {
            provider = .ollama
            // Use the first local model if available, otherwise default to llama3
            model = AIManager.shared.localModels.first?.name ?? "llama3"
        } else if !config.openAIKey.isEmpty {
            provider = .openAI
            model = "gpt-4o"
        } else if !config.deepSeekKey.isEmpty {
            provider = .deepSeek
            model = "deepseek-chat"
        } else if !config.geminiKey.isEmpty {
            provider = .gemini
            model = "gemini-1.5-flash"
        } else {
            // No provider configured
            self.messages.removeAll(where: { $0.role == .reasoning })
            let errorMsg = Message(
                content: "No AI provider configured. Please enable Ollama or add an API Key in Settings.",
                role: .assistant,
                timestamp: Date()
            )
            self.messages.append(errorMsg)
            self.isProcessing = false
            return
        }
        
        // Add a reasoning message
        var reasoningContent = "Connecting to \(provider.rawValue.capitalized)..."
        if provider == .ollama {
            reasoningContent += "\n- Using local endpoint: \(config.ollamaEndpoint)"
            reasoningContent += "\n- Target model: \(model)"
        }
        
        if config.isSemanticMemoryEnabled {
            reasoningContent += "\n- Semantic Memory: Active"
        }
        
        let reasoningMessage = Message(
            content: reasoningContent,
            role: .reasoning,
            timestamp: Date(),
            isThinking: true
        )
        messages.append(reasoningMessage)
        
        Task {
            do {
                let response = try await AIManager.shared.generateResponse(
                    prompt: prompt,
                    provider: provider,
                    model: model
                )
                
                await MainActor.run {
                    self.messages.removeAll(where: { $0.role == .reasoning })
                    let assistantMessage = Message(
                        content: response,
                        role: .assistant,
                        timestamp: Date()
                    )
                    self.messages.append(assistantMessage)
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.messages.removeAll(where: { $0.role == .reasoning })
                    let errorContent: String
                    if (error as NSError).domain == NSURLErrorDomain {
                        errorContent = "Connection Error: Could not reach \(provider.rawValue). Check your network or local server status."
                    } else {
                        errorContent = "Error: \(error.localizedDescription)"
                    }
                    let errorMessage = Message(
                        content: errorContent,
                        role: .assistant,
                        timestamp: Date()
                    )
                    self.messages.append(errorMessage)
                    self.isProcessing = false
                }
            }
        }
    }
}
