import Foundation
import Combine
import AppIntents
import SwiftUI

@available(iOS 16.0, *)
enum AIProvider: String, AppEnum {
    case ollama
    case openAI
    case deepSeek
    case gemini
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "AI Provider"
    static var caseDisplayRepresentations: [AIProvider: CaseDisplayRepresentation] = [
        .ollama: "Ollama",
        .openAI: "OpenAI",
        .deepSeek: "DeepSeek",
        .gemini: "Gemini"
    ]
}

class AIManager: ObservableObject {
    static let shared = AIManager()
    private let config = ConfigManager.shared
    
    @Published var lastResponse: String = ""
    @Published var isRequesting: Bool = false
    
    func generateResponse(prompt: String, provider: AIProvider, model: String) async throws -> String {
        switch provider {
        case .ollama:
            return try await callOllama(prompt: prompt, model: model)
        case .openAI:
            return try await callOpenAI(prompt: prompt, model: model)
        case .deepSeek:
            return try await callDeepSeek(prompt: prompt, model: model)
        case .gemini:
            return try await callGemini(prompt: prompt, model: model)
        }
    }
    
    private func callOllama(prompt: String, model: String) async throws -> String {
        let url = URL(string: "\(config.ollamaEndpoint)/api/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "system": config.defaultSystemPrompt,
            "stream": false
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OllamaResponse.self, from: data)
        return response.response
    }
    
    private func callOpenAI(prompt: String, model: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": config.defaultSystemPrompt],
                ["role": "user", "content": prompt]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return response.choices.first?.message.content ?? ""
    }
    
    private func callDeepSeek(prompt: String, model: String) async throws -> String {
        // DeepSeek uses OpenAI-compatible API
        let url = URL(string: "https://api.deepseek.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.deepSeekKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": config.defaultSystemPrompt],
                ["role": "user", "content": prompt]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return response.choices.first?.message.content ?? ""
    }
    
    private func callGemini(prompt: String, model: String) async throws -> String {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(config.geminiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(GeminiResponse.self, from: data)
        return response.candidates.first?.content.parts.first?.text ?? ""
    }
}

// Models for decoding
struct OllamaResponse: Codable {
    let response: String
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
