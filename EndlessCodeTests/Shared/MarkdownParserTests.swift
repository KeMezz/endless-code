//
//  MarkdownParserTests.swift
//  EndlessCodeTests
//
//  MarkdownParser 테스트
//

import Testing
@testable import EndlessCode

@Suite("MarkdownParser Tests")
struct MarkdownParserTests {
    let parser = MarkdownParser()

    // MARK: - Heading Tests

    @Test("Parse heading level 1")
    func parseHeadingLevel1() {
        // Given
        let markdown = "# Heading 1"

        // When
        let nodes = parser.parse(markdown)

        // Then
        #expect(nodes.count == 1)
        if case .heading(let level, let content) = nodes[0] {
            #expect(level == 1)
            #expect(content.count == 1)
            if case .text(let text) = content[0] {
                #expect(text == "Heading 1")
            } else {
                Issue.record("Expected text node")
            }
        } else {
            Issue.record("Expected heading node")
        }
    }

    @Test("Parse heading level 2")
    func parseHeadingLevel2() {
        // Given
        let markdown = "## Heading 2"

        // When
        let nodes = parser.parse(markdown)

        // Then
        #expect(nodes.count == 1)
        if case .heading(let level, _) = nodes[0] {
            #expect(level == 2)
        } else {
            Issue.record("Expected heading node")
        }
    }

    @Test("Parse heading level 3")
    func parseHeadingLevel3() {
        // Given
        let markdown = "### Heading 3"

        // When
        let nodes = parser.parse(markdown)

        // Then
        #expect(nodes.count == 1)
        if case .heading(let level, _) = nodes[0] {
            #expect(level == 3)
        } else {
            Issue.record("Expected heading node")
        }
    }

    // MARK: - Code Block Tests

    @Test("Parse code block with language")
    func parseCodeBlockWithLanguage() {
        // Given
        let markdown = """
        ```swift
        let x = 42
        ```
        """

        // When
        let nodes = parser.parse(markdown)

        // Then
        #expect(nodes.count == 1)
        if case .codeBlock(let code, let language) = nodes[0] {
            #expect(code == "let x = 42")
            #expect(language == "swift")
        } else {
            Issue.record("Expected code block node")
        }
    }

    @Test("Parse code block without language")
    func parseCodeBlockWithoutLanguage() {
        // Given
        let markdown = """
        ```
        npm install
        ```
        """

        // When
        let nodes = parser.parse(markdown)

        // Then
        #expect(nodes.count == 1)
        if case .codeBlock(let code, let language) = nodes[0] {
            #expect(code == "npm install")
            #expect(language == nil)
        } else {
            Issue.record("Expected code block node")
        }
    }

    @Test("Parse text and code block mixed")
    func parseTextAndCodeBlockMixed() {
        // Given
        let markdown = """
        Here's some code:

        ```swift
        print("Hello")
        ```

        That's it!
        """

        // When
        let nodes = parser.parse(markdown)

        // Then
        #expect(nodes.count == 3)
        #expect(nodes[0] == .paragraph([.text("Here's some code:")]))
        if case .codeBlock(let code, _) = nodes[1] {
            #expect(code == "print(\"Hello\")")
        } else {
            Issue.record("Expected code block node")
        }
        #expect(nodes[2] == .paragraph([.text("That's it!")]))
    }

    // MARK: - Inline Tests

    @Test("Parse bold text")
    func parseBoldText() {
        // Given
        let markdown = "This is **bold** text"

        // When
        let nodes = parser.parse(markdown)

        // Then
        #expect(nodes.count == 1)
        if case .paragraph(let inlineNodes) = nodes[0] {
            #expect(inlineNodes.count == 3)
            #expect(inlineNodes[0] == .text("This is "))
            #expect(inlineNodes[1] == .bold("bold"))
            #expect(inlineNodes[2] == .text(" text"))
        } else {
            Issue.record("Expected paragraph node")
        }
    }

    @Test("Parse italic text")
    func parseItalicText() {
        // Given
        let markdown = "This is *italic* text"

        // When
        let nodes = parser.parse(markdown)

        // Then
        #expect(nodes.count == 1)
        if case .paragraph(let inlineNodes) = nodes[0] {
            #expect(inlineNodes.count == 3)
            #expect(inlineNodes[0] == .text("This is "))
            #expect(inlineNodes[1] == .italic("italic"))
            #expect(inlineNodes[2] == .text(" text"))
        } else {
            Issue.record("Expected paragraph node")
        }
    }

    @Test("Parse inline code")
    func parseInlineCode() {
        // Given
        let markdown = "Use the `View` protocol"

        // When
        let nodes = parser.parse(markdown)

        // Then
        #expect(nodes.count == 1)
        if case .paragraph(let inlineNodes) = nodes[0] {
            #expect(inlineNodes.count == 3)
            #expect(inlineNodes[0] == .text("Use the "))
            #expect(inlineNodes[1] == .code("View"))
            #expect(inlineNodes[2] == .text(" protocol"))
        } else {
            Issue.record("Expected paragraph node")
        }
    }

    @Test("Parse link")
    func parseLink() {
        // Given
        let markdown = "Visit [Swift.org](https://swift.org) for more"

        // When
        let nodes = parser.parse(markdown)

        // Then
        #expect(nodes.count == 1)
        if case .paragraph(let inlineNodes) = nodes[0] {
            #expect(inlineNodes.count == 3)
            #expect(inlineNodes[0] == .text("Visit "))
            #expect(inlineNodes[1] == .link(text: "Swift.org", url: "https://swift.org"))
            #expect(inlineNodes[2] == .text(" for more"))
        } else {
            Issue.record("Expected paragraph node")
        }
    }

    @Test("Parse mixed inline elements")
    func parseMixedInlineElements() {
        // Given
        let markdown = "This is **bold** and *italic* with `code`"

        // When
        let nodes = parser.parse(markdown)

        // Then
        #expect(nodes.count == 1)
        if case .paragraph(let inlineNodes) = nodes[0] {
            #expect(inlineNodes.count == 6)
            #expect(inlineNodes[0] == .text("This is "))
            #expect(inlineNodes[1] == .bold("bold"))
            #expect(inlineNodes[2] == .text(" and "))
            #expect(inlineNodes[3] == .italic("italic"))
            #expect(inlineNodes[4] == .text(" with "))
            #expect(inlineNodes[5] == .code("code"))
        } else {
            Issue.record("Expected paragraph node")
        }
    }

    // MARK: - List Tests

    @Test("Parse unordered list")
    func parseUnorderedList() {
        // Given
        let markdown = """
        - Item 1
        - Item 2
        - Item 3
        """

        // When
        let nodes = parser.parse(markdown)

        // Then
        #expect(nodes.count == 3)
        for (index, node) in nodes.enumerated() {
            if case .listItem(let content, let isOrdered) = node {
                #expect(isOrdered == false)
                #expect(content.count == 1)
                if case .text(let text) = content[0] {
                    #expect(text == "Item \(index + 1)")
                } else {
                    Issue.record("Expected text node in list item")
                }
            } else {
                Issue.record("Expected list item node")
            }
        }
    }

    @Test("Parse ordered list")
    func parseOrderedList() {
        // Given
        let markdown = """
        1. First
        2. Second
        3. Third
        """

        // When
        let nodes = parser.parse(markdown)

        // Then
        #expect(nodes.count == 3)
        for node in nodes {
            if case .listItem(_, let isOrdered) = node {
                #expect(isOrdered == true)
            } else {
                Issue.record("Expected list item node")
            }
        }
    }

    @Test("Parse list with inline formatting")
    func parseListWithInlineFormatting() {
        // Given
        let markdown = "- This is **bold** item"

        // When
        let nodes = parser.parse(markdown)

        // Then
        #expect(nodes.count == 1)
        if case .listItem(let content, _) = nodes[0] {
            #expect(content.count == 3)
            #expect(content[0] == .text("This is "))
            #expect(content[1] == .bold("bold"))
            #expect(content[2] == .text(" item"))
        } else {
            Issue.record("Expected list item node")
        }
    }

    // MARK: - Complex Tests

    @Test("Parse complex markdown")
    func parseComplexMarkdown() {
        // Given
        let markdown = """
        # Title

        This is a **paragraph** with *italic* and `code`.

        ```swift
        let x = 42
        ```

        - List item 1
        - List item 2
        """

        // When
        let nodes = parser.parse(markdown)

        // Then
        #expect(nodes.count >= 5)
        #expect(nodes[0] == .heading(level: 1, content: [.text("Title")]))

        if case .paragraph(let inline) = nodes[1] {
            #expect(inline.count == 7)
        } else {
            Issue.record("Expected paragraph node")
        }

        if case .codeBlock(let code, let language) = nodes[2] {
            #expect(code == "let x = 42")
            #expect(language == "swift")
        } else {
            Issue.record("Expected code block node")
        }
    }

    @Test("Parse empty string returns text node")
    func parseEmptyStringReturnsTextNode() {
        // Given
        let markdown = ""

        // When
        let nodes = parser.parse(markdown)

        // Then
        #expect(nodes.count == 1)
        #expect(nodes[0] == .text(""))
    }

    @Test("Parse plain text returns paragraph")
    func parsePlainTextReturnsParagraph() {
        // Given
        let markdown = "Just plain text"

        // When
        let nodes = parser.parse(markdown)

        // Then
        #expect(nodes.count == 1)
        #expect(nodes[0] == .paragraph([.text("Just plain text")]))
    }
}
