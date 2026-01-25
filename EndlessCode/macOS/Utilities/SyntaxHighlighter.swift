//
//  SyntaxHighlighter.swift
//  EndlessCode
//
//  정규표현식 기반 신택스 하이라이팅 서비스
//  SwiftUI Color를 사용하는 플랫폼 특화 구현
//

import SwiftUI

// MARK: - Token Colors

/// 토큰 타입별 색상 (다크 테마 기준)
public struct SyntaxTokenColors: Sendable {
    public let keyword: Color
    public let type: Color
    public let string: Color
    public let number: Color
    public let comment: Color
    public let attribute: Color
    public let function: Color
    public let property: Color
    public let `operator`: Color
    public let punctuation: Color
    public let plain: Color

    public static let `default` = SyntaxTokenColors(
        keyword: Color(red: 0.78, green: 0.47, blue: 0.85),      // Purple
        type: Color(red: 0.35, green: 0.76, blue: 0.83),         // Cyan
        string: Color(red: 0.90, green: 0.45, blue: 0.45),       // Red
        number: Color(red: 0.85, green: 0.73, blue: 0.45),       // Orange
        comment: Color(red: 0.50, green: 0.60, blue: 0.50),      // Green-gray
        attribute: Color(red: 0.78, green: 0.47, blue: 0.85),    // Purple
        function: Color(red: 0.40, green: 0.70, blue: 0.90),     // Blue
        property: Color(red: 0.35, green: 0.76, blue: 0.83),     // Cyan
        operator: Color.primary,
        punctuation: Color.secondary,
        plain: Color.primary
    )

    public func color(for tokenType: SyntaxTokenType) -> Color {
        switch tokenType {
        case .keyword: return keyword
        case .type: return type
        case .string: return string
        case .number: return number
        case .comment: return comment
        case .attribute: return attribute
        case .function: return function
        case .property: return property
        case .operator: return `operator`
        case .punctuation: return punctuation
        case .plain: return plain
        }
    }
}

// MARK: - Syntax Highlighter

/// 신택스 하이라이터
public struct SyntaxHighlighter: Sendable {
    private let language: SupportedLanguage
    private let rules: LanguageRules
    private let colors: SyntaxTokenColors

    // 캐싱된 정규표현식
    private let keywordRegex: NSRegularExpression?
    private let typeRegex: NSRegularExpression?
    private let attributeRegex: NSRegularExpression?
    private let numberRegex: NSRegularExpression?
    private let functionRegex: NSRegularExpression?
    private let propertyRegex: NSRegularExpression?

    public init(language: SupportedLanguage, colors: SyntaxTokenColors = .default) {
        self.language = language
        self.rules = language.rules
        self.colors = colors

        // 키워드 정규표현식
        if !rules.keywords.isEmpty {
            let escapedKeywords = rules.keywords.map { NSRegularExpression.escapedPattern(for: $0) }
            let pattern = "\\b(\(escapedKeywords.joined(separator: "|")))\\b"
            self.keywordRegex = try? NSRegularExpression(pattern: pattern)
        } else {
            self.keywordRegex = nil
        }

        // 타입 정규표현식
        if !rules.types.isEmpty {
            let escapedTypes = rules.types.map { NSRegularExpression.escapedPattern(for: $0) }
            let pattern = "\\b(\(escapedTypes.joined(separator: "|")))\\b"
            self.typeRegex = try? NSRegularExpression(pattern: pattern)
        } else {
            self.typeRegex = nil
        }

        // 속성 정규표현식
        if !rules.attributes.isEmpty {
            let escapedAttrs = rules.attributes.map { NSRegularExpression.escapedPattern(for: $0) }
            let pattern = "(\(escapedAttrs.joined(separator: "|")))\\b?"
            self.attributeRegex = try? NSRegularExpression(pattern: pattern)
        } else {
            self.attributeRegex = nil
        }

        // 숫자 정규표현식 (정수, 소수, 16진수, 2진수)
        self.numberRegex = try? NSRegularExpression(
            pattern: "\\b(0x[0-9a-fA-F]+|0b[01]+|0o[0-7]+|\\d+\\.?\\d*(?:[eE][+-]?\\d+)?)\\b"
        )

        // 함수 호출 정규표현식
        self.functionRegex = try? NSRegularExpression(
            pattern: "\\b([a-zA-Z_][a-zA-Z0-9_]*)\\s*(?=\\()"
        )

        // 프로퍼티 접근 정규표현식 (.something)
        self.propertyRegex = try? NSRegularExpression(
            pattern: "\\.([a-zA-Z_][a-zA-Z0-9_]*)"
        )
    }

    /// 전체 코드를 하이라이팅합니다.
    public func highlight(_ code: String) -> AttributedString {
        var result = AttributedString()
        let lines = code.components(separatedBy: "\n")

        for (index, line) in lines.enumerated() {
            result.append(highlightLine(line))
            if index < lines.count - 1 {
                result.append(AttributedString("\n"))
            }
        }

        return result
    }

    /// 단일 라인을 하이라이팅합니다.
    public func highlightLine(_ line: String) -> AttributedString {
        guard !line.isEmpty else {
            return AttributedString(line)
        }

        var attributedString = AttributedString(line)
        let nsLine = line as NSString
        let fullRange = NSRange(location: 0, length: nsLine.length)

        // 1. 주석 처리 (가장 높은 우선순위)
        if let highlightedComment = highlightComment(line: line) {
            return highlightedComment
        }

        // 2. 문자열 하이라이팅
        highlightStrings(&attributedString, in: line)

        // 3. 속성 하이라이팅 (@State 등)
        if let regex = attributeRegex {
            applyHighlighting(&attributedString, regex: regex, in: line, range: fullRange, color: colors.attribute)
        }

        // 4. 숫자 하이라이팅
        if let regex = numberRegex {
            applyHighlighting(&attributedString, regex: regex, in: line, range: fullRange, color: colors.number)
        }

        // 5. 타입 하이라이팅
        if let regex = typeRegex {
            applyHighlighting(&attributedString, regex: regex, in: line, range: fullRange, color: colors.type)
        }

        // 6. 키워드 하이라이팅
        if let regex = keywordRegex {
            applyHighlighting(&attributedString, regex: regex, in: line, range: fullRange, color: colors.keyword)
        }

        // 7. 함수 호출 하이라이팅
        if let regex = functionRegex {
            applyHighlighting(&attributedString, regex: regex, in: line, range: fullRange, color: colors.function, captureGroup: 1)
        }

        // 8. 프로퍼티 접근 하이라이팅
        if let regex = propertyRegex {
            applyHighlighting(&attributedString, regex: regex, in: line, range: fullRange, color: colors.property, captureGroup: 1)
        }

        return attributedString
    }

    // MARK: - Private Helpers

    private func highlightComment(line: String) -> AttributedString? {
        // 한 줄 주석 확인
        if let singleComment = rules.singleLineComment,
           let commentIndex = line.range(of: singleComment) {
            var attributedString = AttributedString(line)
            if let attrRange = Range(commentIndex.lowerBound..<line.endIndex, in: attributedString) {
                attributedString[attrRange].foregroundColor = colors.comment
            }
            return attributedString
        }

        return nil
    }

    private func highlightStrings(_ attributedString: inout AttributedString, in line: String) {
        var inString = false
        var stringDelimiter: Character?
        var stringStart: String.Index?

        for (index, char) in line.enumerated() {
            let strIndex = line.index(line.startIndex, offsetBy: index)

            // 이스케이프 문자 처리
            if index > 0 {
                let prevIndex = line.index(line.startIndex, offsetBy: index - 1)
                if line[prevIndex] == "\\" && inString {
                    continue
                }
            }

            if rules.stringDelimiters.contains(char) {
                if inString {
                    if char == stringDelimiter {
                        // 문자열 끝
                        if let start = stringStart {
                            let range = start...strIndex
                            if let attrRange = Range(range, in: attributedString) {
                                attributedString[attrRange].foregroundColor = colors.string
                            }
                        }
                        inString = false
                        stringDelimiter = nil
                        stringStart = nil
                    }
                } else {
                    // 문자열 시작
                    inString = true
                    stringDelimiter = char
                    stringStart = strIndex
                }
            }
        }

        // 닫히지 않은 문자열 처리
        if inString, let start = stringStart {
            let range = start..<line.endIndex
            if let attrRange = Range(range, in: attributedString) {
                attributedString[attrRange].foregroundColor = colors.string
            }
        }
    }

    private func applyHighlighting(
        _ attributedString: inout AttributedString,
        regex: NSRegularExpression,
        in line: String,
        range: NSRange,
        color: Color,
        captureGroup: Int = 0
    ) {
        let matches = regex.matches(in: line, range: range)

        for match in matches {
            let matchRange = captureGroup > 0 && captureGroup < match.numberOfRanges
                ? match.range(at: captureGroup)
                : match.range

            guard matchRange.location != NSNotFound,
                  let swiftRange = Range(matchRange, in: line) else { continue }

            let matchedText = String(line[swiftRange])

            // AttributedString에서 해당 텍스트의 범위 찾기
            if let attrRange = attributedString.range(of: matchedText, options: [], locale: nil) {
                // 이미 색상이 적용된 경우 스킵 (문자열, 주석 등)
                if attributedString[attrRange].foregroundColor == nil {
                    attributedString[attrRange].foregroundColor = color
                }
            }
        }
    }
}

// MARK: - Convenience Extensions

extension SyntaxHighlighter {
    /// 언어 이름으로 하이라이터 생성
    public static func forLanguage(_ name: String?) -> SyntaxHighlighter {
        let language = SupportedLanguage.from(name: name ?? "")
        return SyntaxHighlighter(language: language)
    }
}
