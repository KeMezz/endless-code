//
//  WebSocketMessage.swift
//  EndlessCode
//
//  WebSocket 메시지 타입 정의
//

import Foundation

// MARK: - Client → Server Messages

/// 클라이언트에서 서버로 보내는 메시지
enum ClientMessage: Sendable {
    case userMessage(UserMessage)
    case promptResponse(PromptResponse)
    case sessionControl(SessionControl)

    enum CodingKeys: String, CodingKey {
        case type
    }
}

extension ClientMessage: Codable {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "user_message":
            self = .userMessage(try UserMessage(from: decoder))
        case "prompt_response":
            self = .promptResponse(try PromptResponse(from: decoder))
        case "session_control":
            self = .sessionControl(try SessionControl(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown message type: \(type)"
            )
        }
    }

    nonisolated func encode(to encoder: Encoder) throws {
        switch self {
        case .userMessage(let message):
            try message.encode(to: encoder)
        case .promptResponse(let response):
            try response.encode(to: encoder)
        case .sessionControl(let control):
            try control.encode(to: encoder)
        }
    }
}

/// 사용자 메시지
struct UserMessage: Codable, Sendable {
    let type: String
    let sessionId: String
    let content: String
    let timestamp: Date

    nonisolated init(sessionId: String, content: String, timestamp: Date = Date()) {
        self.type = "user_message"
        self.sessionId = sessionId
        self.content = content
        self.timestamp = timestamp
    }
}

/// 프롬프트 응답
struct PromptResponse: Codable, Sendable {
    let type: String
    let sessionId: String
    let promptId: String
    let selectedOptions: [String]
    let customInput: String?

    nonisolated init(
        sessionId: String,
        promptId: String,
        selectedOptions: [String],
        customInput: String? = nil
    ) {
        self.type = "prompt_response"
        self.sessionId = sessionId
        self.promptId = promptId
        self.selectedOptions = selectedOptions
        self.customInput = customInput
    }
}

/// 세션 제어
struct SessionControl: Codable, Sendable {
    let type: String
    let action: SessionAction
    let sessionId: String?
    let projectId: String?

    nonisolated init(action: SessionAction, sessionId: String? = nil, projectId: String? = nil) {
        self.type = "session_control"
        self.action = action
        self.sessionId = sessionId
        self.projectId = projectId
    }
}

enum SessionAction: String, Codable, Sendable {
    case start
    case pause
    case resume
    case terminate
}

// MARK: - Server → Client Messages

/// 서버에서 클라이언트로 보내는 메시지
enum ServerMessage: Sendable {
    case cliOutput(CLIOutput)
    case sessionState(SessionStateMessage)
    case promptRequest(PromptRequest)
    case error(ErrorMessage)
    case sync(SyncMessage)

    enum CodingKeys: String, CodingKey {
        case type
    }
}

extension ServerMessage: Codable {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "cli_output":
            self = .cliOutput(try CLIOutput(from: decoder))
        case "session_state":
            self = .sessionState(try SessionStateMessage(from: decoder))
        case "prompt_request":
            self = .promptRequest(try PromptRequest(from: decoder))
        case "error":
            self = .error(try ErrorMessage(from: decoder))
        case "sync":
            self = .sync(try SyncMessage(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown message type: \(type)"
            )
        }
    }

    nonisolated func encode(to encoder: Encoder) throws {
        switch self {
        case .cliOutput(let output):
            try output.encode(to: encoder)
        case .sessionState(let state):
            try state.encode(to: encoder)
        case .promptRequest(let request):
            try request.encode(to: encoder)
        case .error(let error):
            try error.encode(to: encoder)
        case .sync(let sync):
            try sync.encode(to: encoder)
        }
    }
}

/// CLI 출력 메시지
struct CLIOutput: Codable, Sendable {
    let type: String
    let sessionId: String
    let message: ParsedMessageDTO
    let timestamp: Date

    nonisolated init(sessionId: String, message: ParsedMessage, timestamp: Date = Date()) {
        self.type = "cli_output"
        self.sessionId = sessionId
        self.message = ParsedMessageDTO(from: message)
        self.timestamp = timestamp
    }
}

/// 세션 상태 메시지
struct SessionStateMessage: Codable, Sendable {
    let type: String
    let sessionId: String
    let state: SessionState
    let error: String?

    nonisolated init(sessionId: String, state: SessionState, error: String? = nil) {
        self.type = "session_state"
        self.sessionId = sessionId
        self.state = state
        self.error = error
    }
}

/// 프롬프트 요청 메시지
struct PromptRequest: Codable, Sendable {
    let type: String
    let sessionId: String
    let promptId: String
    let question: AskUserQuestion
    let timeout: Int

    nonisolated init(
        sessionId: String,
        promptId: String,
        question: AskUserQuestion,
        timeout: Int = 1800
    ) {
        self.type = "prompt_request"
        self.sessionId = sessionId
        self.promptId = promptId
        self.question = question
        self.timeout = timeout
    }
}

/// 에러 메시지
struct ErrorMessage: Codable, Sendable {
    let type: String
    let code: String
    let message: String
    let sessionId: String?

    nonisolated init(code: String, message: String, sessionId: String? = nil) {
        self.type = "error"
        self.code = code
        self.message = message
        self.sessionId = sessionId
    }
}

/// 동기화 메시지
struct SyncMessage: Codable, Sendable {
    let type: String
    let sessions: [Session]
    let recentMessages: [ParsedMessageDTO]

    nonisolated init(sessions: [Session], recentMessages: [ParsedMessage]) {
        self.type = "sync"
        self.sessions = sessions
        self.recentMessages = recentMessages.map { ParsedMessageDTO(from: $0) }
    }
}

// MARK: - ParsedMessageDTO

/// ParsedMessage의 DTO (Codable 지원)
struct ParsedMessageDTO: Codable, Sendable {
    let messageType: String
    let chat: ChatMessage?
    let toolUse: ToolUseMessage?
    let toolResult: ToolResultMessage?
    let askUser: AskUserQuestion?
    let rawJSON: String?

    nonisolated init(from message: ParsedMessage) {
        switch message {
        case .chat(let chat):
            self.messageType = "chat"
            self.chat = chat
            self.toolUse = nil
            self.toolResult = nil
            self.askUser = nil
            self.rawJSON = nil
        case .toolUse(let toolUse):
            self.messageType = "tool_use"
            self.chat = nil
            self.toolUse = toolUse
            self.toolResult = nil
            self.askUser = nil
            self.rawJSON = nil
        case .toolResult(let toolResult):
            self.messageType = "tool_result"
            self.chat = nil
            self.toolUse = nil
            self.toolResult = toolResult
            self.askUser = nil
            self.rawJSON = nil
        case .askUser(let askUser):
            self.messageType = "ask_user"
            self.chat = nil
            self.toolUse = nil
            self.toolResult = nil
            self.askUser = askUser
            self.rawJSON = nil
        case .unknown(let raw):
            self.messageType = "unknown"
            self.chat = nil
            self.toolUse = nil
            self.toolResult = nil
            self.askUser = nil
            self.rawJSON = raw
        }
    }

    nonisolated func toParsedMessage() -> ParsedMessage {
        switch messageType {
        case "chat":
            if let chat = chat {
                return .chat(chat)
            }
        case "tool_use":
            if let toolUse = toolUse {
                return .toolUse(toolUse)
            }
        case "tool_result":
            if let toolResult = toolResult {
                return .toolResult(toolResult)
            }
        case "ask_user":
            if let askUser = askUser {
                return .askUser(askUser)
            }
        default:
            break
        }
        return .unknown(rawJSON: rawJSON ?? "")
    }
}

// MARK: - Error Codes

/// WebSocket 에러 코드
enum WebSocketErrorCode: String, Sendable {
    case cliNotFound = "CLI_NOT_FOUND"
    case cliCrashed = "CLI_CRASHED"
    case cliTimeout = "CLI_TIMEOUT"
    case sessionLimit = "SESSION_LIMIT"
    case authFailed = "AUTH_FAILED"
    case networkError = "NETWORK_ERROR"
    case parseError = "PARSE_ERROR"
    case invalidMessage = "INVALID_MESSAGE"
    case sessionNotFound = "SESSION_NOT_FOUND"
    case internalError = "INTERNAL_ERROR"
}
