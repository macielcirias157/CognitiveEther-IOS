import Foundation
import Combine

final class ChatViewModel: ObservableObject {
    static let shared = ChatViewModel()

    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var isProcessing: Bool = false

    private let store = ConversationStore.shared
    private let config = ConfigManager.shared
    private let aiManager = AIManager.shared
    private var cancellables: Set<AnyCancellable> = []

    private init() {
        bindStore()
        refreshMessages()
    }

    var activeSession: ChatSession? {
        store.activeSession
    }

    var activeTitle: String {
        activeSession?.title ?? "Cognitive Ether"
    }

    var activeProviderLabel: String {
        guard let provider = config.preferredProvider() else {
            return "No provider configured"
        }

        let model = config.modelName(for: provider)
        return "\(provider.displayName) - \(model)"
    }

    func sendMessage() {
        let prompt = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        guard let provider = config.preferredProvider() else {
            appendSystemMessage("No AI provider configured. Add an API key or enable Ollama in Settings.")
            inputText = ""
            return
        }

        if store.activeSession == nil {
            store.createNewSession()
        }

        guard let session = store.activeSession else { return }

        let model = config.modelName(for: provider)
        inputText = ""
        isProcessing = true

        let userMessage = Message(content: prompt, role: .user)
        let reasoningMessage = Message(
            content: makeReasoningMessage(provider: provider, model: model),
            role: .reasoning,
            isThinking: true
        )

        store.updateSessionMetadata(id: session.id, provider: provider, model: model)
        store.appendMessage(userMessage, to: session.id)
        store.appendMessage(reasoningMessage, to: session.id)

        Task {
            do {
                let history = store.messages(for: session.id)
                let memoryContext = config.isSemanticMemoryEnabled
                    ? store.recentMemoryContext(excluding: session.id)
                    : nil

                let response = try await aiManager.generateResponse(
                    history: history,
                    provider: provider,
                    model: model,
                    memoryContext: memoryContext
                )

                await MainActor.run {
                    self.store.removeThinkingMessages(from: session.id)
                    self.store.appendMessage(
                        Message(content: response.text, role: .assistant),
                        to: session.id
                    )
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.store.removeThinkingMessages(from: session.id)
                    self.store.appendMessage(
                        Message(content: self.describe(error, provider: provider), role: .assistant),
                        to: session.id
                    )
                    self.isProcessing = false
                }
            }
        }
    }

    func createNewConversation() {
        store.createNewSession()
    }

    func selectConversation(id: UUID) {
        store.selectSession(id: id)
    }

    func clearHistory() {
        store.clearHistory()
    }

    private func bindStore() {
        store.$sessions
            .combineLatest(store.$activeSessionID)
            .sink { [weak self] _, _ in
                self?.refreshMessages()
            }
            .store(in: &cancellables)
    }

    private func refreshMessages() {
        messages = store.activeSession?.messages ?? []
    }

    private func appendSystemMessage(_ text: String) {
        if store.activeSession == nil {
            store.createNewSession()
        }

        guard let session = store.activeSession else { return }
        store.appendMessage(Message(content: text, role: .assistant), to: session.id)
    }

    private func makeReasoningMessage(provider: AIProvider, model: String) -> String {
        var lines = [
            "Provider: \(provider.displayName)",
            "Model: \(model)",
            "Temperature: \(String(format: "%.2f", config.temperature))",
            "Top-P: \(String(format: "%.2f", config.topP))",
            "Context Window: \(config.contextWindow)"
        ]

        if provider == .ollama {
            lines.append("Endpoint: \(config.ollamaEndpoint)")
        }

        if config.isSemanticMemoryEnabled {
            lines.append("Cross-session memory: enabled")
        }

        return lines.joined(separator: "\n")
    }

    private func describe(_ error: Error, provider: AIProvider) -> String {
        let nsError = error as NSError

        if nsError.domain == NSURLErrorDomain {
            return "Connection error while contacting \(provider.displayName). Check the endpoint, your network, or the API key."
        }

        return error.localizedDescription
    }
}
