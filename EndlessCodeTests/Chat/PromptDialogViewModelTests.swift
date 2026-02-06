//
//  PromptDialogViewModelTests.swift
//  EndlessCodeTests
//
//  PromptDialogViewModel 단위 테스트
//

#if canImport(AppKit)
import Testing
@testable import EndlessCode

// MARK: - PromptDialogViewModel Tests

@Suite("PromptDialogViewModel Tests")
struct PromptDialogViewModelTests {
    // MARK: - Initialization Tests

    @Test("Init with single select prompt sets correct state")
    @MainActor
    func initWithSingleSelectPrompt() {
        // Given
        let prompt = AskUserQuestion(
            toolUseId: "tool-123",
            question: "Choose one",
            options: [
                QuestionOption(label: "Option A"),
                QuestionOption(label: "Option B")
            ],
            multiSelect: false
        )

        // When
        let sut = PromptDialogViewModel(prompt: prompt)

        // Then
        #expect(sut.prompt.toolUseId == "tool-123")
        #expect(sut.prompt.question == "Choose one")
        #expect(sut.prompt.multiSelect == false)
        #expect(sut.selectedOptions.isEmpty)
        #expect(sut.customInput.isEmpty)
        #expect(sut.isSubmitted == false)
        #expect(sut.canSubmit == false)
    }

    @Test("Init with multi select prompt sets correct state")
    @MainActor
    func initWithMultiSelectPrompt() {
        // Given
        let prompt = AskUserQuestion(
            toolUseId: "tool-456",
            question: "Choose multiple",
            options: [
                QuestionOption(label: "Option A"),
                QuestionOption(label: "Option B"),
                QuestionOption(label: "Option C")
            ],
            multiSelect: true
        )

        // When
        let sut = PromptDialogViewModel(prompt: prompt)

        // Then
        #expect(sut.prompt.multiSelect == true)
        #expect(sut.selectedOptions.isEmpty)
        #expect(sut.canSubmit == false)
    }

    // MARK: - Single Select Tests

    @Test("Toggle option in single select replaces previous selection")
    @MainActor
    func toggleOptionInSingleSelect() {
        // Given
        let prompt = AskUserQuestion(
            toolUseId: "tool-123",
            question: "Choose one",
            options: [
                QuestionOption(label: "Option A"),
                QuestionOption(label: "Option B")
            ],
            multiSelect: false
        )
        let sut = PromptDialogViewModel(prompt: prompt)

        // When
        sut.toggleOption("Option A")
        #expect(sut.selectedOptions == ["Option A"])
        #expect(sut.isSelected("Option A") == true)
        #expect(sut.isSelected("Option B") == false)

        sut.toggleOption("Option B")

        // Then
        #expect(sut.selectedOptions == ["Option B"])
        #expect(sut.isSelected("Option A") == false)
        #expect(sut.isSelected("Option B") == true)
    }

    @Test("Can submit after selecting option in single select")
    @MainActor
    func canSubmitAfterSelectingOptionInSingleSelect() {
        // Given
        let prompt = AskUserQuestion(
            toolUseId: "tool-123",
            question: "Choose one",
            options: [QuestionOption(label: "Option A")],
            multiSelect: false
        )
        let sut = PromptDialogViewModel(prompt: prompt)

        // When
        sut.toggleOption("Option A")

        // Then
        #expect(sut.canSubmit == true)
    }

    // MARK: - Multi Select Tests

    @Test("Toggle option in multi select adds and removes")
    @MainActor
    func toggleOptionInMultiSelect() {
        // Given
        let prompt = AskUserQuestion(
            toolUseId: "tool-456",
            question: "Choose multiple",
            options: [
                QuestionOption(label: "Option A"),
                QuestionOption(label: "Option B")
            ],
            multiSelect: true
        )
        let sut = PromptDialogViewModel(prompt: prompt)

        // When
        sut.toggleOption("Option A")
        #expect(sut.selectedOptions.contains("Option A"))
        #expect(sut.isSelected("Option A") == true)

        sut.toggleOption("Option B")
        #expect(sut.selectedOptions.contains("Option A"))
        #expect(sut.selectedOptions.contains("Option B"))
        #expect(sut.isSelected("Option B") == true)

        sut.toggleOption("Option A")

        // Then
        #expect(!sut.selectedOptions.contains("Option A"))
        #expect(sut.selectedOptions.contains("Option B"))
        #expect(sut.isSelected("Option A") == false)
        #expect(sut.isSelected("Option B") == true)
    }

    @Test("Can submit when at least one option selected in multi select")
    @MainActor
    func canSubmitWithOneOptionInMultiSelect() {
        // Given
        let prompt = AskUserQuestion(
            toolUseId: "tool-456",
            question: "Choose multiple",
            options: [
                QuestionOption(label: "Option A"),
                QuestionOption(label: "Option B")
            ],
            multiSelect: true
        )
        let sut = PromptDialogViewModel(prompt: prompt)

        // When
        sut.toggleOption("Option A")

        // Then
        #expect(sut.canSubmit == true)
    }

    // MARK: - Custom Input Tests

    @Test("Can submit with custom input")
    @MainActor
    func canSubmitWithCustomInput() {
        // Given
        let prompt = AskUserQuestion(
            toolUseId: "tool-789",
            question: "Enter custom value",
            options: nil,
            multiSelect: false
        )
        let sut = PromptDialogViewModel(prompt: prompt)

        // When
        sut.customInput = "My custom answer"

        // Then
        #expect(sut.canSubmit == true)
    }

    @Test("Cannot submit with whitespace-only custom input")
    @MainActor
    func cannotSubmitWithWhitespaceOnlyCustomInput() {
        // Given
        let prompt = AskUserQuestion(
            toolUseId: "tool-789",
            question: "Enter custom value",
            options: nil,
            multiSelect: false
        )
        let sut = PromptDialogViewModel(prompt: prompt)

        // When
        sut.customInput = "   \n\t  "

        // Then
        #expect(sut.canSubmit == false)
    }

    @Test("Custom input takes priority over selected options")
    @MainActor
    func customInputTakesPriorityOverSelectedOptions() {
        // Given
        let prompt = AskUserQuestion(
            toolUseId: "tool-123",
            question: "Choose or enter",
            options: [QuestionOption(label: "Option A")],
            multiSelect: false
        )
        let sut = PromptDialogViewModel(prompt: prompt)

        // When
        sut.toggleOption("Option A")
        sut.customInput = "Custom value"
        let response = sut.submit()

        // Then
        #expect(response.customInput == "Custom value")
        #expect(response.selectedOptions == ["Option A"])
    }

    // MARK: - Submit Tests

    @Test("Submit returns correct response with selected options")
    @MainActor
    func submitReturnsCorrectResponseWithSelectedOptions() {
        // Given
        let prompt = AskUserQuestion(
            toolUseId: "tool-123",
            question: "Choose",
            options: [QuestionOption(label: "Option A")],
            multiSelect: false
        )
        let sut = PromptDialogViewModel(prompt: prompt)
        sut.toggleOption("Option A")

        // When
        let response = sut.submit()

        // Then
        #expect(response.toolUseId == "tool-123")
        #expect(response.selectedOptions == ["Option A"])
        #expect(response.customInput == nil)
        #expect(sut.isSubmitted == true)
    }

    @Test("Submit returns correct response with custom input")
    @MainActor
    func submitReturnsCorrectResponseWithCustomInput() {
        // Given
        let prompt = AskUserQuestion(
            toolUseId: "tool-456",
            question: "Enter value",
            options: nil,
            multiSelect: false
        )
        let sut = PromptDialogViewModel(prompt: prompt)
        sut.customInput = "  My answer  "

        // When
        let response = sut.submit()

        // Then
        #expect(response.toolUseId == "tool-456")
        #expect(response.selectedOptions.isEmpty)
        #expect(response.customInput == "My answer")
        #expect(sut.isSubmitted == true)
    }

    @Test("Submit returns multiple selected options in multi select")
    @MainActor
    func submitReturnsMultipleSelectedOptionsInMultiSelect() {
        // Given
        let prompt = AskUserQuestion(
            toolUseId: "tool-789",
            question: "Choose multiple",
            options: [
                QuestionOption(label: "Option A"),
                QuestionOption(label: "Option B"),
                QuestionOption(label: "Option C")
            ],
            multiSelect: true
        )
        let sut = PromptDialogViewModel(prompt: prompt)
        sut.toggleOption("Option A")
        sut.toggleOption("Option C")

        // When
        let response = sut.submit()

        // Then
        #expect(response.toolUseId == "tool-789")
        #expect(response.selectedOptions.count == 2)
        #expect(response.selectedOptions.contains("Option A"))
        #expect(response.selectedOptions.contains("Option C"))
        #expect(!response.selectedOptions.contains("Option B"))
    }

    @Test("Cannot submit after already submitted")
    @MainActor
    func cannotSubmitAfterAlreadySubmitted() {
        // Given
        let prompt = AskUserQuestion(
            toolUseId: "tool-123",
            question: "Choose",
            options: [QuestionOption(label: "Option A")],
            multiSelect: false
        )
        let sut = PromptDialogViewModel(prompt: prompt)
        sut.toggleOption("Option A")
        _ = sut.submit()

        // When
        #expect(sut.canSubmit == false)
        #expect(sut.isSubmitted == true)
    }

    @Test("Cannot toggle options after submission")
    @MainActor
    func cannotToggleOptionsAfterSubmission() {
        // Given
        let prompt = AskUserQuestion(
            toolUseId: "tool-123",
            question: "Choose",
            options: [
                QuestionOption(label: "Option A"),
                QuestionOption(label: "Option B")
            ],
            multiSelect: false
        )
        let sut = PromptDialogViewModel(prompt: prompt)
        sut.toggleOption("Option A")
        _ = sut.submit()

        // When
        sut.toggleOption("Option B")

        // Then: Option A should still be selected, B should not
        #expect(sut.selectedOptions == ["Option A"])
        #expect(sut.isSelected("Option B") == false)
    }

    @Test("Submit without selection returns empty response")
    @MainActor
    func submitWithoutSelectionReturnsEmptyResponse() {
        // Given
        let prompt = AskUserQuestion(
            toolUseId: "tool-123",
            question: "Choose",
            options: [QuestionOption(label: "Option A")],
            multiSelect: false
        )
        let sut = PromptDialogViewModel(prompt: prompt)

        // When
        let response = sut.submit()

        // Then
        #expect(response.toolUseId == "tool-123")
        #expect(response.selectedOptions.isEmpty)
        #expect(response.customInput == nil)
    }
}
#endif
