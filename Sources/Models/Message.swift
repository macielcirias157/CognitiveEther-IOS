import Foundation

enum MessageRole: String, Codable {
    case user
    case assistant
    case reasoning
}

struct Message: Identifiable, Equatable, Codable {
    let id: UUID
    let content: String
    let role: MessageRole
    let timestamp: Date
    var isThinking: Bool = false

    init(
        id: UUID = UUID(),
        content: String,
        role: MessageRole,
        timestamp: Date = Date(),
        isThinking: Bool = false
    ) {
        self.id = id
        self.content = content
        self.role = role
        self.timestamp = timestamp
        self.isThinking = isThinking
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}
