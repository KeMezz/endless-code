//
//  MobileMessageBubble.swift
//  EndlessCode
//
//  모바일 메시지 버블 컴포넌트
//

#if os(iOS)
import SwiftUI

struct MobileMessageBubble: View {
    let message: ChatMessageItem

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.type == .user {
                Spacer(minLength: 40)
            }

            VStack(alignment: message.type == .user ? .trailing : .leading, spacing: 4) {
                // Message Content
                messageContent
                    .padding(12)
                    .background(bubbleBackground)
                    .cornerRadius(16)

                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }

            if message.type != .user {
                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Message Content

    @ViewBuilder
    private var messageContent: some View {
        switch message.content {
        case .text(let text), .streaming(let text):
            MarkdownText(text: text)
                .foregroundStyle(textColor)

        case .toolInput(let input):
            ToolInputView(input: input)

        case .toolOutput(let output):
            ToolOutputView(output: output)
        }
    }

    // MARK: - Bubble Background

    private var bubbleBackground: some View {
        Group {
            switch message.type {
            case .user:
                Color.blue
            case .assistant, .toolResult:
                Color(white: 0.2)
            case .toolUse:
                Color(white: 0.15)
            case .askUser:
                Color.orange.opacity(0.3)
            }
        }
    }

    // MARK: - Text Color

    private var textColor: Color {
        switch message.type {
        case .user:
            return .white
        default:
            return .primary
        }
    }
}

// MARK: - Markdown Text

private struct MarkdownText: View {
    let text: String

    var body: some View {
        // 간단한 마크다운 파싱 (실제로는 MarkdownUI 라이브러리 사용 권장)
        VStack(alignment: .leading, spacing: 8) {
            ForEach(parseContent(), id: \.self) { item in
                switch item {
                case .text(let content):
                    Text(content)
                        .textSelection(.enabled)

                case .code(let code, let language):
                    MobileCodeBlock(code: code, language: language)
                }
            }
        }
    }

    private static let codeBlockRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"```(\w+)?\n([\s\S]*?)```"#)
    }()

    private func parseContent() -> [ContentItem] {
        // 간단한 코드 블록 파싱
        var items: [ContentItem] = []

        guard let regex = Self.codeBlockRegex else {
            return [.text(text)]
        }

        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: nsRange)

        var lastIndex = text.startIndex

        for match in matches {
            // 코드 블록 이전의 텍스트
            if let beforeRange = Range(NSRange(location: lastIndex.utf16Offset(in: text), length: match.range.location - lastIndex.utf16Offset(in: text)), in: text) {
                let beforeText = String(text[beforeRange])
                if !beforeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    items.append(.text(beforeText))
                }
            }

            // 언어
            let language: String?
            if let langRange = Range(match.range(at: 1), in: text) {
                language = String(text[langRange])
            } else {
                language = nil
            }

            // 코드
            if let codeRange = Range(match.range(at: 2), in: text) {
                let code = String(text[codeRange])
                items.append(.code(code, language))
            }

            lastIndex = text.index(text.startIndex, offsetBy: match.range.location + match.range.length)
        }

        // 마지막 텍스트
        if lastIndex < text.endIndex {
            let remainingText = String(text[lastIndex...])
            if !remainingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                items.append(.text(remainingText))
            }
        }

        return items.isEmpty ? [.text(text)] : items
    }

    private enum ContentItem: Hashable {
        case text(String)
        case code(String, String?)
    }
}

// MARK: - Tool Input View

private struct ToolInputView: View {
    let input: [String: AnyCodableValue]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "wrench.fill")
                    .foregroundStyle(.orange)
                Text("Tool Input")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(input.keys.sorted()), id: \.self) { key in
                HStack(alignment: .top) {
                    Text("\(key):")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    if let value = input[key] {
                        Text(String(describing: value))
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }
}

// MARK: - Tool Output View

private struct ToolOutputView: View {
    let output: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Tool Output")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            Text(output)
                .font(.caption)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Preview

#Preview("User Message") {
    MobileMessageBubble(
        message: ChatMessageItem(
            id: "1",
            type: .user,
            content: .text("Can you help me refactor this code?"),
            timestamp: Date()
        )
    )
    .padding()
    .background(Color(white: 0.1))
    .preferredColorScheme(.dark)
}

#Preview("Assistant Message with Code") {
    MobileMessageBubble(
        message: ChatMessageItem(
            id: "2",
            type: .assistant,
            content: .text("""
Sure! Here's the refactored version:

```swift
struct ContentView: View {
    @State private var items: [Item] = []

    var body: some View {
        List(items) { item in
            ItemRow(item: item)
        }
    }
}
```

This separates concerns better.
"""),
            timestamp: Date()
        )
    )
    .padding()
    .background(Color(white: 0.1))
    .preferredColorScheme(.dark)
}

#Preview("Tool Use") {
    MobileMessageBubble(
        message: ChatMessageItem(
            id: "3",
            type: .toolUse(name: "Read", toolUseId: "tool-1"),
            content: .toolInput([
                "file_path": .string("/Users/demo/ContentView.swift")
            ]),
            timestamp: Date()
        )
    )
    .padding()
    .background(Color(white: 0.1))
    .preferredColorScheme(.dark)
}
#endif
