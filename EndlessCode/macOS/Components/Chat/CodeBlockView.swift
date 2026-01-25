//
//  CodeBlockView.swift
//  EndlessCode
//
//  코드 블록 표시 컴포넌트
//

import SwiftUI

// MARK: - CodeBlockView

/// 코드 블록 뷰
struct CodeBlockView: View {
    let code: String
    let language: String?
    let onCopy: (() -> Void)?

    @State private var isCopied = false
    @State private var isHovering = false
    @State private var resetCopiedTask: Task<Void, Never>?

    init(code: String, language: String? = nil, onCopy: (() -> Void)? = nil) {
        self.code = code
        self.language = language
        self.onCopy = onCopy
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()
                .background(Color.secondary.opacity(0.2))

            codeContent
        }
        .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .onDisappear {
            resetCopiedTask?.cancel()
        }
        .accessibilityIdentifier("codeBlock")
    }

    // MARK: - Subviews

    @ViewBuilder
    private var header: some View {
        HStack {
            if let language = language, !language.isEmpty {
                Text(language)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            } else {
                Text("Code")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            copyButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }

    @ViewBuilder
    private var copyButton: some View {
        Button {
            copyToClipboard()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(.caption)
                Text(isCopied ? "Copied!" : "Copy")
                    .font(.caption)
            }
            .foregroundStyle(isCopied ? .green : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(isHovering ? 0.15 : 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .opacity(isHovering || isCopied ? 1 : 0.7)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .animation(.easeInOut(duration: 0.15), value: isCopied)
        .accessibilityIdentifier("copyCodeButton")
        .accessibilityLabel(isCopied ? "Code copied" : "Copy code to clipboard")
    }

    @ViewBuilder
    private var codeContent: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: 0) {
                lineNumbers

                Divider()
                    .frame(height: calculateHeight())
                    .background(Color.secondary.opacity(0.2))

                codeText
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var lineNumbers: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, _ in
                Text("\(index + 1)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .frame(minWidth: 30, alignment: .trailing)
                    .padding(.vertical, 2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
    }

    @ViewBuilder
    private var codeText: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(highlightedLine(line))
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(.vertical, 2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Computed Properties

    private var lines: [String] {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.components(separatedBy: "\n")
    }

    // MARK: - Helpers

    private func calculateHeight() -> CGFloat {
        CGFloat(lines.count) * 24 + 16
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)

        isCopied = true
        onCopy?()

        // 기존 Task 취소 후 새 Task 생성
        resetCopiedTask?.cancel()
        resetCopiedTask = Task {
            try? await Task.sleep(for: .seconds(2))
            // Task가 취소되지 않은 경우에만 상태 업데이트
            if !Task.isCancelled {
                isCopied = false
            }
        }
    }

    // MARK: - Syntax Highlighting

    /// 키워드 하이라이팅용 정규표현식 (캐싱, 단어 경계 체크)
    /// - TODO(Section-3.2): Tree-sitter 기반 신택스 하이라이팅으로 교체 예정
    private static let keywordRegex: NSRegularExpression? = {
        let keywords = [
            "struct", "class", "enum", "protocol", "extension",
            "func", "var", "let", "if", "else", "guard", "switch",
            "case", "for", "while", "return", "import", "private",
            "public", "internal", "fileprivate", "static", "final",
            "override", "async", "await", "throws", "try", "catch", "some"
        ]
        let pattern = "\\b(\(keywords.joined(separator: "|")))\\b"
        return try? NSRegularExpression(pattern: pattern)
    }()

    /// @ 프리픽스 키워드용 정규표현식
    private static let attributeRegex: NSRegularExpression? = {
        let attributes = ["@State", "@Binding", "@Observable", "@MainActor", "@Published", "@Environment"]
        let pattern = "(\(attributes.joined(separator: "|")))\\b"
        return try? NSRegularExpression(pattern: pattern)
    }()

    /// 기본 신택스 하이라이팅 (Tree-sitter 통합 전까지 임시 사용)
    /// 정규표현식 기반으로 단어 경계를 체크하여 부분 매칭 방지
    /// - TODO(Section-3.2): Tree-sitter 기반 신택스 하이라이팅으로 교체 예정
    private func highlightedLine(_ line: String) -> AttributedString {
        var attributedString = AttributedString(line)
        let nsLine = line as NSString
        let fullRange = NSRange(location: 0, length: nsLine.length)

        // 키워드 하이라이팅 (단어 경계 체크)
        if let regex = Self.keywordRegex {
            let matches = regex.matches(in: line, range: fullRange)
            for match in matches {
                if let range = Range(match.range, in: line),
                   let attrRange = attributedString.range(of: String(line[range])) {
                    attributedString[attrRange].foregroundColor = .purple
                }
            }
        }

        // @ 프리픽스 속성 하이라이팅
        if let regex = Self.attributeRegex {
            let matches = regex.matches(in: line, range: fullRange)
            for match in matches {
                if let range = Range(match.range, in: line),
                   let attrRange = attributedString.range(of: String(line[range])) {
                    attributedString[attrRange].foregroundColor = .purple
                }
            }
        }

        // 문자열 하이라이팅
        highlightStrings(&attributedString)

        // 주석 하이라이팅
        highlightComments(&attributedString)

        return attributedString
    }

    private func highlightStrings(_ attributedString: inout AttributedString) {
        let string = String(attributedString.characters)
        var inString = false
        var stringStart: String.Index?

        for (index, char) in string.enumerated() {
            let strIndex = string.index(string.startIndex, offsetBy: index)
            if char == "\"" {
                if inString {
                    // 문자열 끝
                    if let start = stringStart {
                        let range = start...strIndex
                        if let attrRange = Range(range, in: attributedString) {
                            attributedString[attrRange].foregroundColor = .red
                        }
                    }
                    inString = false
                    stringStart = nil
                } else {
                    // 문자열 시작
                    inString = true
                    stringStart = strIndex
                }
            }
        }
    }

    private func highlightComments(_ attributedString: inout AttributedString) {
        let string = String(attributedString.characters)
        if let commentIndex = string.range(of: "//") {
            if let attrRange = Range(commentIndex.lowerBound..<string.endIndex, in: attributedString) {
                attributedString[attrRange].foregroundColor = .green
            }
        }
    }
}

// MARK: - Preview

#Preview("Swift Code") {
    CodeBlockView(
        code: """
        struct ContentView: View {
            @State private var count = 0

            var body: some View {
                VStack {
                    Text("Count: \\(count)")
                    Button("Increment") {
                        count += 1
                    }
                }
            }
        }
        """,
        language: "swift"
    )
    .frame(width: 500)
    .padding()
}

#Preview("No Language") {
    CodeBlockView(
        code: """
        npm install
        npm run dev
        """,
        language: nil
    )
    .frame(width: 400)
    .padding()
}
