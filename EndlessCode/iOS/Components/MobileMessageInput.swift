//
//  MobileMessageInput.swift
//  EndlessCode
//
//  모바일 메시지 입력 컴포넌트
//

#if os(iOS)
import SwiftUI

struct MobileMessageInput: View {
    @Binding var text: String
    let onSend: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            TextField("Ask Claude to write code...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(white: 0.15))
                )
                .lineLimit(1...5)
                .accessibilityIdentifier("iosMobileMessageInput")

            Button {
                onSend()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSend ? .blue : .secondary)
            }
            .disabled(!canSend)
            .accessibilityIdentifier("iosSendButton")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Preview

#Preview("Empty") {
    VStack {
        Spacer()
        MobileMessageInput(text: .constant(""), onSend: {})
    }
    .background(Color(white: 0.1))
    .preferredColorScheme(.dark)
}

#Preview("With Text") {
    VStack {
        Spacer()
        MobileMessageInput(
            text: .constant("Can you help me refactor this SwiftUI view?"),
            onSend: {}
        )
    }
    .background(Color(white: 0.1))
    .preferredColorScheme(.dark)
}

#Preview("Multi-line") {
    VStack {
        Spacer()
        MobileMessageInput(
            text: .constant("This is a very long message\nthat spans multiple lines\nto test the text field behavior"),
            onSend: {}
        )
    }
    .background(Color(white: 0.1))
    .preferredColorScheme(.dark)
}
#endif
