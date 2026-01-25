//
//  LanguageRulesTests.swift
//  EndlessCodeTests
//
//  LanguageRules 및 SupportedLanguage 테스트
//

import Testing
@testable import EndlessCode

@Suite("SupportedLanguage Tests")
struct SupportedLanguageTests {

    // MARK: - Language Detection

    @Test("From name returns correct language for direct match")
    func fromNameDirectMatch() {
        #expect(SupportedLanguage.from(name: "swift") == .swift)
        #expect(SupportedLanguage.from(name: "javascript") == .javascript)
        #expect(SupportedLanguage.from(name: "python") == .python)
        #expect(SupportedLanguage.from(name: "go") == .go)
        #expect(SupportedLanguage.from(name: "rust") == .rust)
    }

    @Test("From name returns correct language for aliases")
    func fromNameAliases() {
        // JavaScript aliases
        #expect(SupportedLanguage.from(name: "js") == .javascript)
        #expect(SupportedLanguage.from(name: "jsx") == .javascript)

        // TypeScript aliases
        #expect(SupportedLanguage.from(name: "ts") == .typescript)
        #expect(SupportedLanguage.from(name: "tsx") == .typescript)

        // Python aliases
        #expect(SupportedLanguage.from(name: "py") == .python)
        #expect(SupportedLanguage.from(name: "python3") == .python)

        // Go aliases
        #expect(SupportedLanguage.from(name: "golang") == .go)

        // Rust aliases
        #expect(SupportedLanguage.from(name: "rs") == .rust)

        // C++ aliases
        #expect(SupportedLanguage.from(name: "c++") == .cpp)
        #expect(SupportedLanguage.from(name: "cc") == .cpp)
        #expect(SupportedLanguage.from(name: "cxx") == .cpp)

        // Shell aliases
        #expect(SupportedLanguage.from(name: "sh") == .bash)
        #expect(SupportedLanguage.from(name: "zsh") == .bash)
        #expect(SupportedLanguage.from(name: "shell") == .bash)
    }

    @Test("From name is case insensitive")
    func fromNameCaseInsensitive() {
        #expect(SupportedLanguage.from(name: "SWIFT") == .swift)
        #expect(SupportedLanguage.from(name: "Swift") == .swift)
        #expect(SupportedLanguage.from(name: "JavaScript") == .javascript)
        #expect(SupportedLanguage.from(name: "PYTHON") == .python)
    }

    @Test("From name returns unknown for unrecognized languages")
    func fromNameUnknown() {
        #expect(SupportedLanguage.from(name: "cobol") == .unknown)
        #expect(SupportedLanguage.from(name: "fortran") == .unknown)
        #expect(SupportedLanguage.from(name: "") == .unknown)
        #expect(SupportedLanguage.from(name: "xyz") == .unknown)
    }

    // MARK: - Language Rules

    @Test("Swift rules contain expected keywords")
    func swiftRulesKeywords() {
        let rules = SupportedLanguage.swift.rules

        #expect(rules.keywords.contains("func"))
        #expect(rules.keywords.contains("struct"))
        #expect(rules.keywords.contains("class"))
        #expect(rules.keywords.contains("let"))
        #expect(rules.keywords.contains("var"))
        #expect(rules.keywords.contains("async"))
        #expect(rules.keywords.contains("await"))
    }

    @Test("Swift rules contain expected types")
    func swiftRulesTypes() {
        let rules = SupportedLanguage.swift.rules

        #expect(rules.types.contains("String"))
        #expect(rules.types.contains("Int"))
        #expect(rules.types.contains("Bool"))
        #expect(rules.types.contains("View"))
        #expect(rules.types.contains("Task"))
    }

    @Test("Swift rules contain expected attributes")
    func swiftRulesAttributes() {
        let rules = SupportedLanguage.swift.rules

        #expect(rules.attributes.contains("@State"))
        #expect(rules.attributes.contains("@Binding"))
        #expect(rules.attributes.contains("@Published"))
        #expect(rules.attributes.contains("@Observable"))
        #expect(rules.attributes.contains("@MainActor"))
    }

    @Test("Swift rules have correct comment delimiters")
    func swiftRulesComments() {
        let rules = SupportedLanguage.swift.rules

        #expect(rules.singleLineComment == "//")
        #expect(rules.blockCommentStart == "/*")
        #expect(rules.blockCommentEnd == "*/")
    }

    @Test("JavaScript rules contain expected keywords")
    func javascriptRulesKeywords() {
        let rules = SupportedLanguage.javascript.rules

        #expect(rules.keywords.contains("function"))
        #expect(rules.keywords.contains("const"))
        #expect(rules.keywords.contains("let"))
        #expect(rules.keywords.contains("var"))
        #expect(rules.keywords.contains("async"))
        #expect(rules.keywords.contains("await"))
        #expect(rules.keywords.contains("class"))
    }

    @Test("Python rules contain expected keywords")
    func pythonRulesKeywords() {
        let rules = SupportedLanguage.python.rules

        #expect(rules.keywords.contains("def"))
        #expect(rules.keywords.contains("class"))
        #expect(rules.keywords.contains("if"))
        #expect(rules.keywords.contains("elif"))
        #expect(rules.keywords.contains("else"))
        #expect(rules.keywords.contains("for"))
        #expect(rules.keywords.contains("while"))
        #expect(rules.keywords.contains("import"))
        #expect(rules.keywords.contains("from"))
        #expect(rules.keywords.contains("async"))
        #expect(rules.keywords.contains("await"))
    }

    @Test("Python rules have correct comment delimiter")
    func pythonRulesComments() {
        let rules = SupportedLanguage.python.rules

        #expect(rules.singleLineComment == "#")
        #expect(rules.blockCommentStart == nil)
        #expect(rules.blockCommentEnd == nil)
    }

    @Test("Go rules contain expected keywords")
    func goRulesKeywords() {
        let rules = SupportedLanguage.go.rules

        #expect(rules.keywords.contains("func"))
        #expect(rules.keywords.contains("package"))
        #expect(rules.keywords.contains("import"))
        #expect(rules.keywords.contains("struct"))
        #expect(rules.keywords.contains("interface"))
        #expect(rules.keywords.contains("go"))
        #expect(rules.keywords.contains("defer"))
        #expect(rules.keywords.contains("chan"))
    }

    @Test("Rust rules contain expected keywords")
    func rustRulesKeywords() {
        let rules = SupportedLanguage.rust.rules

        #expect(rules.keywords.contains("fn"))
        #expect(rules.keywords.contains("let"))
        #expect(rules.keywords.contains("mut"))
        #expect(rules.keywords.contains("impl"))
        #expect(rules.keywords.contains("trait"))
        #expect(rules.keywords.contains("struct"))
        #expect(rules.keywords.contains("enum"))
        #expect(rules.keywords.contains("async"))
        #expect(rules.keywords.contains("await"))
    }

    @Test("SQL rules contain expected keywords in both cases")
    func sqlRulesKeywords() {
        let rules = SupportedLanguage.sql.rules

        // 대문자
        #expect(rules.keywords.contains("SELECT"))
        #expect(rules.keywords.contains("FROM"))
        #expect(rules.keywords.contains("WHERE"))

        // 소문자
        #expect(rules.keywords.contains("select"))
        #expect(rules.keywords.contains("from"))
        #expect(rules.keywords.contains("where"))
    }

    @Test("Unknown language has empty rules")
    func unknownLanguageRules() {
        let rules = SupportedLanguage.unknown.rules

        #expect(rules.keywords.isEmpty)
        #expect(rules.types.isEmpty)
        #expect(rules.attributes.isEmpty)
    }

    // MARK: - String Delimiters

    @Test("Languages have correct string delimiters")
    func stringDelimiters() {
        // Swift uses only double quotes
        #expect(SupportedLanguage.swift.rules.stringDelimiters == ["\""])

        // JavaScript uses double, single, and backtick quotes
        #expect(SupportedLanguage.javascript.rules.stringDelimiters == ["\"", "'", "`"])

        // Python uses double and single quotes
        #expect(SupportedLanguage.python.rules.stringDelimiters == ["\"", "'"])

        // Bash uses double, single, and backtick quotes
        #expect(SupportedLanguage.bash.rules.stringDelimiters == ["\"", "'", "`"])
    }

    // MARK: - Builtin Functions

    @Test("Languages have builtin functions")
    func builtinFunctions() {
        #expect(SupportedLanguage.swift.rules.builtinFunctions.contains("print"))
        #expect(SupportedLanguage.python.rules.builtinFunctions.contains("print"))
        #expect(SupportedLanguage.python.rules.builtinFunctions.contains("len"))
        #expect(SupportedLanguage.go.rules.builtinFunctions.contains("make"))
        #expect(SupportedLanguage.go.rules.builtinFunctions.contains("len"))
    }
}

@Suite("SyntaxTokenType Tests")
struct SyntaxTokenTypeTests {

    @Test("All token types are defined")
    func allTokenTypes() {
        let allTypes = SyntaxTokenType.allCases

        #expect(allTypes.contains(.keyword))
        #expect(allTypes.contains(.type))
        #expect(allTypes.contains(.string))
        #expect(allTypes.contains(.number))
        #expect(allTypes.contains(.comment))
        #expect(allTypes.contains(.attribute))
        #expect(allTypes.contains(.function))
        #expect(allTypes.contains(.property))
        #expect(allTypes.contains(.operator))
        #expect(allTypes.contains(.punctuation))
        #expect(allTypes.contains(.plain))
    }

    @Test("Token type raw values are correct")
    func tokenTypeRawValues() {
        #expect(SyntaxTokenType.keyword.rawValue == "keyword")
        #expect(SyntaxTokenType.string.rawValue == "string")
        #expect(SyntaxTokenType.comment.rawValue == "comment")
    }
}

@Suite("LanguageRules Tests")
struct LanguageRulesTests {

    @Test("LanguageRules can be initialized with minimal parameters")
    func minimalInit() {
        let rules = LanguageRules(keywords: ["if", "else"])

        #expect(rules.keywords == ["if", "else"])
        #expect(rules.types.isEmpty)
        #expect(rules.attributes.isEmpty)
        #expect(rules.singleLineComment == nil)
        #expect(rules.blockCommentStart == nil)
        #expect(rules.blockCommentEnd == nil)
        #expect(rules.stringDelimiters == ["\""])
        #expect(rules.builtinFunctions.isEmpty)
    }

    @Test("LanguageRules can be initialized with all parameters")
    func fullInit() {
        let rules = LanguageRules(
            keywords: ["if", "else"],
            types: ["String", "Int"],
            attributes: ["@attr"],
            singleLineComment: "//",
            blockCommentStart: "/*",
            blockCommentEnd: "*/",
            stringDelimiters: ["\"", "'"],
            builtinFunctions: ["print"]
        )

        #expect(rules.keywords == ["if", "else"])
        #expect(rules.types == ["String", "Int"])
        #expect(rules.attributes == ["@attr"])
        #expect(rules.singleLineComment == "//")
        #expect(rules.blockCommentStart == "/*")
        #expect(rules.blockCommentEnd == "*/")
        #expect(rules.stringDelimiters == ["\"", "'"])
        #expect(rules.builtinFunctions == ["print"])
    }
}
