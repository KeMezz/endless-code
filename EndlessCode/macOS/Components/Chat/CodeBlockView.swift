//
//  CodeBlockView.swift
//  EndlessCode
//
//  코드 블록 표시 컴포넌트
//  - 언어별 신택스 하이라이팅
//  - 대용량 코드 최적화 (LazyVStack)
//  - 라인 번호 및 복사 기능
//

import SwiftUI

// MARK: - Constants

private enum CodeBlockConstants {
    /// 가상화 적용 기준 라인 수
    static let virtualizationThreshold = 100

    /// 최대 높이 (스크롤 필요 시)
    static let maxHeight: CGFloat = 400

    /// 라인 번호 최소 너비
    static let lineNumberMinWidth: CGFloat = 20

    /// 코드 라인 높이 (monospaced body 기준)
    static let lineHeight: CGFloat = 20

    /// 코드 영역 상하 패딩 합계
    static let verticalPadding: CGFloat = 16
}

// MARK: - CodeBlockView

/// 코드 블록 뷰
struct CodeBlockView: View {
    let code: String
    let language: String?
    let onCopy: (() -> Void)?

    @State private var isCopied = false
    @State private var isHovering = false
    @State private var resetCopiedTask: Task<Void, Never>?

    // 캐싱된 라인 및 하이라이팅 결과
    private let lines: [String]
    private let highlightedLines: [AttributedString]

    init(code: String, language: String? = nil, onCopy: (() -> Void)? = nil) {
        self.code = code
        self.language = language
        self.onCopy = onCopy

        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        self.lines = trimmed.components(separatedBy: "\n")

        // 하이라이팅 결과를 init에서 미리 계산 (성능 최적화)
        let highlighter = SyntaxHighlighter.forLanguage(language)
        self.highlightedLines = self.lines.map { highlighter.highlightLine($0) }
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
        let useVirtualization = lines.count >= CodeBlockConstants.virtualizationThreshold

        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                if useVirtualization {
                    lazyCodeRows
                        .frame(minWidth: geometry.size.width, alignment: .leading)
                } else {
                    regularCodeRows
                        .frame(minWidth: geometry.size.width, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: calculateContentHeight())
    }

    /// 코드 콘텐츠 높이 계산
    private func calculateContentHeight() -> CGFloat {
        let calculatedHeight = CGFloat(lines.count) * CodeBlockConstants.lineHeight
            + CodeBlockConstants.verticalPadding

        if lines.count > 20 {
            return min(calculatedHeight, CodeBlockConstants.maxHeight)
        }
        return calculatedHeight
    }

    /// LazyVStack 기반 코드 행 (대용량 최적화)
    private var lazyCodeRows: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(0..<lines.count, id: \.self) { index in
                codeRow(index: index)
            }
        }
        .padding(.vertical, 8)
    }

    /// VStack 기반 코드 행 (일반)
    private var regularCodeRows: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<lines.count, id: \.self) { index in
                codeRow(index: index)
            }
        }
        .padding(.vertical, 8)
    }

    /// 단일 코드 행 (라인 번호 + 코드)
    @ViewBuilder
    private func codeRow(index: Int) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // 라인 번호
            Text("\(index + 1)")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: lineNumberWidth, alignment: .trailing)
                .padding(.leading, 8)
                .padding(.trailing, 8)
                .padding(.vertical, 2)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))

            // 코드
            Text(highlightedLines[index])
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.leading, 8)
                .padding(.vertical, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Computed Properties

    /// 라인 번호 표시 너비 (자릿수에 따라 동적 조절)
    private var lineNumberWidth: CGFloat {
        let digits = String(lines.count).count
        return max(CodeBlockConstants.lineNumberMinWidth, CGFloat(digits * 8 + 4))
    }

    // MARK: - Helpers

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

#Preview("JavaScript Code") {
    CodeBlockView(
        code: """
        async function fetchData(url) {
            const response = await fetch(url);
            const data = await response.json();
            console.log("Data:", data);
            return data;
        }

        // Call the function
        fetchData("https://api.example.com/data")
            .then(result => console.log(result))
            .catch(error => console.error(error));
        """,
        language: "javascript"
    )
    .frame(width: 500)
    .padding()
}

#Preview("Python Code") {
    CodeBlockView(
        code: """
        def calculate_fibonacci(n: int) -> list[int]:
            '''Calculate Fibonacci sequence up to n terms.'''
            if n <= 0:
                return []
            elif n == 1:
                return [0]

            fib = [0, 1]
            for i in range(2, n):
                fib.append(fib[i-1] + fib[i-2])
            return fib

        # Example usage
        result = calculate_fibonacci(10)
        print(f"Fibonacci: {result}")
        """,
        language: "python"
    )
    .frame(width: 500)
    .padding()
}

#Preview("Large Code (Virtualized)") {
    let largeCode = (1...200).map { "let line\($0) = \"This is line \\($0)\"  // Comment for line \\($0)" }.joined(separator: "\n")

    return CodeBlockView(
        code: largeCode,
        language: "swift"
    )
    .frame(width: 600, height: 400)
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
