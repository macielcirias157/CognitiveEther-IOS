import Foundation
import AppIntents

struct AskCognitiveEtherIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask Cognitive Ether"
    static var description = IntentDescription("Send a prompt to Cognitive Ether and get a response.")

    @Parameter(title: "Prompt", description: "The text to send to the AI")
    var prompt: String

    @Parameter(title: "Provider", default: "Ollama")
    var provider: String

    @Parameter(title: "Model", default: "llama3")
    var model: String

    static var parameterSummary: some ParameterSummary {
        Summary("Ask Cognitive Ether \(\.$prompt) using \(\.$provider) model \(\.$model)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let aiProvider: AIProvider
        switch provider.lowercased() {
        case "openai": aiProvider = .openAI
        case "deepseek": aiProvider = .deepSeek
        case "gemini": aiProvider = .gemini
        default: aiProvider = .ollama
        }
        
        do {
            let response = try await AIManager.shared.generateResponse(prompt: prompt, provider: aiProvider, model: model)
            return .result(value: response)
        } catch {
            return .result(value: "Error: \(error.localizedDescription)")
        }
    }
}

struct CognitiveEtherShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskCognitiveEtherIntent(),
            phrases: [
                "Ask \(.applicationName) to \(\.$prompt)",
                "Query \(.applicationName) with \(\.$prompt)"
            ],
            shortTitle: "Ask AI",
            systemImageName: "sparkles"
        )
    }
}
