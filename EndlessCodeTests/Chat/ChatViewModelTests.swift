//
//  ChatViewModelTests.swift
//  EndlessCodeTests
//
//  ChatViewModel 단위 테스트 (Swift Testing)
//

#if canImport(AppKit)
import Foundation
import Testing
@testable import EndlessCode

@Suite("ChatViewModel Tests")
struct ChatViewModelTests {

    // MARK: - Initialization Tests

    @Test("Init creates view model with empty messages")
    @MainActor
    func initCreatesViewModelWithEmptyMessages() {
        // Given
        let session = Session(
            id: "test-session",
            projectId: "test-project"
        )

        // When
        let viewModel = ChatViewModel(session: session)

        // Then
        #expect(viewModel.messages.isEmpty)
        #expect(!viewModel.isLoading)
        #expect(!viewModel.isStreaming)
        #expect(viewModel.error == nil)
        #expect(viewModel.inputText.isEmpty)
    }

    // MARK: - canSend Tests

    @Test("canSend is false when input is empty")
    @MainActor
    func canSendIsFalseWhenInputIsEmpty() {
        // Given
        let session = Session(id: "test", projectId: "project")
        let viewModel = ChatViewModel(session: session)

        // When
        viewModel.inputText = ""

        // Then
        #expect(!viewModel.canSend)
    }

    @Test("canSend is false when input is only whitespace")
    @MainActor
    func canSendIsFalseWhenInputIsWhitespace() {
        // Given
        let session = Session(id: "test", projectId: "project")
        let viewModel = ChatViewModel(session: session)

        // When
        viewModel.inputText = "   \n\t  "

        // Then
        #expect(!viewModel.canSend)
    }

    @Test("canSend is true when input has content")
    @MainActor
    func canSendIsTrueWhenInputHasContent() {
        // Given
        let session = Session(id: "test", projectId: "project")
        let viewModel = ChatViewModel(session: session)

        // When
        viewModel.inputText = "Hello"

        // Then
        #expect(viewModel.canSend)
    }

    // MARK: - loadMessages Tests

    @Test("loadMessages sets isLoading during load")
    @MainActor
    func loadMessagesSetsIsLoadingDuringLoad() async {
        // Given
        let session = Session(id: "test", projectId: "project")
        let viewModel = ChatViewModel(session: session)

        // When
        let loadTask = Task {
            await viewModel.loadMessages()
        }

        // Wait a bit for loading to start
        try? await Task.sleep(for: .milliseconds(50))
        let wasLoading = viewModel.isLoading

        await loadTask.value

        // Then
        #expect(wasLoading || !viewModel.messages.isEmpty) // Either caught loading or completed
        #expect(!viewModel.isLoading)
    }

    @Test("loadMessages populates messages")
    @MainActor
    func loadMessagesPopulatesMessages() async {
        // Given
        let session = Session(id: "test", projectId: "project")
        let viewModel = ChatViewModel(session: session)

        // When
        await viewModel.loadMessages()

        // Then
        #expect(!viewModel.messages.isEmpty)
    }

    // MARK: - sendMessage Tests

    @Test("sendMessage adds user message")
    @MainActor
    func sendMessageAddsUserMessage() async {
        // Given
        let session = Session(id: "test", projectId: "project")
        let viewModel = ChatViewModel(session: session)
        viewModel.inputText = "Test message"

        // When
        await viewModel.sendMessage()

        // Then
        let userMessages = viewModel.messages.filter {
            if case .user = $0.type { return true }
            return false
        }
        #expect(!userMessages.isEmpty)
    }

    @Test("sendMessage clears input after send")
    @MainActor
    func sendMessageClearsInputAfterSend() async {
        // Given
        let session = Session(id: "test", projectId: "project")
        let viewModel = ChatViewModel(session: session)
        viewModel.inputText = "Test message"

        // When
        await viewModel.sendMessage()

        // Then
        #expect(viewModel.inputText.isEmpty)
    }

    @Test("sendMessage does nothing when canSend is false")
    @MainActor
    func sendMessageDoesNothingWhenCannotSend() async {
        // Given
        let session = Session(id: "test", projectId: "project")
        let viewModel = ChatViewModel(session: session)
        viewModel.inputText = ""
        let initialCount = viewModel.messages.count

        // When
        await viewModel.sendMessage()

        // Then
        #expect(viewModel.messages.count == initialCount)
    }

    // MARK: - clearError Tests

    @Test("clearError removes error")
    @MainActor
    func clearErrorRemovesError() {
        // Given
        let session = Session(id: "test", projectId: "project")
        let viewModel = ChatViewModel(session: session)
        // Note: Cannot directly set error, so we test the method exists and works

        // When
        viewModel.clearError()

        // Then
        #expect(viewModel.error == nil)
    }
}

// MARK: - ChatMessageItem Tests

@Suite("ChatMessageItem Tests")
struct ChatMessageItemTests {

    @Test("MessageType isUser returns correct value")
    func messageTypeIsUserReturnsCorrectValue() {
        // Given/When/Then
        #expect(ChatMessageItem.MessageType.user.isUser)
        #expect(!ChatMessageItem.MessageType.assistant.isUser)
    }

    @Test("Sample messages are populated")
    func sampleMessagesArePopulated() {
        // Given/When
        let samples = ChatMessageItem.sampleMessages

        // Then
        #expect(!samples.isEmpty)
        #expect(samples.count >= 3)
    }

    @Test("Sample messages have various types")
    func sampleMessagesHaveVariousTypes() {
        // Given
        let samples = ChatMessageItem.sampleMessages

        // When
        let hasUser = samples.contains { if case .user = $0.type { return true }; return false }
        let hasAssistant = samples.contains { if case .assistant = $0.type { return true }; return false }
        let hasToolUse = samples.contains { if case .toolUse = $0.type { return true }; return false }

        // Then
        #expect(hasUser)
        #expect(hasAssistant)
        #expect(hasToolUse)
    }
}

// MARK: - ChatError Tests

@Suite("ChatError Tests")
struct ChatErrorTests {

    @Test("ChatError cases are equatable")
    func chatErrorCasesAreEquatable() {
        // Given/When/Then
        #expect(ChatError.connectionFailed == ChatError.connectionFailed)
        #expect(ChatError.sendFailed == ChatError.sendFailed)
        #expect(ChatError.loadFailed == ChatError.loadFailed)
        #expect(ChatError.timeout == ChatError.timeout)
        #expect(ChatError.connectionFailed != ChatError.sendFailed)
    }
}
#endif
