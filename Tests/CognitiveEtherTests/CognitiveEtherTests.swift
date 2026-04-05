import XCTest
@testable import CognitiveEther

final class CognitiveEtherTests: XCTestCase {
    func testConversationTitleUsesFirstWords() throws {
        let title = ConversationStore.makeTitle(from: "Build a real persistence layer for chat history and secure settings")
        XCTAssertEqual(title, "Build a real persistence layer for")
    }

    func testConversationTitleFallsBackWhenEmpty() throws {
        let title = ConversationStore.makeTitle(from: "   ")
        XCTAssertEqual(title, "New Conversation")
    }

    func testSessionPreviewUsesLastRenderableMessage() throws {
        let session = ChatSession(
            title: "Preview",
            messages: [
                Message(content: "Thinking", role: .reasoning, isThinking: true),
                Message(content: "User message", role: .user),
                Message(content: "Assistant reply", role: .assistant)
            ]
        )

        XCTAssertEqual(session.previewText, "Assistant reply")
    }

    func testPromptPresetCatalogIsPopulated() throws {
        XCTAssertFalse(PromptPreset.catalog.isEmpty)
        XCTAssertTrue(PromptPreset.catalog.contains(where: { $0.title == "Pragmatic Engineer" }))
    }
}
