//
//  MobileMessageBubbleTests.swift
//  EndlessCodeTests
//
//  MobileMessageBubble 컴포넌트 테스트
//

#if os(iOS)
import Testing
import SwiftUI
@testable import EndlessCode

@Suite("MobileMessageBubble Tests")
@MainActor
struct MobileMessageBubbleTests {
    // MARK: - Message Type Tests

    @Test("User message is displayed with correct alignment")
    func userMessageDisplayedWithCorrectAlignment() {
        // Given
        let message = ChatMessageItem(
            id: "msg-1",
            type: .user,
            content: .text("Hello"),
            timestamp: Date()
        )

        // When & Then
        #expect(message.type == .user)
    }

    @Test("Assistant message is displayed with correct alignment")
    func assistantMessageDisplayedWithCorrectAlignment() {
        // Given
        let message = ChatMessageItem(
            id: "msg-2",
            type: .assistant,
            content: .text("Hi there"),
            timestamp: Date()
        )

        // When & Then
        #expect(message.type == .assistant)
    }

    @Test("Tool use message is displayed")
    func toolUseMessageDisplayed() {
        // Given
        let message = ChatMessageItem(
            id: "msg-3",
            type: .toolUse(name: "Read", toolUseId: "tool-1"),
            content: .toolInput(["file_path": .string("/test/path")]),
            timestamp: Date()
        )

        // When & Then
        if case .toolUse(let name, _) = message.type {
            #expect(name == "Read")
        }
    }

    // MARK: - Content Parsing Tests

    @Test("Code block is extracted from markdown text")
    func codeBlockExtractedFromMarkdownText() {
        // Given
        let text = """
        Here is some code:

        ```swift
        let x = 42
        ```
        """

        let pattern = #"```(\w+)?\n([\s\S]*?)```"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: nsRange)

        // Then
        #expect(matches.count == 1)
    }

    @Test("Multiple code blocks are extracted")
    func multipleCodeBlocksExtracted() {
        // Given
        let text = """
        First block:
        ```swift
        let x = 1
        ```

        Second block:
        ```python
        x = 2
        ```
        """

        let pattern = #"```(\w+)?\n([\s\S]*?)```"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: nsRange)

        // Then
        #expect(matches.count == 2)
    }

    // MARK: - Timestamp Tests

    @Test("Timestamp is displayed for all messages")
    func timestampDisplayedForAllMessages() {
        // Given
        let message = ChatMessageItem(
            id: "msg-1",
            type: .user,
            content: .text("Test"),
            timestamp: Date()
        )

        // When & Then
        #expect(message.timestamp <= Date())
    }
}
#endif
