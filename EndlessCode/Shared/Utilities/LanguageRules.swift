//
//  LanguageRules.swift
//  EndlessCode
//
//  언어별 하이라이팅 규칙 정의
//  플랫폼 독립적인 코어 로직
//

import Foundation

// MARK: - Token Types

/// 신택스 토큰 타입
public enum SyntaxTokenType: String, CaseIterable, Sendable {
    case keyword        // 예약어: func, class, if, for
    case type           // 타입: String, Int, View
    case string         // 문자열: "hello"
    case number         // 숫자: 42, 3.14
    case comment        // 주석: // comment, /* block */
    case attribute      // 속성: @State, @Published
    case function       // 함수명: print, map
    case property       // 프로퍼티: .leading, .red
    case `operator`     // 연산자: +, -, *, /
    case punctuation    // 구두점: {, }, (, )
    case plain          // 일반 텍스트
}

// MARK: - Language Rules

/// 언어별 하이라이팅 규칙
public struct LanguageRules: Sendable {
    public let keywords: Set<String>
    public let types: Set<String>
    public let attributes: Set<String>
    public let singleLineComment: String?
    public let blockCommentStart: String?
    public let blockCommentEnd: String?
    public let stringDelimiters: Set<Character>
    public let builtinFunctions: Set<String>

    public init(
        keywords: Set<String>,
        types: Set<String> = [],
        attributes: Set<String> = [],
        singleLineComment: String? = nil,
        blockCommentStart: String? = nil,
        blockCommentEnd: String? = nil,
        stringDelimiters: Set<Character> = ["\""],
        builtinFunctions: Set<String> = []
    ) {
        self.keywords = keywords
        self.types = types
        self.attributes = attributes
        self.singleLineComment = singleLineComment
        self.blockCommentStart = blockCommentStart
        self.blockCommentEnd = blockCommentEnd
        self.stringDelimiters = stringDelimiters
        self.builtinFunctions = builtinFunctions
    }
}

// MARK: - Language Definitions

/// 지원 언어 정의
public enum SupportedLanguage: String, CaseIterable, Sendable {
    case swift
    case javascript
    case typescript
    case python
    case go
    case rust
    case java
    case kotlin
    case csharp
    case cpp
    case c
    case ruby
    case php
    case html
    case css
    case json
    case yaml
    case bash
    case sql
    case markdown
    case unknown

    /// 언어 별칭 매핑
    public static func from(name: String) -> SupportedLanguage {
        let lowercased = name.lowercased()

        // 직접 매핑
        if let lang = SupportedLanguage(rawValue: lowercased) {
            return lang
        }

        // 별칭 매핑
        switch lowercased {
        case "js": return .javascript
        case "ts", "tsx": return .typescript
        case "jsx": return .javascript
        case "py", "python3": return .python
        case "golang": return .go
        case "rs": return .rust
        case "kt": return .kotlin
        case "cs", "c#": return .csharp
        case "c++", "cc", "cxx", "hpp": return .cpp
        case "h": return .c
        case "rb": return .ruby
        case "sh", "zsh", "shell": return .bash
        case "yml": return .yaml
        case "md": return .markdown
        default: return .unknown
        }
    }

    /// 파일 확장자로부터 언어 결정
    public static func from(extension ext: String) -> SupportedLanguage {
        let lowercased = ext.lowercased()

        switch lowercased {
        // Swift
        case "swift":
            return .swift

        // JavaScript/TypeScript
        case "js", "jsx", "mjs", "cjs":
            return .javascript
        case "ts", "tsx":
            return .typescript

        // Python
        case "py", "pyw", "pyi":
            return .python

        // Go
        case "go":
            return .go

        // Rust
        case "rs":
            return .rust

        // Java
        case "java":
            return .java

        // Kotlin
        case "kt", "kts":
            return .kotlin

        // C#
        case "cs":
            return .csharp

        // C/C++
        case "c", "h":
            return .c
        case "cpp", "cc", "cxx", "hpp", "hxx":
            return .cpp

        // Ruby
        case "rb", "erb":
            return .ruby

        // PHP
        case "php":
            return .php

        // Web
        case "html", "htm", "xhtml":
            return .html
        case "css", "scss", "sass", "less":
            return .css

        // Data
        case "json", "jsonl":
            return .json
        case "yaml", "yml":
            return .yaml

        // Shell
        case "sh", "bash", "zsh":
            return .bash

        // SQL
        case "sql":
            return .sql

        // Markdown
        case "md", "markdown", "mdx":
            return .markdown

        default:
            return .unknown
        }
    }

    /// 언어별 규칙
    public var rules: LanguageRules {
        switch self {
        case .swift:
            return LanguageRules(
                keywords: [
                    "actor", "any", "as", "associatedtype", "async", "await",
                    "break", "case", "catch", "class", "continue", "convenience",
                    "default", "defer", "deinit", "do", "dynamic",
                    "else", "enum", "extension", "fallthrough", "false", "fileprivate",
                    "final", "for", "func", "get", "guard",
                    "if", "import", "in", "indirect", "infix", "init", "inout", "internal", "is",
                    "lazy", "left", "let", "mutating", "nil", "none", "nonisolated", "nonmutating",
                    "open", "operator", "optional", "override",
                    "postfix", "precedence", "prefix", "private", "protocol", "public",
                    "repeat", "required", "rethrows", "return", "right",
                    "self", "Self", "set", "some", "static", "struct", "subscript", "super", "switch",
                    "throw", "throws", "true", "try", "Type", "typealias",
                    "unowned", "var", "weak", "where", "while", "willSet"
                ],
                types: [
                    "String", "Int", "Double", "Float", "Bool", "Character",
                    "Array", "Dictionary", "Set", "Optional", "Result",
                    "Void", "Never", "Any", "AnyObject",
                    "Int8", "Int16", "Int32", "Int64",
                    "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
                    "CGFloat", "CGPoint", "CGSize", "CGRect",
                    "View", "Text", "Image", "Button", "VStack", "HStack", "ZStack",
                    "NavigationView", "NavigationStack", "NavigationSplitView",
                    "List", "ForEach", "ScrollView", "LazyVStack", "LazyHStack",
                    "ObservableObject", "Published", "StateObject", "ObservedObject",
                    "Binding", "State", "Environment", "EnvironmentObject",
                    "Task", "AsyncSequence", "AsyncStream"
                ],
                attributes: [
                    "@State", "@Binding", "@Published", "@Observable", "@ObservationIgnored",
                    "@StateObject", "@ObservedObject", "@EnvironmentObject", "@Environment",
                    "@MainActor", "@Sendable", "@escaping", "@autoclosure",
                    "@available", "@discardableResult", "@frozen", "@inlinable",
                    "@objc", "@objcMembers", "@IBOutlet", "@IBAction", "@IBInspectable",
                    "@propertyWrapper", "@resultBuilder", "@dynamicMemberLookup",
                    "@ViewBuilder", "@SceneBuilder", "@ToolbarContentBuilder"
                ],
                singleLineComment: "//",
                blockCommentStart: "/*",
                blockCommentEnd: "*/",
                stringDelimiters: ["\""],
                builtinFunctions: [
                    "print", "debugPrint", "dump", "fatalError", "precondition",
                    "assert", "assertionFailure", "preconditionFailure",
                    "min", "max", "abs", "stride", "zip", "type"
                ]
            )

        case .javascript, .typescript:
            return LanguageRules(
                keywords: [
                    "async", "await", "break", "case", "catch", "class", "const", "continue",
                    "debugger", "default", "delete", "do", "else", "enum", "export", "extends",
                    "false", "finally", "for", "from", "function", "get", "if", "implements",
                    "import", "in", "instanceof", "interface", "let", "new", "null", "of",
                    "package", "private", "protected", "public", "return", "set", "static",
                    "super", "switch", "this", "throw", "true", "try", "type", "typeof",
                    "undefined", "var", "void", "while", "with", "yield"
                ],
                types: [
                    "string", "number", "boolean", "object", "any", "void", "never", "unknown",
                    "Array", "Object", "Function", "Promise", "Map", "Set", "Date", "RegExp",
                    "Error", "Symbol", "BigInt", "Record", "Partial", "Required", "Readonly"
                ],
                singleLineComment: "//",
                blockCommentStart: "/*",
                blockCommentEnd: "*/",
                stringDelimiters: ["\"", "'", "`"],
                builtinFunctions: [
                    "console", "log", "error", "warn", "info",
                    "setTimeout", "setInterval", "clearTimeout", "clearInterval",
                    "parseInt", "parseFloat", "isNaN", "isFinite",
                    "JSON", "parse", "stringify",
                    "fetch", "require", "module", "exports"
                ]
            )

        case .python:
            return LanguageRules(
                keywords: [
                    "False", "None", "True", "and", "as", "assert", "async", "await",
                    "break", "class", "continue", "def", "del", "elif", "else", "except",
                    "finally", "for", "from", "global", "if", "import", "in", "is",
                    "lambda", "nonlocal", "not", "or", "pass", "raise", "return",
                    "try", "while", "with", "yield"
                ],
                types: [
                    "str", "int", "float", "bool", "list", "dict", "set", "tuple",
                    "bytes", "bytearray", "complex", "frozenset", "range",
                    "List", "Dict", "Set", "Tuple", "Optional", "Union", "Any", "Callable"
                ],
                singleLineComment: "#",
                stringDelimiters: ["\"", "'"],
                builtinFunctions: [
                    "print", "len", "range", "type", "str", "int", "float", "bool",
                    "list", "dict", "set", "tuple", "input", "open", "file",
                    "abs", "all", "any", "bin", "chr", "dir", "divmod", "enumerate",
                    "eval", "exec", "filter", "format", "getattr", "globals", "hasattr",
                    "hash", "hex", "id", "isinstance", "issubclass", "iter", "map",
                    "max", "min", "next", "oct", "ord", "pow", "repr", "reversed",
                    "round", "setattr", "slice", "sorted", "sum", "super", "vars", "zip"
                ]
            )

        case .go:
            return LanguageRules(
                keywords: [
                    "break", "case", "chan", "const", "continue", "default", "defer",
                    "else", "fallthrough", "for", "func", "go", "goto", "if", "import",
                    "interface", "map", "package", "range", "return", "select", "struct",
                    "switch", "type", "var"
                ],
                types: [
                    "bool", "byte", "complex64", "complex128", "error", "float32", "float64",
                    "int", "int8", "int16", "int32", "int64", "rune", "string",
                    "uint", "uint8", "uint16", "uint32", "uint64", "uintptr"
                ],
                singleLineComment: "//",
                blockCommentStart: "/*",
                blockCommentEnd: "*/",
                stringDelimiters: ["\"", "`"],
                builtinFunctions: [
                    "append", "cap", "close", "complex", "copy", "delete",
                    "imag", "len", "make", "new", "panic", "print", "println",
                    "real", "recover"
                ]
            )

        case .rust:
            return LanguageRules(
                keywords: [
                    "as", "async", "await", "break", "const", "continue", "crate", "dyn",
                    "else", "enum", "extern", "false", "fn", "for", "if", "impl", "in",
                    "let", "loop", "match", "mod", "move", "mut", "pub", "ref", "return",
                    "self", "Self", "static", "struct", "super", "trait", "true", "type",
                    "union", "unsafe", "use", "where", "while"
                ],
                types: [
                    "bool", "char", "f32", "f64", "i8", "i16", "i32", "i64", "i128", "isize",
                    "str", "u8", "u16", "u32", "u64", "u128", "usize",
                    "String", "Vec", "Option", "Result", "Box", "Rc", "Arc",
                    "HashMap", "HashSet", "BTreeMap", "BTreeSet"
                ],
                attributes: [
                    "#[derive", "#[cfg", "#[test", "#[allow", "#[deny", "#[warn",
                    "#[inline", "#[must_use", "#[repr", "#[macro_export"
                ],
                singleLineComment: "//",
                blockCommentStart: "/*",
                blockCommentEnd: "*/",
                stringDelimiters: ["\""],
                builtinFunctions: [
                    "println!", "print!", "eprintln!", "eprint!", "format!",
                    "vec!", "panic!", "assert!", "assert_eq!", "assert_ne!",
                    "debug_assert!", "todo!", "unimplemented!", "unreachable!"
                ]
            )

        case .java, .kotlin:
            return LanguageRules(
                keywords: [
                    "abstract", "assert", "boolean", "break", "byte", "case", "catch",
                    "char", "class", "const", "continue", "default", "do", "double",
                    "else", "enum", "extends", "final", "finally", "float", "for",
                    "goto", "if", "implements", "import", "instanceof", "int", "interface",
                    "long", "native", "new", "null", "package", "private", "protected",
                    "public", "return", "short", "static", "strictfp", "super", "switch",
                    "synchronized", "this", "throw", "throws", "transient", "true", "try",
                    "void", "volatile", "while",
                    // Kotlin specific
                    "fun", "val", "var", "when", "object", "companion", "data", "sealed",
                    "inline", "noinline", "crossinline", "reified", "suspend", "lateinit"
                ],
                types: [
                    "String", "Integer", "Long", "Double", "Float", "Boolean", "Byte",
                    "Short", "Character", "Object", "Class", "List", "ArrayList",
                    "Map", "HashMap", "Set", "HashSet"
                ],
                singleLineComment: "//",
                blockCommentStart: "/*",
                blockCommentEnd: "*/",
                stringDelimiters: ["\"", "'"],
                builtinFunctions: [
                    "System.out.println", "println", "print"
                ]
            )

        case .csharp:
            return LanguageRules(
                keywords: [
                    "abstract", "as", "async", "await", "base", "bool", "break", "byte",
                    "case", "catch", "char", "checked", "class", "const", "continue",
                    "decimal", "default", "delegate", "do", "double", "else", "enum",
                    "event", "explicit", "extern", "false", "finally", "fixed", "float",
                    "for", "foreach", "get", "goto", "if", "implicit", "in", "int",
                    "interface", "internal", "is", "lock", "long", "namespace", "new",
                    "null", "object", "operator", "out", "override", "params", "partial",
                    "private", "protected", "public", "readonly", "ref", "return", "sbyte",
                    "sealed", "set", "short", "sizeof", "stackalloc", "static", "string",
                    "struct", "switch", "this", "throw", "true", "try", "typeof", "uint",
                    "ulong", "unchecked", "unsafe", "ushort", "using", "value", "var",
                    "virtual", "void", "volatile", "where", "while", "yield"
                ],
                types: [
                    "String", "Int32", "Int64", "Double", "Single", "Boolean", "Byte",
                    "Char", "Decimal", "Object", "List", "Dictionary", "Task", "Func", "Action"
                ],
                singleLineComment: "//",
                blockCommentStart: "/*",
                blockCommentEnd: "*/",
                stringDelimiters: ["\"", "'"],
                builtinFunctions: [
                    "Console.WriteLine", "Console.Write", "Debug.Log"
                ]
            )

        case .cpp, .c:
            return LanguageRules(
                keywords: [
                    "alignas", "alignof", "and", "and_eq", "asm", "auto", "bitand",
                    "bitor", "bool", "break", "case", "catch", "char", "char8_t",
                    "char16_t", "char32_t", "class", "compl", "concept", "const",
                    "consteval", "constexpr", "constinit", "const_cast", "continue",
                    "co_await", "co_return", "co_yield", "decltype", "default", "delete",
                    "do", "double", "dynamic_cast", "else", "enum", "explicit", "export",
                    "extern", "false", "float", "for", "friend", "goto", "if", "inline",
                    "int", "long", "mutable", "namespace", "new", "noexcept", "not",
                    "not_eq", "nullptr", "operator", "or", "or_eq", "private", "protected",
                    "public", "register", "reinterpret_cast", "requires", "return", "short",
                    "signed", "sizeof", "static", "static_assert", "static_cast", "struct",
                    "switch", "template", "this", "thread_local", "throw", "true", "try",
                    "typedef", "typeid", "typename", "union", "unsigned", "using",
                    "virtual", "void", "volatile", "wchar_t", "while", "xor", "xor_eq"
                ],
                types: [
                    "size_t", "ptrdiff_t", "intptr_t", "uintptr_t",
                    "int8_t", "int16_t", "int32_t", "int64_t",
                    "uint8_t", "uint16_t", "uint32_t", "uint64_t",
                    "string", "vector", "map", "set", "list", "deque", "array",
                    "shared_ptr", "unique_ptr", "weak_ptr", "optional", "variant"
                ],
                singleLineComment: "//",
                blockCommentStart: "/*",
                blockCommentEnd: "*/",
                stringDelimiters: ["\"", "'"],
                builtinFunctions: [
                    "printf", "scanf", "cout", "cin", "endl",
                    "malloc", "free", "new", "delete",
                    "sizeof", "strlen", "strcmp", "strcpy", "memcpy", "memset"
                ]
            )

        case .ruby:
            return LanguageRules(
                keywords: [
                    "BEGIN", "END", "alias", "and", "begin", "break", "case", "class",
                    "def", "defined?", "do", "else", "elsif", "end", "ensure", "false",
                    "for", "if", "in", "module", "next", "nil", "not", "or", "redo",
                    "rescue", "retry", "return", "self", "super", "then", "true", "undef",
                    "unless", "until", "when", "while", "yield", "__FILE__", "__LINE__"
                ],
                types: [
                    "String", "Integer", "Float", "Array", "Hash", "Symbol", "Range",
                    "Regexp", "Proc", "Lambda", "Class", "Module", "Object", "Struct"
                ],
                singleLineComment: "#",
                stringDelimiters: ["\"", "'"],
                builtinFunctions: [
                    "puts", "print", "p", "gets", "require", "require_relative",
                    "attr_accessor", "attr_reader", "attr_writer",
                    "raise", "rescue", "catch", "throw"
                ]
            )

        case .php:
            return LanguageRules(
                keywords: [
                    "abstract", "and", "array", "as", "break", "callable", "case", "catch",
                    "class", "clone", "const", "continue", "declare", "default", "do", "echo",
                    "else", "elseif", "empty", "enddeclare", "endfor", "endforeach", "endif",
                    "endswitch", "endwhile", "eval", "exit", "extends", "final", "finally",
                    "fn", "for", "foreach", "function", "global", "goto", "if", "implements",
                    "include", "include_once", "instanceof", "insteadof", "interface", "isset",
                    "list", "match", "namespace", "new", "or", "print", "private", "protected",
                    "public", "readonly", "require", "require_once", "return", "static",
                    "switch", "throw", "trait", "try", "unset", "use", "var", "while", "xor",
                    "yield", "true", "false", "null"
                ],
                types: [
                    "int", "float", "bool", "string", "array", "object", "callable", "iterable",
                    "void", "mixed", "never", "null"
                ],
                singleLineComment: "//",
                blockCommentStart: "/*",
                blockCommentEnd: "*/",
                stringDelimiters: ["\"", "'"],
                builtinFunctions: [
                    "echo", "print", "var_dump", "print_r", "die", "exit",
                    "strlen", "strpos", "substr", "explode", "implode",
                    "array_push", "array_pop", "array_shift", "array_unshift",
                    "count", "sizeof", "in_array", "array_key_exists"
                ]
            )

        case .html:
            return LanguageRules(
                keywords: [
                    "html", "head", "body", "div", "span", "p", "a", "img", "ul", "ol", "li",
                    "table", "tr", "td", "th", "form", "input", "button", "select", "option",
                    "script", "style", "link", "meta", "title", "header", "footer", "nav",
                    "section", "article", "aside", "main", "figure", "figcaption"
                ],
                stringDelimiters: ["\"", "'"]
            )

        case .css:
            return LanguageRules(
                keywords: [
                    "important", "inherit", "initial", "unset", "auto", "none",
                    "block", "inline", "flex", "grid", "hidden", "visible",
                    "absolute", "relative", "fixed", "sticky", "static"
                ],
                singleLineComment: nil,
                blockCommentStart: "/*",
                blockCommentEnd: "*/",
                stringDelimiters: ["\"", "'"]
            )

        case .json, .yaml:
            return LanguageRules(keywords: ["true", "false", "null"], stringDelimiters: ["\""])

        case .bash:
            return LanguageRules(
                keywords: [
                    "if", "then", "else", "elif", "fi", "for", "while", "do", "done",
                    "case", "esac", "in", "function", "return", "exit", "break", "continue",
                    "export", "local", "readonly", "shift", "source", "eval", "exec",
                    "set", "unset", "true", "false"
                ],
                singleLineComment: "#",
                stringDelimiters: ["\"", "'", "`"],
                builtinFunctions: [
                    "echo", "printf", "read", "cd", "pwd", "ls", "cat", "grep", "sed", "awk",
                    "find", "xargs", "sort", "uniq", "wc", "head", "tail", "cut", "tr",
                    "mkdir", "rm", "cp", "mv", "chmod", "chown", "touch"
                ]
            )

        case .sql:
            return LanguageRules(
                keywords: [
                    "SELECT", "FROM", "WHERE", "INSERT", "INTO", "VALUES", "UPDATE", "SET",
                    "DELETE", "CREATE", "DROP", "ALTER", "TABLE", "INDEX", "VIEW",
                    "JOIN", "INNER", "LEFT", "RIGHT", "OUTER", "ON", "AND", "OR", "NOT",
                    "IN", "BETWEEN", "LIKE", "IS", "NULL", "AS", "ORDER", "BY", "ASC", "DESC",
                    "GROUP", "HAVING", "LIMIT", "OFFSET", "UNION", "DISTINCT", "PRIMARY", "KEY",
                    "FOREIGN", "REFERENCES", "CONSTRAINT", "DEFAULT", "AUTO_INCREMENT",
                    // 소문자 버전
                    "select", "from", "where", "insert", "into", "values", "update", "set",
                    "delete", "create", "drop", "alter", "table", "index", "view",
                    "join", "inner", "left", "right", "outer", "on", "and", "or", "not",
                    "in", "between", "like", "is", "null", "as", "order", "by", "asc", "desc",
                    "group", "having", "limit", "offset", "union", "distinct", "primary", "key",
                    "foreign", "references", "constraint", "default", "auto_increment"
                ],
                types: [
                    "INT", "INTEGER", "BIGINT", "SMALLINT", "TINYINT",
                    "DECIMAL", "NUMERIC", "FLOAT", "REAL", "DOUBLE",
                    "CHAR", "VARCHAR", "TEXT", "BLOB", "BINARY",
                    "DATE", "TIME", "DATETIME", "TIMESTAMP", "BOOLEAN"
                ],
                singleLineComment: "--",
                blockCommentStart: "/*",
                blockCommentEnd: "*/",
                stringDelimiters: ["\"", "'"]
            )

        case .markdown, .unknown:
            return LanguageRules(keywords: [])
        }
    }
}
