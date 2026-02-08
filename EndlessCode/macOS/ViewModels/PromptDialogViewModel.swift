//
//  PromptDialogViewModel.swift
//  EndlessCode
//
//  대화형 프롬프트 다이얼로그의 상태 관리
//

import Foundation

// MARK: - PromptDialogResponse

/// 프롬프트 다이얼로그 응답 데이터
struct PromptDialogResponse: Sendable {
    let toolUseId: String
    let selectedOptions: [String]
    let customInput: String?
}

// MARK: - PromptDialogViewModel

/// 대화형 프롬프트 다이얼로그의 상태를 관리하는 ViewModel
@Observable @MainActor
final class PromptDialogViewModel {
    // MARK: - Properties

    let prompt: AskUserQuestion

    private(set) var selectedOptions: Set<String> = []
    var customInput: String = ""
    private(set) var isSubmitted = false

    // MARK: - Computed Properties

    /// 제출 가능 여부
    var canSubmit: Bool {
        guard !isSubmitted else { return false }

        // 다중 선택이면 최소 하나 이상 선택되어야 함
        if prompt.multiSelect {
            return !selectedOptions.isEmpty || !customInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        // 단일 선택은 옵션 선택 또는 직접 입력
        return !selectedOptions.isEmpty || !customInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 옵션이 선택되었는지 확인
    func isSelected(_ label: String) -> Bool {
        selectedOptions.contains(label)
    }

    // MARK: - Initialization

    init(prompt: AskUserQuestion) {
        self.prompt = prompt
    }

    // MARK: - Actions

    /// 옵션 토글 (다중 선택) 또는 선택 (단일 선택)
    func toggleOption(_ label: String) {
        guard !isSubmitted else { return }

        if prompt.multiSelect {
            // 다중 선택: 토글
            if selectedOptions.contains(label) {
                selectedOptions.remove(label)
            } else {
                selectedOptions.insert(label)
            }
        } else {
            // 단일 선택: 기존 선택 해제 후 새로 선택
            selectedOptions = [label]
        }
    }

    /// 프롬프트 제출
    func submit() -> PromptDialogResponse {
        guard canSubmit else {
            return PromptDialogResponse(
                toolUseId: prompt.toolUseId,
                selectedOptions: [],
                customInput: nil
            )
        }

        isSubmitted = true

        let trimmedInput = customInput.trimmingCharacters(in: .whitespacesAndNewlines)

        return PromptDialogResponse(
            toolUseId: prompt.toolUseId,
            selectedOptions: Array(selectedOptions),
            customInput: trimmedInput.isEmpty ? nil : trimmedInput
        )
    }
}
