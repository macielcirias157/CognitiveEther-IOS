import Foundation
import Combine
import AppIntents
import SwiftUI

enum AIProvider: String, AppEnum, CaseIterable, Codable {
    case ollama
    case openAI
    case deepSeek
    case gemini

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "AI Provider"
    static var caseDisplayRepresentations: [AIProvider: DisplayRepresentation] = [
        .ollama: "Ollama",
        .openAI: "OpenAI",
        .deepSeek: "DeepSeek",
        .gemini: "Gemini"
    ]

    var displayName: String {
        switch self {
        case .ollama:
            return "Ollama"
        case .openAI:
            return "OpenAI"
        case .deepSeek:
            return "DeepSeek"
        case .gemini:
            return "Gemini"
        }
    }
}

enum ProviderConnectionPhase {
    case idle
    case checking
    case connected
    case failed
    case notConfigured
}

struct ProviderConnectionStatus {
    let phase: ProviderConnectionPhase
    let message: String
    let checkedAt: Date?

    static func idle(for provider: AIProvider) -> ProviderConnectionStatus {
        ProviderConnectionStatus(
            phase: .idle,
            message: "No checks run yet for \(provider.displayName).",
            checkedAt: nil
        )
    }

    static func notConfigured(for provider: AIProvider) -> ProviderConnectionStatus {
        ProviderConnectionStatus(
            phase: .notConfigured,
            message: "\(provider.displayName) is not configured.",
            checkedAt: nil
        )
    }
}

struct AIResponsePayload {
    let text: String
    let metrics: AIResponseMetrics
}

struct AIResponseMetrics {
    let provider: AIProvider
    let model: String
    let latency: TimeInterval
    let estimatedTokensPerSecond: Double
    let estimatedOutputTokens: Int

    static let empty = AIResponseMetrics(
        provider: .ollama,
        model: "",
        latency: 0,
        estimatedTokensPerSecond: 0,
        estimatedOutputTokens: 0
    )
}

enum AIServiceError: LocalizedError {
    case providerNotConfigured(AIProvider)
    case invalidEndpoint
    case invalidResponse
    case upstream(message: String)

    var errorDescription: String? {
        switch self {
        case .providerNotConfigured(let provider):
            return "\(provider.displayName) is not configured yet."
        case .invalidEndpoint:
            return "The configured endpoint is invalid."
        case .invalidResponse:
            return "The AI service returned an invalid response."
        case .upstream(let message):
            return message
        }
    }
}

final class AIManager: ObservableObject {
    static let shared = AIManager()

    @Published var lastResponse: String = ""
    @Published var isRequesting: Bool = false
    @Published var localModels: [OllamaModel] = []
    @Published var lastMetrics: AIResponseMetrics = .empty
    @Published var providerCatalogs: [AIProvider: [String]] = [:]
    @Published var providerStatuses: [AIProvider: ProviderConnectionStatus] = [:]
    @Published var isRefreshingCatalogs: Bool = false

    private let config = ConfigManager.shared
    private let resourceManager = ResourceManager.shared

    private init() {
        AIProvider.allCases.forEach { providerStatuses[$0] = ProviderConnectionStatus.idle(for: $0) }
    }

    func status(for provider: AIProvider) -> ProviderConnectionStatus {
        providerStatuses[provider] ?? ProviderConnectionStatus.idle(for: provider)
    }

    func refreshAllCatalogs() async {
        await MainActor.run {
            self.isRefreshingCatalogs = true
        }

        defer {
            Task { @MainActor in
                self.isRefreshingCatalogs = false
            }
        }

        for provider in AIProvider.allCases {
            await refreshCatalog(for: provider)
        }
    }

    func refreshCatalog(for provider: AIProvider) async {
        guard config.isConfigured(for: provider) else {
            await MainActor.run {
                self.providerCatalogs[provider] = []
                self.providerStatuses[provider] = ProviderConnectionStatus.notConfigured(for: provider)
            }
            return
        }

        await MainActor.run {
            self.providerStatuses[provider] = ProviderConnectionStatus(
                phase: .checking,
                message: "Checking \(provider.displayName)...",
                checkedAt: Date()
            )
        }

        do {
            let models = try await fetchCatalog(for: provider)
            await MainActor.run {
                self.providerCatalogs[provider] = models
                self.providerStatuses[provider] = ProviderConnectionStatus(
                    phase: .connected,
                    message: models.isEmpty
                        ? "\(provider.displayName) responded, but no chat models were returned."
                        : "\(models.count) models available from \(provider.displayName).",
                    checkedAt: Date()
                )
            }
        } catch {
            await MainActor.run {
                self.providerCatalogs[provider] = []
                self.providerStatuses[provider] = ProviderConnectionStatus(
                    phase: .failed,
                    message: error.localizedDescription,
                    checkedAt: Date()
                )
            }
        }
    }

    func listLocalModels() async {
        do {
            let models = try await fetchOllamaModels()
            await MainActor.run {
                self.localModels = models
                self.providerCatalogs[.ollama] = models.map(\.name)
                self.providerStatuses[.ollama] = ProviderConnectionStatus(
                    phase: .connected,
                    message: models.isEmpty
                        ? "Ollama responded, but no local models were found."
                        : "\(models.count) local models available.",
                    checkedAt: Date()
                )
            }
            config.updatePreferredOllamaModel(from: models)
        } catch {
            await MainActor.run {
                self.localModels = []
                self.providerCatalogs[.ollama] = []
                self.providerStatuses[.ollama] = config.isConfigured(for: .ollama)
                    ? ProviderConnectionStatus(
                        phase: .failed,
                        message: error.localizedDescription,
                        checkedAt: Date()
                    )
                    : ProviderConnectionStatus.notConfigured(for: .ollama)
            }
        }
    }

    func pullModel(name: String) async throws {
        guard let url = URL(string: "\(config.ollamaEndpoint)/api/pull") else {
            throw AIServiceError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(
            withJSONObject: [
                "name": name,
                "stream": false
            ]
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        await listLocalModels()
    }

    func deleteModel(name: String) async throws {
        guard let url = URL(string: "\(config.ollamaEndpoint)/api/delete") else {
            throw AIServiceError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["name": name])

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        await listLocalModels()
    }

    func generateResponse(
        history: [Message],
        provider: AIProvider,
        model: String,
        memoryContext: String? = nil
    ) async throws -> AIResponsePayload {
        guard config.isConfigured(for: provider) else {
            throw AIServiceError.providerNotConfigured(provider)
        }

        let conversationMessages = buildConversationMessages(from: history)
        let systemPrompt = buildSystemPrompt(memoryContext: memoryContext)
        let startDate = Date()

        await MainActor.run {
            self.isRequesting = true
        }

        defer {
            Task { @MainActor in
                self.isRequesting = false
            }
        }

        let text: String
        switch provider {
        case .ollama:
            text = try await callOllama(messages: conversationMessages, systemPrompt: systemPrompt, model: model)
        case .openAI:
            text = try await callOpenAI(messages: conversationMessages, systemPrompt: systemPrompt, model: model)
        case .deepSeek:
            text = try await callDeepSeek(messages: conversationMessages, systemPrompt: systemPrompt, model: model)
        case .gemini:
            text = try await callGemini(messages: conversationMessages, systemPrompt: systemPrompt, model: model)
        }

        let metrics = makeMetrics(
            text: text,
            provider: provider,
            model: model,
            startedAt: startDate
        )

        await MainActor.run {
            self.lastResponse = text
            self.lastMetrics = metrics
            self.resourceManager.recordInference(metrics)
        }

        return AIResponsePayload(text: text, metrics: metrics)
    }

    private func fetchCatalog(for provider: AIProvider) async throws -> [String] {
        switch provider {
        case .ollama:
            let models = try await fetchOllamaModels()
            await MainActor.run {
                self.localModels = models
            }
            config.updatePreferredOllamaModel(from: models)
            return models.map(\.name)

        case .openAI:
            let request = try makeAuthorizedRequest(
                urlString: "https://api.openai.com/v1/models",
                bearerToken: config.openAIKey
            )
            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response: response, data: data)
            let modelResponse = try JSONDecoder().decode(OpenAIModelListResponse.self, from: data)
            return sanitizeModelIDs(modelResponse.data.map(\.id))

        case .deepSeek:
            let request = try makeAuthorizedRequest(
                urlString: "https://api.deepseek.com/models",
                bearerToken: config.deepSeekKey
            )
            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response: response, data: data)
            let modelResponse = try JSONDecoder().decode(OpenAIModelListResponse.self, from: data)
            return sanitizeModelIDs(modelResponse.data.map(\.id))

        case .gemini:
            guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(config.geminiKey)") else {
                throw AIServiceError.invalidEndpoint
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response: response, data: data)
            let modelResponse = try JSONDecoder().decode(GeminiModelListResponse.self, from: data)

            let models = modelResponse.models
                .filter { $0.supportedGenerationMethods.contains("generateContent") }
                .compactMap { model -> String? in
                    if let baseModelID = model.baseModelID, !baseModelID.isEmpty {
                        return baseModelID
                    }
                    return model.name.split(separator: "/").last.map(String.init)
                }

            return sanitizeModelIDs(models)
        }
    }

    private func fetchOllamaModels() async throws -> [OllamaModel] {
        guard config.isConfigured(for: .ollama) else {
            return []
        }

        guard let url = URL(string: "\(config.ollamaEndpoint)/api/tags") else {
            throw AIServiceError.invalidEndpoint
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        try validate(response: response, data: data)
        let tagsResponse = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
        return tagsResponse.models.sorted(by: { $0.name < $1.name })
    }

    private func makeAuthorizedRequest(urlString: String, bearerToken: String) throws -> URLRequest {
        guard let url = URL(string: urlString) else {
            throw AIServiceError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func sanitizeModelIDs(_ models: [String]) -> [String] {
        Array(
            Set(
                models.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        )
        .sorted()
    }

    private func buildConversationMessages(from history: [Message]) -> [ProviderMessage] {
        let meaningfulMessages = history
            .filter { $0.role == .user || $0.role == .assistant }

        let limitedMessages = trimConversation(meaningfulMessages)
        return limitedMessages.map {
            ProviderMessage(
                role: $0.role == .assistant ? "assistant" : "user",
                content: $0.content
            )
        }
    }

    private func trimConversation(_ messages: [Message]) -> [Message] {
        let budget = max(config.contextWindow / 4, 2048)
        var runningTotal = 0
        var selected: [Message] = []

        for message in messages.reversed() {
            let estimatedCost = message.content.count + 24
            if runningTotal + estimatedCost > budget, !selected.isEmpty {
                break
            }

            selected.append(message)
            runningTotal += estimatedCost
        }

        return selected.reversed()
    }

    private func buildSystemPrompt(memoryContext: String?) -> String {
        guard let memoryContext,
              config.isSemanticMemoryEnabled,
              !memoryContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return config.defaultSystemPrompt
        }

        return """
        \(config.defaultSystemPrompt)

        \(memoryContext)
        """
    }

    private func callOllama(messages: [ProviderMessage], systemPrompt: String, model: String) async throws -> String {
        guard let url = URL(string: "\(config.ollamaEndpoint)/api/chat") else {
            throw AIServiceError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = OllamaChatRequest(
            model: model,
            messages: [ProviderMessage(role: "system", content: systemPrompt)] + messages,
            stream: false,
            options: OllamaOptions(
                temperature: config.temperature,
                topP: config.topP,
                numCtx: config.contextWindow
            )
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        let chatResponse = try JSONDecoder().decode(OllamaChatResponse.self, from: data)
        return chatResponse.message.content
    }

    private func callOpenAI(messages: [ProviderMessage], systemPrompt: String, model: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = OpenAIChatRequest(
            model: model,
            messages: [ProviderMessage(role: "system", content: systemPrompt)] + messages,
            temperature: config.temperature,
            topP: config.topP
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        let chatResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content else {
            throw AIServiceError.invalidResponse
        }

        return content
    }

    private func callDeepSeek(messages: [ProviderMessage], systemPrompt: String, model: String) async throws -> String {
        let url = URL(string: "https://api.deepseek.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.deepSeekKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = OpenAIChatRequest(
            model: model,
            messages: [ProviderMessage(role: "system", content: systemPrompt)] + messages,
            temperature: config.temperature,
            topP: config.topP
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        let chatResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content else {
            throw AIServiceError.invalidResponse
        }

        return content
    }

    private func callGemini(messages: [ProviderMessage], systemPrompt: String, model: String) async throws -> String {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(config.geminiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = GeminiRequest(
            systemInstruction: GeminiInstruction(parts: [GeminiPart(text: systemPrompt)]),
            contents: messages.map { message in
                GeminiContent(
                    role: message.role == "assistant" ? "model" : "user",
                    parts: [GeminiPart(text: message.content)]
                )
            },
            generationConfig: GeminiGenerationConfig(
                temperature: config.temperature,
                topP: config.topP
            )
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let content = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw AIServiceError.invalidResponse
        }

        return content
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let apiError = try? JSONDecoder().decode(GenericAPIErrorResponse.self, from: data) {
                throw AIServiceError.upstream(message: apiError.readableMessage)
            }

            if let plainText = String(data: data, encoding: .utf8), !plainText.isEmpty {
                throw AIServiceError.upstream(message: plainText)
            }

            throw AIServiceError.upstream(message: "Upstream request failed with status \(httpResponse.statusCode).")
        }
    }

    private func makeMetrics(
        text: String,
        provider: AIProvider,
        model: String,
        startedAt: Date
    ) -> AIResponseMetrics {
        let latency = max(Date().timeIntervalSince(startedAt), 0.01)
        let estimatedTokens = max(text.count / 4, 1)
        let estimatedTokensPerSecond = Double(estimatedTokens) / latency

        return AIResponseMetrics(
            provider: provider,
            model: model,
            latency: latency,
            estimatedTokensPerSecond: estimatedTokensPerSecond,
            estimatedOutputTokens: estimatedTokens
        )
    }
}

struct ProviderMessage: Codable {
    let role: String
    let content: String
}

private struct OllamaChatRequest: Codable {
    let model: String
    let messages: [ProviderMessage]
    let stream: Bool
    let options: OllamaOptions
}

private struct OllamaOptions: Codable {
    let temperature: Double
    let topP: Double
    let numCtx: Int

    enum CodingKeys: String, CodingKey {
        case temperature
        case topP = "top_p"
        case numCtx = "num_ctx"
    }
}

private struct OllamaChatResponse: Codable {
    struct OllamaChatMessage: Codable {
        let content: String
    }

    let message: OllamaChatMessage
}

private struct OpenAIChatRequest: Codable {
    let model: String
    let messages: [ProviderMessage]
    let temperature: Double
    let topP: Double

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case topP = "top_p"
    }
}

struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }

        let message: Message
    }

    let choices: [Choice]
}

private struct OpenAIModelListResponse: Codable {
    let data: [OpenAIModelDescriptor]
}

private struct OpenAIModelDescriptor: Codable {
    let id: String
}

private struct GeminiRequest: Codable {
    let systemInstruction: GeminiInstruction
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

private struct GeminiInstruction: Codable {
    let parts: [GeminiPart]
}

private struct GeminiContent: Codable {
    let role: String
    let parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    let text: String
}

private struct GeminiGenerationConfig: Codable {
    let temperature: Double
    let topP: Double

    enum CodingKeys: String, CodingKey {
        case temperature
        case topP = "topP"
    }
}

struct GeminiResponse: Codable {
    struct Candidate: Codable {
        struct Content: Codable {
            struct Part: Codable {
                let text: String
            }

            let parts: [Part]
        }

        let content: Content
    }

    let candidates: [Candidate]
}

private struct GeminiModelListResponse: Codable {
    let models: [GeminiListedModel]
}

private struct GeminiListedModel: Codable {
    let name: String
    let baseModelID: String?
    let supportedGenerationMethods: [String]

    enum CodingKeys: String, CodingKey {
        case name
        case baseModelID = "baseModelId"
        case supportedGenerationMethods
    }
}

struct OllamaTagsResponse: Codable {
    let models: [OllamaModel]
}

struct OllamaModel: Codable, Identifiable {
    var id: String { name }
    let name: String
    let size: Int64
    let details: ModelDetails
}

struct ModelDetails: Codable {
    let format: String
    let family: String
    let parameter_size: String
}

private struct GenericAPIErrorResponse: Codable {
    struct ErrorPayload: Codable {
        let message: String?
    }

    let error: ErrorPayload?
    let message: String?

    var readableMessage: String {
        error?.message ?? message ?? "The upstream API returned an error."
    }
}
