//
//  DiffLineView.swift
//  EndlessCode
//
//  Diff 라인 표시 컴포넌트
//  - 추가/삭제/컨텍스트 라인 구분
//  - 이중 라인 번호 표시
//  - 신택스 하이라이팅 지원
//

import SwiftUI

// MARK: - Constants

enum DiffViewConstants {
    /// 라인 번호 너비
    static let lineNumberWidth: CGFloat = 40

    /// 라인 번호 패딩
    static let lineNumberPadding: CGFloat = 4

    /// 라인 높이
    static let lineHeight: CGFloat = 20

    /// 최대 높이 (스크롤 필요 시)
    static let maxHunkHeight: CGFloat = 400

    /// 가상화 적용 기준 라인 수
    static let virtualizationThreshold = 100

    /// Hunk 헤더 높이
    static let hunkHeaderHeight: CGFloat = 32
}

// MARK: - DiffLineColors

/// Diff 라인 타입별 색상
struct DiffLineColors {
    static let addedBackground = Color.green.opacity(0.15)
    static let deletedBackground = Color.red.opacity(0.15)
    static let contextBackground = Color.clear

    static let addedLineNumber = Color.green.opacity(0.3)
    static let deletedLineNumber = Color.red.opacity(0.3)
    static let contextLineNumber = Color(nsColor: .controlBackgroundColor).opacity(0.5)

    static let addedText = Color.green.opacity(0.8)
    static let deletedText = Color.red.opacity(0.8)
}

// MARK: - DiffLineView

/// 단일 Diff 라인 뷰
struct DiffLineView: View {
    let line: DiffLine
    let fileExtension: String?
    let showSyntaxHighlighting: Bool

    // 캐싱된 하이라이팅 결과
    private let highlightedContent: AttributedString

    // 언어별 SyntaxHighlighter 캐시 (정규표현식 컴파일 비용 절감)
    private static let highlighterCache: NSCache<NSString, HighlighterWrapper> = {
        let cache = NSCache<NSString, HighlighterWrapper>()
        cache.countLimit = 30
        return cache
    }()

    private static func cachedHighlighter(for ext: String) -> SyntaxHighlighter {
        let key = ext as NSString
        if let wrapper = highlighterCache.object(forKey: key) {
            return wrapper.highlighter
        }
        let language = SupportedLanguage.from(extension: ext)
        let highlighter = SyntaxHighlighter(language: language)
        highlighterCache.setObject(HighlighterWrapper(highlighter), forKey: key)
        return highlighter
    }

    init(line: DiffLine, fileExtension: String? = nil, showSyntaxHighlighting: Bool = true) {
        self.line = line
        self.fileExtension = fileExtension
        self.showSyntaxHighlighting = showSyntaxHighlighting

        // 신택스 하이라이팅 적용
        if showSyntaxHighlighting, let ext = fileExtension {
            let highlighter = Self.cachedHighlighter(for: ext)
            self.highlightedContent = highlighter.highlightLine(line.content)
        } else {
            self.highlightedContent = AttributedString(line.content)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // 원본 라인 번호
            lineNumberCell(line.oldLineNumber, isOld: true)

            // 새 파일 라인 번호
            lineNumberCell(line.newLineNumber, isOld: false)

            // Diff 기호
            prefixCell

            // 코드 내용
            contentCell
        }
        .frame(height: DiffViewConstants.lineHeight)
        .background(backgroundColor)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func lineNumberCell(_ number: Int?, isOld: Bool) -> some View {
        ZStack {
            lineNumberBackground

            if let num = number {
                Text("\(num)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: DiffViewConstants.lineNumberWidth)
    }

    private var prefixCell: some View {
        Text(line.type.prefix)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(prefixColor)
            .frame(width: 16)
            .padding(.horizontal, 2)
    }

    private var contentCell: some View {
        Text(highlightedContent)
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.leading, 4)
            .padding(.trailing, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Computed Properties

    private var backgroundColor: Color {
        switch line.type {
        case .added:
            return DiffLineColors.addedBackground
        case .deleted:
            return DiffLineColors.deletedBackground
        case .context, .header, .noNewline:
            return DiffLineColors.contextBackground
        }
    }

    private var lineNumberBackground: Color {
        switch line.type {
        case .added:
            return DiffLineColors.addedLineNumber
        case .deleted:
            return DiffLineColors.deletedLineNumber
        case .context, .header, .noNewline:
            return DiffLineColors.contextLineNumber
        }
    }

    private var prefixColor: Color {
        switch line.type {
        case .added:
            return DiffLineColors.addedText
        case .deleted:
            return DiffLineColors.deletedText
        case .context, .header, .noNewline:
            return .secondary
        }
    }
}

// MARK: - DiffHunkHeaderView

/// Hunk 헤더 뷰
struct DiffHunkHeaderView: View {
    let hunk: DiffHunk
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 12)

                Text(hunk.header)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)

                if let context = hunk.contextText {
                    Text(context)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer()

                // 변경 통계
                statisticsView
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(height: DiffViewConstants.hunkHeaderHeight)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("hunkHeader-\(hunk.id)")
    }

    private var statisticsView: some View {
        HStack(spacing: 4) {
            if hunk.additions > 0 {
                Text("+\(hunk.additions)")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            if hunk.deletions > 0 {
                Text("-\(hunk.deletions)")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

// MARK: - DiffHunkView

/// 단일 Hunk 뷰
struct DiffHunkView: View {
    let hunk: DiffHunk
    let fileExtension: String?
    let showSyntaxHighlighting: Bool

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DiffHunkHeaderView(
                hunk: hunk,
                isExpanded: isExpanded,
                onToggle: { isExpanded.toggle() }
            )

            if isExpanded {
                hunkContent
            }
        }
        .accessibilityIdentifier("diffHunk-\(hunk.id)")
    }

    @ViewBuilder
    private var hunkContent: some View {
        let useVirtualization = hunk.lines.count >= DiffViewConstants.virtualizationThreshold

        if useVirtualization {
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(hunk.lines) { line in
                        DiffLineView(
                            line: line,
                            fileExtension: fileExtension,
                            showSyntaxHighlighting: showSyntaxHighlighting
                        )
                    }
                }
            }
            .frame(maxHeight: DiffViewConstants.maxHunkHeight)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(hunk.lines) { line in
                    DiffLineView(
                        line: line,
                        fileExtension: fileExtension,
                        showSyntaxHighlighting: showSyntaxHighlighting
                    )
                }
            }
        }
    }
}

// MARK: - HighlighterWrapper

/// NSCache에 저장하기 위한 래퍼 (NSCache는 class만 값으로 허용)
private final class HighlighterWrapper: @unchecked Sendable {
    let highlighter: SyntaxHighlighter
    init(_ highlighter: SyntaxHighlighter) {
        self.highlighter = highlighter
    }
}

// MARK: - Preview

#Preview("Diff Line - Added") {
    DiffLineView(
        line: DiffLine(
            type: .added,
            content: "let newVariable = \"Hello, World!\"",
            oldLineNumber: nil,
            newLineNumber: 10
        ),
        fileExtension: "swift"
    )
    .frame(width: 600)
}

#Preview("Diff Line - Deleted") {
    DiffLineView(
        line: DiffLine(
            type: .deleted,
            content: "let oldVariable = \"Goodbye!\"",
            oldLineNumber: 5,
            newLineNumber: nil
        ),
        fileExtension: "swift"
    )
    .frame(width: 600)
}

#Preview("Diff Line - Context") {
    DiffLineView(
        line: DiffLine(
            type: .context,
            content: "import Foundation",
            oldLineNumber: 1,
            newLineNumber: 1
        ),
        fileExtension: "swift"
    )
    .frame(width: 600)
}

#Preview("Hunk Header") {
    DiffHunkHeaderView(
        hunk: DiffHunk(
            header: "@@ -10,5 +10,7 @@",
            oldStart: 10,
            oldCount: 5,
            newStart: 10,
            newCount: 7,
            contextText: "func myFunction()",
            lines: [
                DiffLine(type: .context, content: "line 1", oldLineNumber: 10, newLineNumber: 10),
                DiffLine(type: .deleted, content: "line 2", oldLineNumber: 11, newLineNumber: nil),
                DiffLine(type: .added, content: "line 3", oldLineNumber: nil, newLineNumber: 11),
                DiffLine(type: .added, content: "line 4", oldLineNumber: nil, newLineNumber: 12),
            ]
        ),
        isExpanded: true,
        onToggle: {}
    )
    .frame(width: 600)
}
