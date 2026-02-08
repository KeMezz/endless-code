//
//  MarkdownContentView.swift
//  EndlessCode
//
//  마크다운 텍스트를 SwiftUI 뷰로 렌더링
//

import SwiftUI

// MARK: - MarkdownContentView

/// 마크다운 콘텐츠 뷰
struct MarkdownContentView: View {
    let text: String
    var onCopyCode: ((String) -> Void)?
    var onViewDiff: ((UnifiedDiff) -> Void)?

    // 파싱 결과를 init에서 미리 계산 (성능 최적화)
    private let nodes: [MarkdownNode]

    init(
        text: String,
        onCopyCode: ((String) -> Void)? = nil,
        onViewDiff: ((UnifiedDiff) -> Void)? = nil
    ) {
        self.text = text
        self.onCopyCode = onCopyCode
        self.onViewDiff = onViewDiff

        let parser = MarkdownParser()
        self.nodes = parser.parse(text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(nodes.enumerated()), id: \.offset) { _, node in
                nodeView(for: node)
            }
        }
        .accessibilityIdentifier("markdownContent")
    }

    // MARK: - Node Rendering

    @ViewBuilder
    private func nodeView(for node: MarkdownNode) -> some View {
        switch node {
        case .heading(let level, let content):
            headingView(level: level, content: content)

        case .paragraph(let inlineNodes):
            paragraphView(content: inlineNodes)

        case .codeBlock(let code, let language):
            CodeBlockView(
                code: code,
                language: language,
                onCopy: { onCopyCode?(code) }
            )
            .accessibilityIdentifier("markdownCodeBlock")

        case .listItem(let content, let isOrdered):
            listItemView(content: content, isOrdered: isOrdered)

        case .text(let text):
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
    }

    @ViewBuilder
    private func headingView(level: Int, content: [InlineNode]) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            inlineView(for: content)
        }
        .font(headingFont(for: level))
        .fontWeight(.bold)
        .foregroundStyle(.primary)
        .textSelection(.enabled)
        .padding(.top, level == 1 ? 8 : 4)
        .padding(.bottom, 4)
        .accessibilityIdentifier("markdownHeading-\(level)")
    }

    @ViewBuilder
    private func paragraphView(content: [InlineNode]) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            inlineView(for: content)
        }
        .font(.body)
        .foregroundStyle(.primary)
        .textSelection(.enabled)
    }

    @ViewBuilder
    private func listItemView(content: [InlineNode], isOrdered: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(isOrdered ? "1." : "•")
                .font(.body)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                inlineView(for: content)
            }
            .font(.body)
            .foregroundStyle(.primary)
            .textSelection(.enabled)
        }
    }

    @ViewBuilder
    private func inlineView(for nodes: [InlineNode]) -> some View {
        ForEach(Array(nodes.enumerated()), id: \.offset) { _, node in
            switch node {
            case .text(let text):
                Text(text)

            case .bold(let text):
                Text(text)
                    .fontWeight(.bold)

            case .italic(let text):
                Text(text)
                    .italic()

            case .code(let code):
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

            case .link(let linkText, let url):
                if let validURL = URL(string: url) {
                    Link(linkText, destination: validURL)
                        .foregroundStyle(.blue)
                        .accessibilityIdentifier("markdownLink")
                } else {
                    Text(linkText)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("markdownLink")
                }
            }
        }
    }

    // MARK: - Helpers

    private func headingFont(for level: Int) -> Font {
        switch level {
        case 1: return .title
        case 2: return .title2
        case 3: return .title3
        case 4: return .headline
        case 5: return .subheadline
        default: return .body
        }
    }
}

// MARK: - Preview

#Preview("Basic Markdown") {
    MarkdownContentView(text: """
        # Heading 1

        This is a **bold** text and this is *italic* text.

        Here's some `inline code` in a sentence.

        ## Heading 2

        - List item 1
        - List item 2
        - List item 3

        ### Heading 3

        1. Ordered item 1
        2. Ordered item 2

        Check out [Swift.org](https://swift.org) for more info.
        """)
    .padding()
    .frame(width: 500)
}

#Preview("Code Block") {
    MarkdownContentView(text: """
        Here's a Swift example:

        ```swift
        struct ContentView: View {
            var body: some View {
                Text("Hello, World!")
            }
        }
        ```

        And here's some **important** information with `code`.
        """)
    .padding()
    .frame(width: 500)
}

#Preview("Complex Markdown") {
    MarkdownContentView(text: """
        # SwiftUI Guide

        SwiftUI is **Apple's** modern framework for building UIs.

        ## Key Features

        - Declarative syntax
        - **Cross-platform** support
        - Built-in *dark mode*
        - Real-time previews

        ### Example Code

        Here's a simple view:

        ```swift
        struct MyView: View {
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
        ```

        You can learn more at [Apple's documentation](https://developer.apple.com/documentation/swiftui).

        ## Advanced Topics

        1. State management with `@State` and `@Binding`
        2. Navigation and routing
        3. Custom modifiers

        Use the `View` protocol to create custom components.
        """)
    .padding()
    .frame(width: 600)
}
