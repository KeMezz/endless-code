import Foundation

// MARK: - Incoming Messages (from CLI stdout)

/// CLI에서 받는 모든 메시지의 기본 구조
public struct CLIMessage: Decodable, Sendable {
    public let type: MessageType
    public let subtype: String?
    public let uuid: String?

    public enum MessageType: String, Decodable, Sendable {
        case system
        case assistant
        case user
        case result
        case streamEvent = "stream_event"
    }
}

/// system init 메시지
public struct SystemInitMessage: Decodable, Sendable {
    public let type: String
    public let subtype: String
    public let cwd: String
    public let sessionId: String
    public let tools: [String]
    public let mcpServers: [MCPServer]?
    public let model: String
    public let claudeCodeVersion: String

    enum CodingKeys: String, CodingKey {
        case type, subtype, cwd, tools, model
        case sessionId = "session_id"
        case mcpServers = "mcp_servers"
        case claudeCodeVersion = "claude_code_version"
    }

    public struct MCPServer: Decodable, Sendable {
        public let name: String
        public let status: String
    }
}

/// assistant 메시지
public struct AssistantMessage: Decodable, Sendable {
    public let type: String
    public let message: MessageContent
    public let sessionId: String

    enum CodingKeys: String, CodingKey {
        case type, message
        case sessionId = "session_id"
    }

    public struct MessageContent: Decodable, Sendable {
        public let model: String
        public let id: String
        public let role: String
        public let content: [ContentBlock]
    }
}

/// content block (text 또는 tool_use)
public enum ContentBlock: Decodable, Sendable {
    case text(TextBlock)
    case toolUse(ToolUseBlock)
    case unknown

    public struct TextBlock: Decodable, Sendable {
        public let type: String
        public let text: String
    }

    public struct ToolUseBlock: Decodable, Sendable {
        public let type: String
        public let id: String
        public let name: String
        public let input: [String: AnyCodable]
    }

    enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text":
            let block = try TextBlock(from: decoder)
            self = .text(block)
        case "tool_use":
            let block = try ToolUseBlock(from: decoder)
            self = .toolUse(block)
        default:
            self = .unknown
        }
    }
}

/// result 메시지
public struct ResultMessage: Decodable, Sendable {
    public let type: String
    public let subtype: String
    public let isError: Bool
    public let durationMs: Int
    public let numTurns: Int
    public let result: String?
    public let sessionId: String
    public let totalCostUsd: Double?

    enum CodingKeys: String, CodingKey {
        case type, subtype, result
        case isError = "is_error"
        case durationMs = "duration_ms"
        case numTurns = "num_turns"
        case sessionId = "session_id"
        case totalCostUsd = "total_cost_usd"
    }
}

// MARK: - AskUserQuestion

/// AskUserQuestion tool input
public struct AskUserQuestionInput: Decodable, Sendable {
    public let questions: [Question]

    public struct Question: Decodable, Sendable {
        public let question: String
        public let header: String
        public let options: [Option]
        public let multiSelect: Bool
    }

    public struct Option: Decodable, Sendable {
        public let label: String
        public let description: String
    }
}

// MARK: - Outgoing Messages (to CLI stdin)

/// CLI에 보내는 사용자 메시지
public struct UserInputMessage: Encodable, Sendable {
    public let type: String = "user"
    public let message: Message

    public struct Message: Encodable, Sendable {
        public let role: String = "user"
        public let content: String
    }

    public init(content: String) {
        self.message = Message(content: content)
    }
}

/// AskUserQuestion 응답
public struct AskUserQuestionResponse: Encodable, Sendable {
    public let answers: [String: AnyCodable]

    public init(answers: [String: String]) {
        self.answers = answers.mapValues { AnyCodable($0) }
    }

    public init(answersArray: [String: [String]]) {
        self.answers = answersArray.mapValues { AnyCodable($0) }
    }
}

// MARK: - AnyCodable Helper

/// 동적 JSON 값을 처리하기 위한 타입
public struct AnyCodable: Codable, @unchecked Sendable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode value"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(codingPath: [], debugDescription: "Cannot encode value")
            )
        }
    }

    public var stringValue: String? { value as? String }
    public var intValue: Int? { value as? Int }
    public var boolValue: Bool? { value as? Bool }
    public var arrayValue: [Any]? { value as? [Any] }
    public var dictionaryValue: [String: Any]? { value as? [String: Any] }
}
