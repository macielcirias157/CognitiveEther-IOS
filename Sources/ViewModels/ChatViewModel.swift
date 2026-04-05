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
        
        // Determine provider and model (this can be made dynamic later)
        let provider: AIProvider = config.isOllamaEnabled ? .ollama : .openAI
        let model: String = config.isOllamaEnabled ? "llama3" : "gpt-4o"
        
        // Add a reasoning message
        var reasoningContent = "Connecting to \(config.isOllamaEnabled ? "Ollama Local" : "Cloud API")..."
        
        if config.isSemanticMemoryEnabled {
            reasoningContent += "\n- Semantic Memory active: Searching for relevant context..."
        }
        
        if config.isWebBrowsingEnabled && prompt.lowercased().contains("http") {
            reasoningContent += "\n- Web Browser active: Extracting content from link..."
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
                    let errorMessage = Message(
                        content: "Error: \(error.localizedDescription)",
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
