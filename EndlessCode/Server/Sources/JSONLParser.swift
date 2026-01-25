//
//  JSONLParser.swift
//  EndlessCode
//
//  JSONL 파싱 - 라인 버퍼링, 타입 분류, 방어적 파싱
//

import Foundation

// MARK: - JSONLParserProtocol

/// JSONL 파서 프로토콜
nonisolated protocol JSONLParserProtocol: Sendable {
    func parse(line: String) throws -> ParsedMessage
}

// MARK: - JSONLParser

/// Claude CLI JSONL 출력을 파싱하는 파서
struct JSONLParser: JSONLParserProtocol, Sendable {
    private let decoder: JSONDecoder

    nonisolated init() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    nonisolated func parse(line: String) throws -> ParsedMessage {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedLine.isEmpty else {
            throw JSONLParserError.emptyLine
        }

        guard let data = trimmedLine.data(using: .utf8) else {
            throw JSONLParserError.invalidEncoding
        }

        // 먼저 기본 타입 확인을 위해 딕셔너리로 파싱
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw JSONLParserError.invalidJSON(line: trimmedLine)
        }

        return try parseMessage(from: json, rawLine: trimmedLine, data: data)
    }

    nonisolated private func parseMessage(
        from json: [String: Any],
        rawLine: String,
        data: Data
    ) throws -> ParsedMessage {
        // type 필드 확인
        guard let type = json["type"] as? String else {
            return .unknown(rawJSON: rawLine)
        }

        switch type {
        case "message":
            return try parseChatMessage(from: data, rawLine: rawLine)

        case "tool_use":
            // AskUserQuestion 확인
            if let toolName = json["tool_name"] as? String,
               toolName == "AskUserQuestion" {
                return try parseAskUserQuestion(from: json, rawLine: rawLine)
            }
            return try parseToolUseMessage(from: data, rawLine: rawLine)

        case "tool_result":
            return try parseToolResultMessage(from: data, rawLine: rawLine)

        default:
            return .unknown(rawJSON: rawLine)
        }
    }

    nonisolated private func parseChatMessage(from data: Data, rawLine: String) throws -> ParsedMessage {
        do {
            let rawMessage = try decoder.decode(RawChatMessage.self, from: data)
            let message = ChatMessage(
                type: rawMessage.type,
                role: rawMessage.role ?? .assistant,
                content: rawMessage.content ?? "",
                timestamp: rawMessage.timestamp ?? Date()
            )
            return .chat(message)
        } catch {
            // 방어적 파싱: 필수 필드만으로 메시지 생성
            return parsePartialChatMessage(from: data, rawLine: rawLine)
        }
    }

    nonisolated private func parsePartialChatMessage(from data: Data, rawLine: String) -> ParsedMessage {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .unknown(rawJSON: rawLine)
        }

        let content = json["content"] as? String ?? ""
        let roleString = json["role"] as? String
        let role = roleString.flatMap { MessageRole(rawValue: $0) } ?? .assistant

        let message = ChatMessage(
            type: "message",
            role: role,
            content: content
        )
        return .chat(message)
    }

    nonisolated private func parseToolUseMessage(from data: Data, rawLine: String) throws -> ParsedMessage {
        do {
            let rawMessage = try decoder.decode(RawToolUseMessage.self, from: data)
            let message = ToolUseMessage(
                type: rawMessage.type,
                toolName: rawMessage.toolName ?? "unknown",
                toolInput: rawMessage.toolInput ?? [:],
                toolUseId: rawMessage.toolUseId ?? UUID().uuidString
            )
            return .toolUse(message)
        } catch {
            return parsePartialToolUseMessage(from: data, rawLine: rawLine)
        }
    }

    nonisolated private func parsePartialToolUseMessage(from data: Data, rawLine: String) -> ParsedMessage {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .unknown(rawJSON: rawLine)
        }

        let toolName = json["tool_name"] as? String ?? "unknown"
        let toolUseId = json["tool_use_id"] as? String ?? UUID().uuidString

        // tool_input 파싱
        var toolInput: [String: AnyCodableValue] = [:]
        if let rawInput = json["tool_input"] as? [String: Any] {
            toolInput = convertToAnyCodable(rawInput)
        }

        let message = ToolUseMessage(
            type: "tool_use",
            toolName: toolName,
            toolInput: toolInput,
            toolUseId: toolUseId
        )
        return .toolUse(message)
    }

    nonisolated private func parseToolResultMessage(from data: Data, rawLine: String) throws -> ParsedMessage {
        do {
            let rawMessage = try decoder.decode(RawToolResultMessage.self, from: data)
            let message = ToolResultMessage(
                type: rawMessage.type,
                toolUseId: rawMessage.toolUseId ?? "",
                output: rawMessage.output ?? "",
                isError: rawMessage.isError ?? false
            )
            return .toolResult(message)
        } catch {
            return parsePartialToolResultMessage(from: data, rawLine: rawLine)
        }
    }

    nonisolated private func parsePartialToolResultMessage(from data: Data, rawLine: String) -> ParsedMessage {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .unknown(rawJSON: rawLine)
        }

        let toolUseId = json["tool_use_id"] as? String ?? ""
        let output = json["output"] as? String ?? ""
        let isError = json["is_error"] as? Bool ?? false

        let message = ToolResultMessage(
            type: "tool_result",
            toolUseId: toolUseId,
            output: output,
            isError: isError
        )
        return .toolResult(message)
    }

    nonisolated private func parseAskUserQuestion(from json: [String: Any], rawLine: String) throws -> ParsedMessage {
        let toolUseId = json["tool_use_id"] as? String ?? UUID().uuidString

        // tool_input에서 질문 정보 추출
        guard let toolInput = json["tool_input"] as? [String: Any] else {
            return .unknown(rawJSON: rawLine)
        }

        // questions 배열에서 첫 번째 질문 추출
        var question = ""
        var options: [QuestionOption]?
        var multiSelect = false

        if let questions = toolInput["questions"] as? [[String: Any]],
           let firstQuestion = questions.first {
            question = firstQuestion["question"] as? String ?? ""
            multiSelect = firstQuestion["multiSelect"] as? Bool ?? false

            if let rawOptions = firstQuestion["options"] as? [[String: Any]] {
                options = rawOptions.map { opt in
                    QuestionOption(
                        label: opt["label"] as? String ?? "",
                        description: opt["description"] as? String
                    )
                }
            }
        }

        let askUser = AskUserQuestion(
            toolUseId: toolUseId,
            question: question,
            options: options,
            multiSelect: multiSelect
        )
        return .askUser(askUser)
    }

    nonisolated private func convertToAnyCodable(_ dict: [String: Any]) -> [String: AnyCodableValue] {
        var result: [String: AnyCodableValue] = [:]
        for (key, value) in dict {
            result[key] = convertValue(value)
        }
        return result
    }

    nonisolated private func convertValue(_ value: Any) -> AnyCodableValue {
        switch value {
        case let string as String:
            return .string(string)
        case let int as Int:
            return .int(int)
        case let double as Double:
            return .double(double)
        case let bool as Bool:
            return .bool(bool)
        case let array as [Any]:
            return .array(array.map { convertValue($0) })
        case let dict as [String: Any]:
            return .dictionary(convertToAnyCodable(dict))
        default:
            if value is NSNull {
                return .null
            }
            return .string(String(describing: value))
        }
    }
}

// MARK: - Raw Message Types (for decoding)

private struct RawChatMessage: Decodable {
    let type: String
    let role: MessageRole?
    let content: String?
    let timestamp: Date?
}

private struct RawToolUseMessage: Decodable {
    let type: String
    let toolName: String?
    let toolInput: [String: AnyCodableValue]?
    let toolUseId: String?
}

private struct RawToolResultMessage: Decodable {
    let type: String
    let toolUseId: String?
    let output: String?
    let isError: Bool?
}

// MARK: - JSONLParserError

/// JSONL 파싱 에러
enum JSONLParserError: Error, Sendable, Equatable {
    case emptyLine
    case invalidEncoding
    case invalidJSON(line: String)
    case missingRequiredField(field: String)
    case unknownMessageType(type: String)
}

extension JSONLParserError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .emptyLine:
            return "빈 라인"
        case .invalidEncoding:
            return "UTF-8 인코딩 실패"
        case .invalidJSON(let line):
            return "잘못된 JSON: \(line.prefix(100))"
        case .missingRequiredField(let field):
            return "필수 필드 누락: \(field)"
        case .unknownMessageType(let type):
            return "알 수 없는 메시지 타입: \(type)"
        }
    }
}

// MARK: - LineBuffer

/// 라인 버퍼링을 위한 헬퍼
actor LineBuffer {
    private var buffer: String = ""

    /// 데이터를 추가하고 완성된 라인들을 반환
    func append(_ data: String) -> [String] {
        buffer.append(data)
        return extractLines()
    }

    private func extractLines() -> [String] {
        var lines: [String] = []

        while let newlineIndex = buffer.firstIndex(of: "\n") {
            let line = String(buffer[..<newlineIndex])
            buffer = String(buffer[buffer.index(after: newlineIndex)...])

            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                lines.append(trimmed)
            }
        }

        return lines
    }

    /// 버퍼에 남은 데이터 반환 (스트림 종료 시)
    func flush() -> String? {
        let remaining = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        buffer = ""
        return remaining.isEmpty ? nil : remaining
    }
}
