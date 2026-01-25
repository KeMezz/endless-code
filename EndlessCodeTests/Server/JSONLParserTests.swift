//
//  JSONLParserTests.swift
//  EndlessCodeTests
//
//  JSONLParser 단위 테스트 (Swift Testing)
//

import Testing
@testable import EndlessCode

@Suite("JSONLParser Tests")
struct JSONLParserTests {
    let parser = JSONLParser()

    // MARK: - Chat Message Tests

    @Test("Parse chat message returns chat")
    func parseChatMessage() throws {
        let json = """
        {"type":"message","role":"assistant","content":"Hello, world!"}
        """

        let result = try parser.parse(line: json)

        guard case .chat(let message) = result else {
            Issue.record("Expected chat message, got \(result)")
            return
        }
        #expect(message.type == "message")
        #expect(message.role == .assistant)
        #expect(message.content == "Hello, world!")
    }

    @Test("Parse user message returns correct role")
    func parseUserMessage() throws {
        let json = """
        {"type":"message","role":"user","content":"Hi there"}
        """

        let result = try parser.parse(line: json)

        guard case .chat(let message) = result else {
            Issue.record("Expected chat message")
            return
        }
        #expect(message.role == .user)
    }

    // MARK: - Tool Use Tests

    @Test("Parse tool use returns tool use")
    func parseToolUse() throws {
        let json = """
        {"type":"tool_use","tool_name":"Read","tool_input":{"path":"/test"},"tool_use_id":"123"}
        """

        let result = try parser.parse(line: json)

        guard case .toolUse(let message) = result else {
            Issue.record("Expected tool use message, got \(result)")
            return
        }
        #expect(message.type == "tool_use")
        #expect(message.toolName == "Read")
        #expect(message.toolUseId == "123")
    }

    @Test("Parse tool use with nested input parses correctly")
    func parseToolUseNestedInput() throws {
        let json = """
        {"type":"tool_use","tool_name":"Bash","tool_input":{"command":"ls","options":{"all":true}},"tool_use_id":"456"}
        """

        let result = try parser.parse(line: json)

        guard case .toolUse(let message) = result else {
            Issue.record("Expected tool use message")
            return
        }
        #expect(message.toolName == "Bash")
        guard case .dictionary(let options) = message.toolInput["options"],
              case .bool(let all) = options["all"] else {
            Issue.record("Expected nested dictionary with bool")
            return
        }
        #expect(all == true)
    }

    // MARK: - Tool Result Tests

    @Test("Parse tool result returns tool result")
    func parseToolResult() throws {
        let json = """
        {"type":"tool_result","tool_use_id":"123","output":"Success","is_error":false}
        """

        let result = try parser.parse(line: json)

        guard case .toolResult(let message) = result else {
            Issue.record("Expected tool result message, got \(result)")
            return
        }
        #expect(message.type == "tool_result")
        #expect(message.toolUseId == "123")
        #expect(message.output == "Success")
        #expect(message.isError == false)
    }

    @Test("Parse tool result with error returns isError true")
    func parseToolResultError() throws {
        let json = """
        {"type":"tool_result","tool_use_id":"789","output":"File not found","is_error":true}
        """

        let result = try parser.parse(line: json)

        guard case .toolResult(let message) = result else {
            Issue.record("Expected tool result message")
            return
        }
        #expect(message.isError == true)
        #expect(message.output == "File not found")
    }

    // MARK: - AskUserQuestion Tests

    @Test("Parse AskUserQuestion returns askUser")
    func parseAskUserQuestion() throws {
        let json = """
        {"type":"tool_use","tool_name":"AskUserQuestion","tool_use_id":"ask123","tool_input":{"questions":[{"question":"Continue?","options":[{"label":"Yes"},{"label":"No"}],"multiSelect":false}]}}
        """

        let result = try parser.parse(line: json)

        guard case .askUser(let question) = result else {
            Issue.record("Expected ask user question, got \(result)")
            return
        }
        #expect(question.question == "Continue?")
        #expect(question.toolUseId == "ask123")
        #expect(question.multiSelect == false)
        #expect(question.options?.count == 2)
        #expect(question.options?[0].label == "Yes")
        #expect(question.options?[1].label == "No")
    }

    @Test("Parse AskUserQuestion with multiSelect returns multiSelect true")
    func parseAskUserQuestionMultiSelect() throws {
        let json = """
        {"type":"tool_use","tool_name":"AskUserQuestion","tool_use_id":"multi","tool_input":{"questions":[{"question":"Select options","options":[{"label":"A"},{"label":"B"}],"multiSelect":true}]}}
        """

        let result = try parser.parse(line: json)

        guard case .askUser(let question) = result else {
            Issue.record("Expected ask user question")
            return
        }
        #expect(question.multiSelect == true)
    }

    // MARK: - Unknown Type Tests

    @Test("Parse unknown type returns unknown")
    func parseUnknownType() throws {
        let json = """
        {"type":"new_future_type","data":"something"}
        """

        let result = try parser.parse(line: json)

        guard case .unknown(let rawJSON) = result else {
            Issue.record("Expected unknown message, got \(result)")
            return
        }
        #expect(rawJSON.contains("new_future_type"))
    }

    // MARK: - Defensive Parsing Tests

    @Test("Parse missing role defaults to assistant")
    func parseMissingRole() throws {
        let json = """
        {"type":"message","content":"No role specified"}
        """

        let result = try parser.parse(line: json)

        guard case .chat(let message) = result else {
            Issue.record("Expected chat message")
            return
        }
        #expect(message.role == .assistant)
    }

    @Test("Parse missing content defaults to empty string")
    func parseMissingContent() throws {
        let json = """
        {"type":"message","role":"assistant"}
        """

        let result = try parser.parse(line: json)

        guard case .chat(let message) = result else {
            Issue.record("Expected chat message")
            return
        }
        #expect(message.content == "")
    }

    @Test("Parse missing tool name defaults to unknown")
    func parseMissingToolName() throws {
        let json = """
        {"type":"tool_use","tool_use_id":"test"}
        """

        let result = try parser.parse(line: json)

        guard case .toolUse(let message) = result else {
            Issue.record("Expected tool use message")
            return
        }
        #expect(message.toolName == "unknown")
    }

    // MARK: - Error Tests

    @Test("Parse empty line throws emptyLine error")
    func parseEmptyLine() {
        #expect(throws: JSONLParserError.emptyLine) {
            try parser.parse(line: "")
        }
    }

    @Test("Parse whitespace only throws emptyLine error")
    func parseWhitespaceOnly() {
        #expect(throws: JSONLParserError.emptyLine) {
            try parser.parse(line: "   \n\t  ")
        }
    }

    @Test("Parse invalid JSON throws invalidJSON error")
    func parseInvalidJSON() {
        #expect {
            try parser.parse(line: "not a json")
        } throws: { error in
            guard let parserError = error as? JSONLParserError,
                  case .invalidJSON = parserError else {
                return false
            }
            return true
        }
    }
}

// MARK: - LineBuffer Tests

@Suite("LineBuffer Tests")
struct LineBufferTests {
    @Test("Extract complete lines")
    func extractCompleteLines() async {
        let buffer = LineBuffer()

        let lines1 = await buffer.append("hello\nworld")
        let lines2 = await buffer.append("\nfoo")
        let remaining = await buffer.flush()

        #expect(lines1 == ["hello"])
        #expect(lines2 == ["world"])
        #expect(remaining == "foo")
    }

    @Test("Handle partial lines")
    func handlePartialLines() async {
        let buffer = LineBuffer()

        let lines1 = await buffer.append("partial")
        let lines2 = await buffer.append(" line\n")

        #expect(lines1 == [])
        #expect(lines2 == ["partial line"])
    }
}
