//
//  Message.swift
//  EndlessCode
//
//  공통 메시지 모델 정의
//

import Foundation

// MARK: - ParsedMessage

/// CLI 출력에서 파싱된 메시지 타입
enum ParsedMessage: Sendable, Equatable {
    case chat(ChatMessage)
    case toolUse(ToolUseMessage)
    case toolResult(ToolResultMessage)
    case askUser(AskUserQuestion)
    case unknown(rawJSON: String)
}

// MARK: - ChatMessage

/// 채팅 메시지 (사용자/어시스턴트)
struct ChatMessage: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let type: String
    let role: MessageRole
    let content: String
    let timestamp: Date

    nonisolated init(
        id: UUID = UUID(),
        type: String = "message",
        role: MessageRole,
        content: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - MessageRole

/// 메시지 역할
enum MessageRole: String, Codable, Sendable {
    case user
    case assistant
}

// MARK: - ToolUseMessage

/// 도구 사용 메시지
struct ToolUseMessage: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let type: String
    let toolName: String
    let toolInput: [String: AnyCodableValue]
    let toolUseId: String
    let timestamp: Date

    nonisolated init(
        id: UUID = UUID(),
        type: String = "tool_use",
        toolName: String,
        toolInput: [String: AnyCodableValue],
        toolUseId: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.toolName = toolName
        self.toolInput = toolInput
        self.toolUseId = toolUseId
        self.timestamp = timestamp
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case toolName = "tool_name"
        case toolInput = "tool_input"
        case toolUseId = "tool_use_id"
        case timestamp
    }
}

// MARK: - ToolResultMessage

/// 도구 실행 결과 메시지
struct ToolResultMessage: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let type: String
    let toolUseId: String
    let output: String
    let isError: Bool
    let timestamp: Date

    nonisolated init(
        id: UUID = UUID(),
        type: String = "tool_result",
        toolUseId: String,
        output: String,
        isError: Bool = false,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.toolUseId = toolUseId
        self.output = output
        self.isError = isError
        self.timestamp = timestamp
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case toolUseId = "tool_use_id"
        case output
        case isError = "is_error"
        case timestamp
    }
}

// MARK: - AskUserQuestion

/// 사용자에게 질문하는 대화형 프롬프트
struct AskUserQuestion: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let type: String
    let toolName: String
    let toolUseId: String
    let question: String
    let options: [QuestionOption]?
    let multiSelect: Bool
    let timestamp: Date

    nonisolated init(
        id: UUID = UUID(),
        type: String = "tool_use",
        toolName: String = "AskUserQuestion",
        toolUseId: String,
        question: String,
        options: [QuestionOption]? = nil,
        multiSelect: Bool = false,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.toolName = toolName
        self.toolUseId = toolUseId
        self.question = question
        self.options = options
        self.multiSelect = multiSelect
        self.timestamp = timestamp
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case toolName = "tool_name"
        case toolUseId = "tool_use_id"
        case question
        case options
        case multiSelect = "multi_select"
        case timestamp
    }
}

// MARK: - QuestionOption

/// 질문 선택 옵션
struct QuestionOption: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let label: String
    let description: String?

    nonisolated init(
        id: UUID = UUID(),
        label: String,
        description: String? = nil
    ) {
        self.id = id
        self.label = label
        self.description = description
    }
}

// MARK: - AnyCodableValue

/// 임의의 JSON 값을 저장하기 위한 타입
enum AnyCodableValue: Sendable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([AnyCodableValue])
    case dictionary([String: AnyCodableValue])
    case null
}

extension AnyCodableValue: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
            return
        }

        if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
            return
        }

        if let int = try? container.decode(Int.self) {
            self = .int(int)
            return
        }

        if let double = try? container.decode(Double.self) {
            self = .double(double)
            return
        }

        if let string = try? container.decode(String.self) {
            self = .string(string)
            return
        }

        if let array = try? container.decode([AnyCodableValue].self) {
            self = .array(array)
            return
        }

        if let dictionary = try? container.decode([String: AnyCodableValue].self) {
            self = .dictionary(dictionary)
            return
        }

        throw DecodingError.typeMismatch(
            AnyCodableValue.self,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Unable to decode AnyCodableValue"
            )
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}
