import Foundation
import Combine

final class ConversationStore: ObservableObject {
    static let shared = ConversationStore()

    @Published private(set) var sessions: [ChatSession] = []
    @Published private(set) var activeSessionID: UUID?

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let saveURL: URL

    private init() {
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = applicationSupport.appendingPathComponent("CognitiveEther", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        saveURL = directory.appendingPathComponent("conversations.json")

        load()
        if sessions.isEmpty {
            createNewSession()
        } else if activeSessionID == nil || !sessions.contains(where: { $0.id == activeSessionID }) {
            activeSessionID = sessions[0].id
        }
    }

    var activeSession: ChatSession? {
        guard let activeSessionID else { return sessions.first }
        return sessions.first(where: { $0.id == activeSessionID })
    }

    func createNewSession() {
        let welcome = Message(
            content: "Welcome to Cognitive Ether. Your conversations are now persisted locally, so we can continue where we left off.",
            role: .assistant
        )

        let session = ChatSession(
            title: "New Conversation",
            messages: [welcome]
        )

        sessions.insert(session, at: 0)
        activeSessionID = session.id
        save()
    }

    func selectSession(id: UUID) {
        guard sessions.contains(where: { $0.id == id }) else { return }
        activeSessionID = id
        save()
    }

    func clearHistory() {
        sessions.removeAll()
        activeSessionID = nil
        save()
        createNewSession()
    }

    func updateSessionMetadata(id: UUID, provider: AIProvider, model: String) {
        mutateSession(id: id) { session in
            session.providerID = provider.rawValue
            session.modelName = model
        }
    }

    func appendMessage(_ message: Message, to sessionID: UUID) {
        mutateSession(id: sessionID) { session in
            session.messages.append(message)
            session.updatedAt = message.timestamp

            if session.title == "New Conversation", message.role == .user {
                session.title = Self.makeTitle(from: message.content)
            }
        }
    }

    func removeThinkingMessages(from sessionID: UUID) {
        mutateSession(id: sessionID) { session in
            session.messages.removeAll(where: { $0.role == .reasoning || $0.isThinking })
            session.updatedAt = Date()
        }
    }

    func messages(for sessionID: UUID?) -> [Message] {
        guard let sessionID else {
            return activeSession?.messages ?? []
        }

        return sessions.first(where: { $0.id == sessionID })?.messages ?? []
    }

    func recentMemoryContext(excluding sessionID: UUID?, limit: Int = 3) -> String? {
        let memories = sessions
            .filter { $0.id != sessionID }
            .sorted(by: { $0.updatedAt > $1.updatedAt })
            .prefix(limit)
            .compactMap { session -> String? in
                guard let userPrompt = session.messages.last(where: { $0.role == .user })?.content else {
                    return nil
                }

                let assistantReply = session.messages.last(where: { $0.role == .assistant })?.content ?? ""
                let trimmedReply = assistantReply.trimmingCharacters(in: .whitespacesAndNewlines)

                return """
                - \(session.title)
                  User: \(Self.truncate(userPrompt))
                  Assistant: \(Self.truncate(trimmedReply))
                """
            }

        guard !memories.isEmpty else { return nil }

        return """
        Previous conversation memory:
        \(memories.joined(separator: "\n"))
        """
    }

    var totalMessageCount: Int {
        sessions.reduce(0) { $0 + $1.totalMessageCount }
    }

    var configuredProvidersInHistory: [String: Int] {
        sessions.reduce(into: [:]) { partialResult, session in
            guard let providerID = session.providerID else { return }
            partialResult[providerID, default: 0] += 1
        }
    }

    private func mutateSession(id: UUID, mutation: (inout ChatSession) -> Void) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        mutation(&sessions[index])
        let updated = sessions.remove(at: index)
        sessions.insert(updated, at: 0)
        if activeSessionID == nil {
            activeSessionID = updated.id
        }
        save()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }

        do {
            let data = try Data(contentsOf: saveURL)
            let persisted = try decoder.decode(PersistedConversations.self, from: data)
            sessions = persisted.sessions.sorted(by: { $0.updatedAt > $1.updatedAt })
            activeSessionID = persisted.activeSessionID
        } catch {
            sessions = []
            activeSessionID = nil
        }
    }

    private func save() {
        do {
            let payload = PersistedConversations(
                activeSessionID: activeSessionID,
                sessions: sessions
            )
            let data = try encoder.encode(payload)
            try data.write(to: saveURL, options: [.atomic])
        } catch {
            print("Failed to persist conversations: \(error)")
        }
    }

    static func makeTitle(from content: String) -> String {
        let cleaned = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")

        guard !cleaned.isEmpty else {
            return "New Conversation"
        }

        let words = cleaned.split(separator: " ").prefix(6)
        let candidate = words.joined(separator: " ")
        return candidate.count > 48 ? String(candidate.prefix(48)) : candidate
    }

    private static func truncate(_ value: String, maxLength: Int = 120) -> String {
        let cleaned = value
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.count > maxLength else { return cleaned }
        return String(cleaned.prefix(maxLength - 3)) + "..."
    }
}

private struct PersistedConversations: Codable {
    let activeSessionID: UUID?
    let sessions: [ChatSession]
}
