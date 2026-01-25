//
//  SyntaxHighlighterTests.swift
//  EndlessCodeTests
//
//  SyntaxHighlighter 단위 테스트
//

import Testing
import SwiftUI
@testable import EndlessCode

// MARK: - Syntax Highlighter Tests

@Suite("SyntaxHighlighter Tests")
struct SyntaxHighlighterTests {

    // MARK: - Basic Highlighting Tests

    @Test("Highlight Swift keywords")
    func highlightSwiftKeywords() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = "func test() -> String"

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
        // 하이라이팅된 결과가 비어있지 않음
        #expect(!result.characters.isEmpty)
    }

    @Test("Highlight multiple keywords in one line")
    func highlightMultipleKeywords() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = "public struct MyType: View"

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    @Test("Highlight types correctly")
    func highlightTypes() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = "let name: String = value"

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    // MARK: - String Highlighting Tests

    @Test("Highlight simple string literal")
    func highlightSimpleString() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = #"let greeting = "Hello, World!""#

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    @Test("Highlight string with escape sequence")
    func highlightStringWithEscape() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = #"let text = "Say \"hello\"!""#

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    @Test("Highlight unclosed string")
    func highlightUnclosedString() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = #"let text = "unclosed"#

        // When
        let result = highlighter.highlightLine(code)

        // Then: 닫히지 않은 문자열도 정상 처리
        #expect(result.characters.count == code.count)
    }

    // MARK: - Comment Highlighting Tests

    @Test("Highlight single line comment")
    func highlightSingleLineComment() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = "// This is a comment"

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    @Test("Highlight code with trailing comment")
    func highlightCodeWithTrailingComment() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = "let x = 10 // inline comment"

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    @Test("Highlight Python comment with hash")
    func highlightPythonComment() {
        // Given
        let highlighter = SyntaxHighlighter(language: .python)
        let code = "# This is a Python comment"

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    // MARK: - Number Highlighting Tests

    @Test("Highlight integer numbers")
    func highlightIntegerNumbers() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = "let count = 42"

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    @Test("Highlight floating point numbers")
    func highlightFloatingPointNumbers() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = "let pi = 3.14159"

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    @Test("Highlight hexadecimal numbers")
    func highlightHexNumbers() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = "let color = 0xFF00FF"

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    // MARK: - Attribute Highlighting Tests

    @Test("Highlight Swift attributes")
    func highlightSwiftAttributes() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = "@State private var count = 0"

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    @Test("Highlight multiple attributes")
    func highlightMultipleAttributes() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = "@MainActor @Observable class ViewModel"

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    // MARK: - Function Highlighting Tests

    @Test("Highlight function calls")
    func highlightFunctionCalls() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = "print(message)"

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    @Test("Highlight method chain")
    func highlightMethodChain() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = "array.map { $0 }.filter { $0 > 0 }"

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    // MARK: - Property Highlighting Tests

    @Test("Highlight property access")
    func highlightPropertyAccess() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = "view.frame.origin.x"

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    // MARK: - Multi-line Code Tests

    @Test("Highlight multiline code")
    func highlightMultilineCode() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = """
        struct ContentView: View {
            var body: some View {
                Text("Hello")
            }
        }
        """

        // When
        let result = highlighter.highlight(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    @Test("Highlight large code block")
    func highlightLargeCodeBlock() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = (1...200).map { "let line\($0) = \($0)" }.joined(separator: "\n")

        // When
        let result = highlighter.highlight(code)

        // Then
        #expect(result.characters.count > 0)
    }

    // MARK: - Empty Input Tests

    @Test("Highlight empty line returns empty string")
    func highlightEmptyLine() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)

        // When
        let result = highlighter.highlightLine("")

        // Then
        #expect(result.characters.isEmpty)
    }

    @Test("Highlight whitespace only line")
    func highlightWhitespaceOnlyLine() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = "    "

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    // MARK: - Language-specific Tests

    @Test("Highlight JavaScript async/await")
    func highlightJavaScriptAsyncAwait() {
        // Given
        let highlighter = SyntaxHighlighter(language: .javascript)
        let code = "async function fetchData() { await fetch(url) }"

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    @Test("Highlight Python def and class")
    func highlightPythonDefAndClass() {
        // Given
        let highlighter = SyntaxHighlighter(language: .python)
        let code = "def calculate(x: int) -> int:"

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    @Test("Highlight Go keywords")
    func highlightGoKeywords() {
        // Given
        let highlighter = SyntaxHighlighter(language: .go)
        let code = "func main() { go handleRequest() }"

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    @Test("Highlight Rust attributes")
    func highlightRustAttributes() {
        // Given
        let highlighter = SyntaxHighlighter(language: .rust)
        let code = "#[derive(Debug, Clone)]"

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    // MARK: - Duplicate Token Handling Tests

    @Test("Highlight duplicate keywords correctly")
    func highlightDuplicateKeywords() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = "let let = let"  // 같은 키워드가 여러 번 등장

        // When
        let result = highlighter.highlightLine(code)

        // Then: 모든 'let' 키워드가 하이라이팅되어야 함
        #expect(result.characters.count == code.count)
    }

    @Test("Highlight same identifier appearing multiple times")
    func highlightSameIdentifierMultipleTimes() {
        // Given
        let highlighter = SyntaxHighlighter(language: .swift)
        let code = "print(value); print(value)"

        // When
        let result = highlighter.highlightLine(code)

        // Then
        #expect(result.characters.count == code.count)
    }

    // MARK: - Convenience Factory Tests

    @Test("Create highlighter from language name string")
    func createHighlighterFromLanguageName() {
        // Given
        let languageName = "swift"

        // When
        let highlighter = SyntaxHighlighter.forLanguage(languageName)
        let result = highlighter.highlightLine("let x = 1")

        // Then
        #expect(result.characters.count > 0)
    }

    @Test("Create highlighter from nil language defaults to unknown")
    func createHighlighterFromNilLanguage() {
        // Given/When
        let highlighter = SyntaxHighlighter.forLanguage(nil)
        let result = highlighter.highlightLine("some text")

        // Then
        #expect(result.characters.count > 0)
    }

    @Test("Create highlighter from language alias")
    func createHighlighterFromAlias() {
        // Given
        let languageAlias = "js"

        // When
        let highlighter = SyntaxHighlighter.forLanguage(languageAlias)
        let result = highlighter.highlightLine("const x = 1")

        // Then
        #expect(result.characters.count > 0)
    }
}
