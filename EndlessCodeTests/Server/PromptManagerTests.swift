//
//  PromptManagerTests.swift
//  EndlessCodeTests
//
//  PromptManager 테스트 (Swift Testing)
//

import Testing
@testable import EndlessCode

@Suite("PromptManager Tests")
struct PromptManagerTests {

    // MARK: - Register Tests

    @Test("Register prompt creates pending prompt")
    func registerPromptCreatesPendingPrompt() async {
        // Given
        let manager = PromptManager(timeoutSeconds: 60)
        let question = AskUserQuestion(
            toolUseId: "tool123",
            question: "Continue?",
            options: [QuestionOption(label: "Yes"), QuestionOption(label: "No")]
        )

        // When
        let prompt = await manager.registerPrompt(
            sessionId: "session1",
            question: question
        )

        // Then
        #expect(prompt.sessionId == "session1")
        #expect(prompt.toolUseId == "tool123")
        #expect(prompt.question.question == "Continue?")
        #expect(prompt.state == .pending)
    }

    @Test("Get pending prompts returns only pending")
    func getPendingPromptsReturnsOnlyPending() async throws {
        // Given
        let manager = PromptManager(timeoutSeconds: 60)

        let question1 = AskUserQuestion(toolUseId: "t1", question: "Q1")
        let question2 = AskUserQuestion(toolUseId: "t2", question: "Q2")

        let prompt1 = await manager.registerPrompt(sessionId: "session1", question: question1)
        _ = await manager.registerPrompt(sessionId: "session1", question: question2)

        // Respond to first prompt
        _ = try await manager.respondToPrompt(
            promptId: prompt1.id,
            selectedOptions: ["Yes"],
            customInput: nil
        )

        // When
        let pending = await manager.getPendingPrompts(sessionId: "session1")

        // Then
        #expect(pending.count == 1)
        #expect(pending[0].question.question == "Q2")
    }

    // MARK: - Response Tests

    @Test("Respond to prompt changes state to responded")
    func respondToPromptChangesStateToResponded() async throws {
        // Given
        let manager = PromptManager(timeoutSeconds: 60)
        let question = AskUserQuestion(
            toolUseId: "tool123",
            question: "Continue?",
            options: [QuestionOption(label: "Yes"), QuestionOption(label: "No")]
        )
        let prompt = await manager.registerPrompt(sessionId: "session1", question: question)

        // When
        _ = try await manager.respondToPrompt(
            promptId: prompt.id,
            selectedOptions: ["Yes"],
            customInput: nil
        )

        // Then
        let updated = await manager.getPrompt(id: prompt.id)
        if case .responded = updated?.state {
            // Success
        } else {
            Issue.record("Expected responded state")
        }
    }

    @Test("Respond to prompt with custom input uses custom input")
    func respondToPromptWithCustomInputUsesCustomInput() async throws {
        // Given
        let manager = PromptManager(timeoutSeconds: 60)
        let question = AskUserQuestion(toolUseId: "tool123", question: "Enter name:")
        let prompt = await manager.registerPrompt(sessionId: "session1", question: question)

        // When
        let response = try await manager.respondToPrompt(
            promptId: prompt.id,
            selectedOptions: [],
            customInput: "Custom Response"
        )

        // Then
        #expect(response.contains("Custom Response"))
    }

    @Test("Respond to prompt not found throws error")
    func respondToPromptNotFoundThrowsError() async {
        // Given
        let manager = PromptManager(timeoutSeconds: 60)

        // When/Then
        await #expect {
            try await manager.respondToPrompt(
                promptId: "nonexistent",
                selectedOptions: ["Yes"],
                customInput: nil
            )
        } throws: { error in
            guard let promptError = error as? PromptError,
                  case .promptNotFound = promptError else {
                return false
            }
            return true
        }
    }

    @Test("Respond to prompt already responded throws error")
    func respondToPromptAlreadyRespondedThrowsError() async throws {
        // Given
        let manager = PromptManager(timeoutSeconds: 60)
        let question = AskUserQuestion(toolUseId: "tool123", question: "Q?")
        let prompt = await manager.registerPrompt(sessionId: "session1", question: question)

        _ = try await manager.respondToPrompt(
            promptId: prompt.id,
            selectedOptions: ["Yes"],
            customInput: nil
        )

        // When/Then
        await #expect {
            try await manager.respondToPrompt(
                promptId: prompt.id,
                selectedOptions: ["No"],
                customInput: nil
            )
        } throws: { error in
            guard let promptError = error as? PromptError,
                  case .promptNotPending = promptError else {
                return false
            }
            return true
        }
    }

    // MARK: - Cancel Tests

    @Test("Cancel prompt changes state to cancelled")
    func cancelPromptChangesStateToCancelled() async throws {
        // Given
        let manager = PromptManager(timeoutSeconds: 60)
        let question = AskUserQuestion(toolUseId: "tool123", question: "Q?")
        let prompt = await manager.registerPrompt(sessionId: "session1", question: question)

        // When
        try await manager.cancelPrompt(promptId: prompt.id)

        // Then
        let updated = await manager.getPrompt(id: prompt.id)
        #expect(updated?.state == .cancelled)
    }

    // MARK: - Timeout Tests

    @Test("Timeout changes state to timed out")
    func timeoutChangesStateToTimedOut() async throws {
        // Given - very short timeout
        let manager = PromptManager(timeoutSeconds: 1)
        let question = AskUserQuestion(toolUseId: "tool123", question: "Q?")
        _ = await manager.registerPrompt(sessionId: "session1", question: question)

        // When - wait for timeout with some margin
        try await Task.sleep(for: .seconds(2))

        // Then
        let expired = await manager.cleanupExpiredPrompts()
        #expect(expired.count == 1)
        #expect(expired[0].state == .timedOut)
    }

    // MARK: - Cleanup Tests

    @Test("Cleanup removes session prompts")
    func cleanupRemovesSessionPrompts() async {
        // Given
        let manager = PromptManager(timeoutSeconds: 60)

        let question1 = AskUserQuestion(toolUseId: "t1", question: "Q1")
        let question2 = AskUserQuestion(toolUseId: "t2", question: "Q2")

        _ = await manager.registerPrompt(sessionId: "session1", question: question1)
        _ = await manager.registerPrompt(sessionId: "session2", question: question2)

        // When
        await manager.cleanup(sessionId: "session1")

        // Then
        let session1Prompts = await manager.getPendingPrompts(sessionId: "session1")
        let session2Prompts = await manager.getPendingPrompts(sessionId: "session2")

        #expect(session1Prompts.count == 0)
        #expect(session2Prompts.count == 1)
    }

    // MARK: - Callback Tests

    @Test("On state change calls callback")
    func onStateChangeCallsCallback() async throws {
        // Given
        let manager = PromptManager(timeoutSeconds: 60)
        var callbackCalled = false
        var receivedPrompt: PendingPrompt?

        await manager.onStateChange { prompt in
            callbackCalled = true
            receivedPrompt = prompt
        }

        let question = AskUserQuestion(toolUseId: "tool123", question: "Q?")
        let prompt = await manager.registerPrompt(sessionId: "session1", question: question)

        // When
        _ = try await manager.respondToPrompt(
            promptId: prompt.id,
            selectedOptions: ["Yes"],
            customInput: nil
        )

        // Then
        #expect(callbackCalled)
        #expect(receivedPrompt?.id == prompt.id)
        if case .responded = receivedPrompt?.state {
            // Success
        } else {
            Issue.record("Expected responded state")
        }
    }

    // MARK: - MultiSelect Tests

    @Test("Respond to prompt multiSelect formats correctly")
    func respondToPromptMultiSelectFormatsCorrectly() async throws {
        // Given
        let manager = PromptManager(timeoutSeconds: 60)
        let question = AskUserQuestion(
            toolUseId: "tool123",
            question: "Select options:",
            options: [
                QuestionOption(label: "A"),
                QuestionOption(label: "B"),
                QuestionOption(label: "C")
            ],
            multiSelect: true
        )
        let prompt = await manager.registerPrompt(sessionId: "session1", question: question)

        // When
        let response = try await manager.respondToPrompt(
            promptId: prompt.id,
            selectedOptions: ["A", "C"],
            customInput: nil
        )

        // Then - should contain both options
        #expect(response.contains("A"))
        #expect(response.contains("C"))
    }
}

// MARK: - ParsedMessage Extension Tests

@Suite("ParsedMessage Extension Tests")
struct ParsedMessageExtensionTests {

    @Test("IsAskUserQuestion returns true for askUser")
    func isAskUserQuestionReturnsTrueForAskUser() {
        // Given
        let question = AskUserQuestion(toolUseId: "t1", question: "Q?")
        let message: ParsedMessage = .askUser(question)

        // Then
        #expect(message.isAskUserQuestion)
    }

    @Test("IsAskUserQuestion returns false for other types")
    func isAskUserQuestionReturnsFalseForOtherTypes() {
        // Given
        let chatMessage: ParsedMessage = .chat(ChatMessage(role: .assistant, content: "Hi"))
        let toolUse: ParsedMessage = .toolUse(ToolUseMessage(
            toolName: "Read",
            toolInput: [:],
            toolUseId: "t1"
        ))

        // Then
        #expect(!chatMessage.isAskUserQuestion)
        #expect(!toolUse.isAskUserQuestion)
    }

    @Test("AskUserQuestion returns question for askUser")
    func askUserQuestionReturnsQuestionForAskUser() {
        // Given
        let question = AskUserQuestion(toolUseId: "t1", question: "Q?")
        let message: ParsedMessage = .askUser(question)

        // Then
        #expect(message.askUserQuestion?.question == "Q?")
    }

    @Test("AskUserQuestion returns nil for other types")
    func askUserQuestionReturnsNilForOtherTypes() {
        // Given
        let chatMessage: ParsedMessage = .chat(ChatMessage(role: .assistant, content: "Hi"))

        // Then
        #expect(chatMessage.askUserQuestion == nil)
    }
}
