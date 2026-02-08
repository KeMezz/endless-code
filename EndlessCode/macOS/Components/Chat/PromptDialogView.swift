//
//  PromptDialogView.swift
//  EndlessCode
//
//  대화형 프롬프트 다이얼로그 UI
//

import SwiftUI

// MARK: - PromptDialogView

/// 대화형 프롬프트 다이얼로그 뷰
struct PromptDialogView: View {
    @State private var viewModel: PromptDialogViewModel
    let onPromptDialogResponse: (PromptDialogResponse) -> Void

    init(prompt: AskUserQuestion, onPromptDialogResponse: @escaping (PromptDialogResponse) -> Void) {
        self._viewModel = State(initialValue: PromptDialogViewModel(prompt: prompt))
        self.onPromptDialogResponse = onPromptDialogResponse
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 질문 텍스트
            questionSection

            // 옵션 목록
            if let options = viewModel.prompt.options, !options.isEmpty {
                optionsSection(options: options)
            }

            // 직접 입력 필드
            customInputSection

            // 제출 버튼 (다중 선택일 때만)
            if viewModel.prompt.multiSelect {
                submitButton
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
        .accessibilityIdentifier("promptDialog-\(viewModel.prompt.toolUseId)")
    }

    // MARK: - Subviews

    @ViewBuilder
    private var questionSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "questionmark.circle.fill")
                .foregroundStyle(.purple)
                .font(.title3)

            Text(viewModel.prompt.question)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .accessibilityIdentifier("promptQuestion")
    }

    @ViewBuilder
    private func optionsSection(options: [QuestionOption]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(options) { option in
                optionButton(option: option)
            }
        }
    }

    @ViewBuilder
    private func optionButton(option: QuestionOption) -> some View {
        Button {
            handleOptionSelection(option.label)
        } label: {
            HStack(spacing: 12) {
                // 선택 인디케이터
                if viewModel.prompt.multiSelect {
                    // 체크박스
                    Image(systemName: viewModel.isSelected(option.label) ? "checkmark.square.fill" : "square")
                        .foregroundStyle(viewModel.isSelected(option.label) ? Color.accentColor : .secondary)
                        .font(.title3)
                } else {
                    // 라디오 버튼
                    Image(systemName: viewModel.isSelected(option.label) ? "circle.inset.filled" : "circle")
                        .foregroundStyle(viewModel.isSelected(option.label) ? Color.accentColor : .secondary)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.label)
                        .font(.body)
                        .foregroundStyle(.primary)

                    if let description = option.description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.isSelected(option.label) ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        viewModel.isSelected(option.label) ? Color.accentColor : Color.secondary.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSubmitted)
        .accessibilityIdentifier("promptOption-\(option.label)")
    }

    @ViewBuilder
    private var customInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("또는 직접 입력:")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TextField("답변을 입력하세요", text: $viewModel.customInput)
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.isSubmitted)
                    .onSubmit {
                        if !viewModel.prompt.multiSelect && viewModel.canSubmit {
                            submitResponse()
                        }
                    }
                    .accessibilityIdentifier("promptCustomInput")

                // 단일 선택일 때는 Enter 키 또는 버튼으로 제출
                if !viewModel.prompt.multiSelect {
                    Button {
                        submitResponse()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(viewModel.canSubmit ? Color.accentColor : Color.secondary.opacity(0.3))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.canSubmit || viewModel.isSubmitted)
                    .accessibilityIdentifier("promptSubmitButton")
                }
            }
        }
    }

    @ViewBuilder
    private var submitButton: some View {
        Button {
            submitResponse()
        } label: {
            HStack {
                Spacer()
                Text(viewModel.isSubmitted ? "제출됨" : "제출")
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.canSubmit && !viewModel.isSubmitted ? Color.accentColor : Color.secondary.opacity(0.3))
            )
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSubmit || viewModel.isSubmitted)
        .accessibilityIdentifier("promptSubmitButton")
    }

    // MARK: - Actions

    private func handleOptionSelection(_ label: String) {
        viewModel.toggleOption(label)

        // 단일 선택이면 즉시 제출
        if !viewModel.prompt.multiSelect {
            submitResponse()
        }
    }

    private func submitResponse() {
        guard viewModel.canSubmit && !viewModel.isSubmitted else { return }

        let response = viewModel.submit()
        onPromptDialogResponse(response)
    }
}

// MARK: - Preview

#Preview("Single Select") {
    PromptDialogView(
        prompt: AskUserQuestion(
            toolUseId: "tool-123",
            question: "어떤 언어를 사용하시겠습니까?",
            options: [
                QuestionOption(label: "Swift", description: "Apple의 모던 프로그래밍 언어"),
                QuestionOption(label: "Kotlin", description: "JetBrains의 JVM 언어"),
                QuestionOption(label: "TypeScript", description: "타입 안전한 JavaScript")
            ],
            multiSelect: false
        ),
        onPromptDialogResponse: { response in
            print("Response: \(response)")
        }
    )
    .frame(width: 500)
    .padding()
}

#Preview("Multi Select") {
    PromptDialogView(
        prompt: AskUserQuestion(
            toolUseId: "tool-456",
            question: "사용할 프레임워크를 선택하세요 (복수 선택 가능)",
            options: [
                QuestionOption(label: "SwiftUI", description: "Apple의 선언형 UI 프레임워크"),
                QuestionOption(label: "Vapor", description: "서버 사이드 Swift 프레임워크"),
                QuestionOption(label: "Combine", description: "리액티브 프로그래밍 프레임워크")
            ],
            multiSelect: true
        ),
        onPromptDialogResponse: { response in
            print("Response: \(response)")
        }
    )
    .frame(width: 500)
    .padding()
}

#Preview("No Options") {
    PromptDialogView(
        prompt: AskUserQuestion(
            toolUseId: "tool-789",
            question: "프로젝트 이름을 입력하세요",
            options: nil,
            multiSelect: false
        ),
        onPromptDialogResponse: { response in
            print("Response: \(response)")
        }
    )
    .frame(width: 500)
    .padding()
}
