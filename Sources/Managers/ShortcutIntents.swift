import Foundation
import AppIntents
import SwiftUI

@available(iOS 16.0, *)
struct AskCognitiveEtherIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask Cognitive Ether"
    static var description = IntentDescription("Send a prompt to Cognitive Ether and get a response.")

    @Parameter(title: "Prompt", description: "The text to send to the AI")
    var prompt: String

    @Parameter(title: "Provider", default: .ollama)
    var provider: AIProvider

    @Parameter(title: "Model", default: "llama3")
    var model: String

    static var parameterSummary: some ParameterSummary {
        Summary("Ask Cognitive Ether \(\.$prompt) using \(\.$provider) model \(\.$model)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        do {
            let response = try await AIManager.shared.generateResponse(prompt: prompt, provider: provider, model: model)
            return .result(value: response)
        } catch {
            return .result(value: "Error: \(error.localizedDescription)")
        }
    }
}

@available(iOS 16.0, *)
struct CognitiveEtherShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskCognitiveEtherIntent(),
            phrases: [
                "Ask \(.applicationName)",
                "Query \(.applicationName)"
            ],
            shortTitle: "Ask AI",
            systemImageName: "sparkles"
        )
    }
}
