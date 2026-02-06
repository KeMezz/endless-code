//
//  MarkdownParser.swift
//  EndlessCode
//
//  마크다운 텍스트를 구조화된 노드로 파싱
//

import Foundation

// MARK: - MarkdownNode

/// 마크다운 노드 타입
enum MarkdownNode: Equatable, Sendable {
    case heading(level: Int, content: [InlineNode])
    case paragraph([InlineNode])
    case codeBlock(code: String, language: String?)
    case listItem(content: [InlineNode], isOrdered: Bool)
    case text(String)
}

/// 인라인 마크다운 노드
enum InlineNode: Equatable, Sendable {
    case text(String)
    case bold(String)
    case italic(String)
    case code(String)
    case link(text: String, url: String)
}

// MARK: - MarkdownParser

/// 마크다운 파서
struct MarkdownParser: Sendable {
    // MARK: - Regular Expressions

    /// 코드 블록 정규표현식
    private static let codeBlockRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "```(\\w*)\\n([\\s\\S]*?)```")
    }()

    /// 헤딩 정규표현식
    private static let headingRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "^(#{1,6})\\s+(.+)$")
    }()

    /// 리스트 아이템 정규표현식 (-, *, 1., 2. 등)
    private static let listItemRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "^([-*]|\\d+\\.)\\s+(.+)$")
    }()

    /// 볼드 정규표현식 (**text**)
    private static let boldRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*")
    }()

    /// 이탤릭 정규표현식 (*text* 또는 _text_)
    private static let italicRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)|_(.+?)_")
    }()

    /// 인라인 코드 정규표현식 (`code`)
    private static let inlineCodeRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "`([^`]+)`")
    }()

    /// 링크 정규표현식 ([text](url))
    private static let linkRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^\\)]+)\\)")
    }()

    // MARK: - Public Methods

    /// 마크다운 텍스트를 노드 배열로 파싱
    func parse(_ markdown: String) -> [MarkdownNode] {
        var nodes: [MarkdownNode] = []

        // 먼저 코드 블록을 추출하고 나머지 텍스트를 처리
        let blocks = extractCodeBlocks(from: markdown)

        for block in blocks {
            switch block {
            case .code(let code, let language):
                nodes.append(.codeBlock(code: code, language: language))
            case .text(let text):
                // 텍스트 블록을 라인별로 파싱
                let lineNodes = parseTextBlock(text)
                nodes.append(contentsOf: lineNodes)
            }
        }

        return nodes.isEmpty ? [.text(markdown)] : nodes
    }

    // MARK: - Private Methods

    /// 코드 블록을 추출하고 나머지 텍스트와 분리
    private func extractCodeBlocks(from text: String) -> [Block] {
        var blocks: [Block] = []

        guard let regex = Self.codeBlockRegex else {
            return [.text(text)]
        }

        let nsText = text as NSString
        var lastIndex = 0

        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        for match in matches {
            // 코드 블록 이전 텍스트
            if match.range.location > lastIndex {
                let textRange = NSRange(location: lastIndex, length: match.range.location - lastIndex)
                let textContent = nsText.substring(with: textRange)
                if !textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    blocks.append(.text(textContent))
                }
            }

            // 코드 블록
            let languageRange = match.range(at: 1)
            let codeRange = match.range(at: 2)
            let language = nsText.substring(with: languageRange)
            var code = nsText.substring(with: codeRange)
            // Remove trailing newline before closing ```
            if code.hasSuffix("\n") {
                code = String(code.dropLast())
            }
            blocks.append(.code(code, language.isEmpty ? nil : language))

            lastIndex = match.range.location + match.range.length
        }

        // 마지막 텍스트
        if lastIndex < nsText.length {
            let textContent = nsText.substring(from: lastIndex)
            if !textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                blocks.append(.text(textContent))
            }
        }

        return blocks.isEmpty ? [.text(text)] : blocks
    }

    /// 텍스트 블록을 라인별로 파싱
    private func parseTextBlock(_ text: String) -> [MarkdownNode] {
        var nodes: [MarkdownNode] = []
        let lines = text.components(separatedBy: "\n")

        var paragraphLines: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // 빈 줄은 이전 paragraph 종료
            if trimmed.isEmpty {
                if !paragraphLines.isEmpty {
                    let paragraphText = paragraphLines.joined(separator: " ")
                    nodes.append(.paragraph(parseInline(paragraphText)))
                    paragraphLines.removeAll()
                }
                continue
            }

            // 헤딩 체크
            if let heading = parseHeading(trimmed) {
                // 이전 paragraph 저장
                if !paragraphLines.isEmpty {
                    let paragraphText = paragraphLines.joined(separator: " ")
                    nodes.append(.paragraph(parseInline(paragraphText)))
                    paragraphLines.removeAll()
                }
                nodes.append(heading)
                continue
            }

            // 리스트 아이템 체크
            if let listItem = parseListItem(trimmed) {
                // 이전 paragraph 저장
                if !paragraphLines.isEmpty {
                    let paragraphText = paragraphLines.joined(separator: " ")
                    nodes.append(.paragraph(parseInline(paragraphText)))
                    paragraphLines.removeAll()
                }
                nodes.append(listItem)
                continue
            }

            // 일반 텍스트는 paragraph에 추가
            paragraphLines.append(trimmed)
        }

        // 마지막 paragraph 저장
        if !paragraphLines.isEmpty {
            let paragraphText = paragraphLines.joined(separator: " ")
            nodes.append(.paragraph(parseInline(paragraphText)))
        }

        return nodes
    }

    /// 헤딩 파싱
    private func parseHeading(_ line: String) -> MarkdownNode? {
        guard let regex = Self.headingRegex else { return nil }

        let nsLine = line as NSString
        guard let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)) else {
            return nil
        }

        let hashMarks = nsLine.substring(with: match.range(at: 1))
        let content = nsLine.substring(with: match.range(at: 2))

        return .heading(level: hashMarks.count, content: parseInline(content))
    }

    /// 리스트 아이템 파싱
    private func parseListItem(_ line: String) -> MarkdownNode? {
        guard let regex = Self.listItemRegex else { return nil }

        let nsLine = line as NSString
        guard let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)) else {
            return nil
        }

        let marker = nsLine.substring(with: match.range(at: 1))
        let content = nsLine.substring(with: match.range(at: 2))
        let isOrdered = marker.contains(where: { $0.isNumber })

        return .listItem(content: parseInline(content), isOrdered: isOrdered)
    }

    /// 인라인 요소 파싱 (볼드, 이탤릭, 코드, 링크)
    private func parseInline(_ text: String) -> [InlineNode] {
        var nodes: [InlineNode] = []

        // 우선순위: 링크 > 볼드 > 이탤릭 > 인라인 코드 > 일반 텍스트
        let patterns: [(regex: NSRegularExpression?, handler: (NSTextCheckingResult, NSString) -> InlineNode?)] = [
            (Self.linkRegex, { match, nsText in
                let linkText = nsText.substring(with: match.range(at: 1))
                let url = nsText.substring(with: match.range(at: 2))
                return .link(text: linkText, url: url)
            }),
            (Self.boldRegex, { match, nsText in
                let content = nsText.substring(with: match.range(at: 1))
                return .bold(content)
            }),
            (Self.italicRegex, { match, nsText in
                // italic regex는 두 개의 캡처 그룹을 가짐 (별표 또는 언더스코어)
                let content1 = match.range(at: 1).location != NSNotFound
                    ? nsText.substring(with: match.range(at: 1))
                    : nil
                let content2 = match.range(at: 2).location != NSNotFound
                    ? nsText.substring(with: match.range(at: 2))
                    : nil
                let content = content1 ?? content2 ?? ""
                return .italic(content)
            }),
            (Self.inlineCodeRegex, { match, nsText in
                let code = nsText.substring(with: match.range(at: 1))
                return .code(code)
            })
        ]

        // 모든 패턴 매칭을 찾아서 위치별로 정렬
        struct Match {
            let range: NSRange
            let node: InlineNode
        }

        var allMatches: [Match] = []

        for (regex, handler) in patterns {
            guard let regex = regex else { continue }
            let nsText = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

            for match in matches {
                if let node = handler(match, nsText) {
                    allMatches.append(Match(range: match.range, node: node))
                }
            }
        }

        // 위치별로 정렬하고 중복 제거 (같은 위치면 먼저 매칭된 것 우선)
        allMatches.sort { $0.range.location < $1.range.location }
        var filteredMatches: [Match] = []
        var lastEnd = 0

        for match in allMatches {
            if match.range.location >= lastEnd {
                filteredMatches.append(match)
                lastEnd = match.range.location + match.range.length
            }
        }

        // 텍스트와 매칭된 노드를 순서대로 조합
        let nsText = text as NSString
        var currentIndex = 0

        for match in filteredMatches {
            // 매칭 이전 텍스트
            if match.range.location > currentIndex {
                let textRange = NSRange(location: currentIndex, length: match.range.location - currentIndex)
                let plainText = nsText.substring(with: textRange)
                if !plainText.isEmpty {
                    nodes.append(.text(plainText))
                }
            }

            // 매칭된 노드
            nodes.append(match.node)
            currentIndex = match.range.location + match.range.length
        }

        // 마지막 텍스트
        if currentIndex < nsText.length {
            let plainText = nsText.substring(from: currentIndex)
            if !plainText.isEmpty {
                nodes.append(.text(plainText))
            }
        }

        return nodes.isEmpty ? [.text(text)] : nodes
    }

    // MARK: - Helper Types

    private enum Block {
        case text(String)
        case code(String, String?)
    }
}
