import Foundation

enum MessageRole {
    case user
    case assistant
    case reasoning
}

struct Message: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let role: MessageRole
    let timestamp: Date
    var isThinking: Bool = false
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}
