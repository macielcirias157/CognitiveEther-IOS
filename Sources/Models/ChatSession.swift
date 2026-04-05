import Foundation

struct ChatSession: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    let createdAt: Date
    var updatedAt: Date
    var providerID: String?
    var modelName: String?
    var messages: [Message]

    init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        providerID: String? = nil,
        modelName: String? = nil,
        messages: [Message] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.providerID = providerID
        self.modelName = modelName
        self.messages = messages
    }

    var previewText: String {
        messages
            .filter { $0.role != .reasoning }
            .last?
            .content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            ?? "No messages yet."
    }

    var userMessageCount: Int {
        messages.filter { $0.role == .user }.count
    }

    var totalMessageCount: Int {
        messages.filter { $0.role != .reasoning }.count
    }
}
