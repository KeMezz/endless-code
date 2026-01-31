//
//  MessageBubble.swift
//  EndlessCode
//
//  채팅 메시지 버블 컴포넌트
//

import SwiftUI

// MARK: - MessageBubble

/// 채팅 메시지 버블
struct MessageBubble: View {
    let message: ChatMessageItem
    let onCopyCode: ((String) -> Void)?
    let onViewDiff: ((UnifiedDiff) -> Void)?

    init(
        message: ChatMessageItem,
        onCopyCode: ((String) -> Void)? = nil,
        onViewDiff: ((UnifiedDiff) -> Void)? = nil
    ) {
        self.message = message
        self.onCopyCode = onCopyCode
        self.onViewDiff = onViewDiff
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if message.type.isUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.type.isUser ? .trailing : .leading, spacing: 4) {
                // 아바타 + 역할 레이블 행
                HStack(spacing: 8) {
                    if !message.type.isUser {
                        avatar
                    }
                    roleLabel
                    if message.type.isUser {
                        avatar
                    }
                }

                bubbleContent
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(bubbleBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                timestampLabel
            }

            if !message.type.isUser {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .accessibilityIdentifier("messageBubble-\(message.id)")
    }

    // MARK: - Subviews

    @ViewBuilder
    private var avatar: some View {
        ZStack {
            Circle()
                .fill(avatarColor.gradient)

            Image(systemName: avatarIcon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 32, height: 32)
        .accessibilityIdentifier("messageAvatar-\(message.type.isUser ? "user" : "assistant")")
    }

    @ViewBuilder
    private var roleLabel: some View {
        Text(roleText)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var bubbleContent: some View {
        switch message.content {
        case .text(let text):
            MessageTextContent(text: text, onCopyCode: onCopyCode)
        case .streaming(let text):
            HStack(alignment: .bottom, spacing: 4) {
                MessageTextContent(text: text, onCopyCode: onCopyCode)
                TypingIndicator()
            }
        case .toolInput(let input):
            ToolInputContent(input: input)
        case .toolOutput(let output):
            ToolOutputContent(output: output, onViewDiff: onViewDiff)
        }
    }

    @ViewBuilder
    private var timestampLabel: some View {
        Text(formattedTimestamp)
            .font(.caption2)
            .foregroundStyle(.tertiary)
    }

    private var bubbleBackground: some ShapeStyle {
        if message.type.isUser {
            return AnyShapeStyle(Color.accentColor.opacity(0.15))
        } else {
            return AnyShapeStyle(Color(nsColor: .controlBackgroundColor))
        }
    }

    // MARK: - Computed Properties

    private var avatarColor: Color {
        message.type.isUser ? .blue : .purple
    }

    private var avatarIcon: String {
        message.type.isUser ? "person.fill" : "sparkle"
    }

    private var roleText: String {
        switch message.type {
        case .user:
            return "You"
        case .assistant:
            return "Assistant"
        case .toolUse(let name, _):
            return "Tool: \(name)"
        case .toolResult(_, let isError):
            return isError ? "Error" : "Result"
        case .askUser:
            return "Question"
        }
    }

    private var formattedTimestamp: String {
        RelativeTimestampFormatter.shared.string(from: message.timestamp)
    }
}

// MARK: - MessageType Extension

extension ChatMessageItem.MessageType {
    var isUser: Bool {
        if case .user = self { return true }
        return false
    }
}

// MARK: - MessageTextContent

/// 텍스트 메시지 콘텐츠
struct MessageTextContent: View {
    /// 코드 블록 파싱용 정규표현식 (캐싱)
    private static let codeBlockRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "```(\\w*)\\n([\\s\\S]*?)```")
    }()

    let text: String
    let onCopyCode: ((String) -> Void)?

    // 파싱 결과를 init에서 미리 계산 (성능 최적화)
    private let parsedBlocks: [ContentBlock]

    init(text: String, onCopyCode: ((String) -> Void)? = nil) {
        self.text = text
        self.onCopyCode = onCopyCode
        self.parsedBlocks = Self.parseContent(text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(parsedBlocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .text(let content):
                    Text(content)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                case .code(let code, let language):
                    CodeBlockView(
                        code: code,
                        language: language,
                        onCopy: { onCopyCode?(code) }
                    )
                }
            }
        }
    }

    private static func parseContent(_ text: String) -> [ContentBlock] {
        var blocks: [ContentBlock] = []

        guard let regex = codeBlockRegex else {
            return [.text(text)]
        }

        let nsText = text as NSString
        var lastIndex = 0

        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        for match in matches {
            // 코드 블록 이전 텍스트
            if match.range.location > lastIndex {
                let textRange = NSRange(location: lastIndex, length: match.range.location - lastIndex)
                let textContent = nsText.substring(with: textRange).trimmingCharacters(in: .whitespacesAndNewlines)
                if !textContent.isEmpty {
                    blocks.append(.text(textContent))
                }
            }

            // 코드 블록
            let languageRange = match.range(at: 1)
            let codeRange = match.range(at: 2)
            let language = nsText.substring(with: languageRange)
            let code = nsText.substring(with: codeRange)
            blocks.append(.code(code, language.isEmpty ? nil : language))

            lastIndex = match.range.location + match.range.length
        }

        // 마지막 텍스트
        if lastIndex < nsText.length {
            let textContent = nsText.substring(from: lastIndex).trimmingCharacters(in: .whitespacesAndNewlines)
            if !textContent.isEmpty {
                blocks.append(.text(textContent))
            }
        }

        return blocks.isEmpty ? [.text(text)] : blocks
    }

    private enum ContentBlock {
        case text(String)
        case code(String, String?)
    }
}

// MARK: - ToolInputContent

/// 도구 입력 콘텐츠
struct ToolInputContent: View {
    let input: [String: AnyCodableValue]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(input.keys.sorted()), id: \.self) { key in
                HStack(alignment: .top, spacing: 4) {
                    Text("\(key):")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    Text(formatValue(input[key]))
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                }
            }
        }
    }

    private func formatValue(_ value: AnyCodableValue?) -> String {
        guard let value = value else { return "nil" }
        switch value {
        case .string(let s): return s
        case .int(let i): return String(i)
        case .double(let d): return String(d)
        case .bool(let b): return String(b)
        case .array(let arr): return "[\(arr.count) items]"
        case .dictionary(let dict): return "{\(dict.count) keys}"
        case .null: return "null"
        }
    }
}

// MARK: - ToolOutputContent

/// 도구 출력 콘텐츠
struct ToolOutputContent: View {
    let output: String
    var onViewDiff: ((UnifiedDiff) -> Void)?

    private let diffParser = DiffParser()

    /// Diff가 포함되어 있는지 확인
    private var containsDiff: Bool {
        diffParser.containsDiff(output)
    }

    /// 파싱된 Diff (diff가 포함된 경우에만)
    private var parsedDiff: UnifiedDiff? {
        guard containsDiff else { return nil }
        return try? diffParser.parse(output, isStaged: nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(output)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(containsDiff ? 3 : 5)
                .textSelection(.enabled)

            if containsDiff, let diff = parsedDiff {
                Button {
                    onViewDiff?(diff)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("Diff 뷰어에서 보기")
                    }
                    .font(.caption)
                }
                .buttonStyle(.link)
                .accessibilityIdentifier("viewDiffButton")
            }
        }
    }
}

// MARK: - TypingIndicator

/// 타이핑 인디케이터
/// TimelineView를 사용하여 실제로 애니메이션이 동작하도록 구현
struct TypingIndicator: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.4)) { timeline in
            let phase = Int(timeline.date.timeIntervalSinceReferenceDate * 2.5) % 3
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.secondary.opacity(opacity(for: index, phase: phase)))
                        .frame(width: 6, height: 6)
                        .animation(.easeInOut(duration: 0.2), value: phase)
                }
            }
        }
        .accessibilityIdentifier("typingIndicator")
        .accessibilityLabel("Assistant is typing")
        .accessibilityAddTraits(.updatesFrequently)
    }

    private func opacity(for index: Int, phase: Int) -> Double {
        let adjustedPhase = (phase + index) % 3
        switch adjustedPhase {
        case 0: return 1.0
        case 1: return 0.6
        default: return 0.3
        }
    }
}

// MARK: - RelativeTimestampFormatter

/// 상대 시간 포맷터 (스레드 안전)
final class RelativeTimestampFormatter: @unchecked Sendable {
    static let shared = RelativeTimestampFormatter()

    private let lock = NSLock()
    private let relativeFormatter: RelativeDateTimeFormatter
    private let timeFormatter: DateFormatter
    private let dateTimeFormatter: DateFormatter

    private init() {
        relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .short

        timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        dateTimeFormatter = DateFormatter()
        dateTimeFormatter.dateFormat = "MMM d, HH:mm"
    }

    func string(from date: Date) -> String {
        lock.lock()
        defer { lock.unlock() }

        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        } else {
            let calendar = Calendar.current
            if calendar.isDateInToday(date) {
                return "Today \(timeFormatter.string(from: date))"
            } else if calendar.isDateInYesterday(date) {
                return "Yesterday \(timeFormatter.string(from: date))"
            } else {
                return dateTimeFormatter.string(from: date)
            }
        }
    }
}

// MARK: - Preview

#Preview("User Message") {
    VStack {
        MessageBubble(message: ChatMessageItem(
            id: "1",
            type: .user,
            content: .text("Hello, can you help me with SwiftUI?"),
            timestamp: Date()
        ))

        MessageBubble(message: ChatMessageItem(
            id: "2",
            type: .assistant,
            content: .text("Of course! What would you like to know?"),
            timestamp: Date()
        ))
    }
    .padding()
}

#Preview("Code Block") {
    MessageBubble(message: ChatMessageItem(
        id: "3",
        type: .assistant,
        content: .text("""
            Here's an example:

            ```swift
            struct ContentView: View {
                var body: some View {
                    Text("Hello, World!")
                }
            }
            ```

            This is a basic SwiftUI view.
            """),
        timestamp: Date()
    ))
    .padding()
}

#Preview("Streaming") {
    MessageBubble(message: ChatMessageItem(
        id: "4",
        type: .assistant,
        content: .streaming("I'm thinking about this..."),
        timestamp: Date()
    ))
    .padding()
}
