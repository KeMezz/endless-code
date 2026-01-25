//
//  MessageInputView.swift
//  EndlessCode
//
//  메시지 입력 컴포넌트
//

import SwiftUI

// MARK: - MessageInputView

/// 메시지 입력 뷰
struct MessageInputView: View {
    @Binding var text: String
    let isLoading: Bool
    let canSend: Bool
    let onSend: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            attachmentButton

            textEditor

            sendButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(nsColor: .controlBackgroundColor))
        .accessibilityIdentifier("messageInputView")
    }

    // MARK: - Subviews

    @ViewBuilder
    private var attachmentButton: some View {
        Button {
            // TODO(Section-3.3): 첨부 파일 기능 - 파일 선택 다이얼로그 및 업로드 구현
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("attachmentButton")
        .accessibilityLabel("Attach file")
    }

    @ViewBuilder
    private var textEditor: some View {
        TextField("Ask Claude to write code...", text: $text, axis: .vertical)
            .textFieldStyle(.plain)
            .font(.body)
            .lineLimit(1...8)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .focused($isFocused)
            .onKeyPress(.return, phases: .down) { keyPress in
                if keyPress.modifiers.contains(.shift) {
                    // Shift+Enter: 줄바꿈 추가
                    text += "\n"
                    return .handled
                } else if canSend {
                    // Enter만: 전송
                    onSend()
                    return .handled
                }
                return .ignored
            }
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isFocused ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .accessibilityIdentifier("messageInput")
    }

    @ViewBuilder
    private var sendButton: some View {
        Button {
            onSend()
        } label: {
            ZStack {
                Circle()
                    .fill(canSend ? Color.accentColor : Color.secondary.opacity(0.2))

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .progressViewStyle(.circular)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(canSend ? .white : .secondary)
                }
            }
            .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .disabled(!canSend || isLoading)
        .animation(.easeInOut(duration: 0.15), value: canSend)
        .accessibilityIdentifier("sendButton")
        .accessibilityLabel(isLoading ? "Sending message" : "Send message")
    }
}

// MARK: - Preview

#Preview("Empty") {
    VStack {
        Spacer()
        MessageInputView(
            text: .constant(""),
            isLoading: false,
            canSend: false,
            onSend: {}
        )
    }
    .frame(width: 600, height: 200)
}

#Preview("With Text") {
    VStack {
        Spacer()
        MessageInputView(
            text: .constant("Can you help me refactor this code?"),
            isLoading: false,
            canSend: true,
            onSend: {}
        )
    }
    .frame(width: 600, height: 200)
}

#Preview("Loading") {
    VStack {
        Spacer()
        MessageInputView(
            text: .constant(""),
            isLoading: true,
            canSend: false,
            onSend: {}
        )
    }
    .frame(width: 600, height: 200)
}

#Preview("Multiline") {
    VStack {
        Spacer()
        MessageInputView(
            text: .constant("""
                This is a multiline message.
                It has several lines.
                And should expand the input area.
                Line 4
                Line 5
                """),
            isLoading: false,
            canSend: true,
            onSend: {}
        )
    }
    .frame(width: 600, height: 300)
}
