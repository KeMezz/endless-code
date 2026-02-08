//
//  iOSChatModels.swift
//  EndlessCode
//
//  iOS용 채팅 메시지 모델 (macOS ChatModels.swift와 동일 구조)
//

#if os(iOS)
import Foundation

// MARK: - ChatMessageItem

/// 채팅 메시지 아이템 (UI 표시용)
struct ChatMessageItem: Identifiable, Equatable, Sendable, Codable {
    let id: String
    let type: MessageType
    let content: MessageContent
    let timestamp: Date

    enum MessageType: Equatable, Sendable, Codable {
        case user
        case assistant
        case toolUse(name: String, toolUseId: String)
        case toolResult(toolUseId: String, isError: Bool)
        case askUser(toolUseId: String, question: String, options: [QuestionOption]?, multiSelect: Bool)

        enum CodingKeys: String, CodingKey {
            case type, name, toolUseId, isError, question, options, multiSelect
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)

            switch type {
            case "user":
                self = .user
            case "assistant":
                self = .assistant
            case "toolUse":
                let name = try container.decode(String.self, forKey: .name)
                let toolUseId = try container.decode(String.self, forKey: .toolUseId)
                self = .toolUse(name: name, toolUseId: toolUseId)
            case "toolResult":
                let toolUseId = try container.decode(String.self, forKey: .toolUseId)
                let isError = try container.decode(Bool.self, forKey: .isError)
                self = .toolResult(toolUseId: toolUseId, isError: isError)
            case "askUser":
                let toolUseId = try container.decode(String.self, forKey: .toolUseId)
                let question = try container.decode(String.self, forKey: .question)
                let options = try container.decodeIfPresent([QuestionOption].self, forKey: .options)
                let multiSelect = try container.decode(Bool.self, forKey: .multiSelect)
                self = .askUser(toolUseId: toolUseId, question: question, options: options, multiSelect: multiSelect)
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown message type")
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .user:
                try container.encode("user", forKey: .type)
            case .assistant:
                try container.encode("assistant", forKey: .type)
            case .toolUse(let name, let toolUseId):
                try container.encode("toolUse", forKey: .type)
                try container.encode(name, forKey: .name)
                try container.encode(toolUseId, forKey: .toolUseId)
            case .toolResult(let toolUseId, let isError):
                try container.encode("toolResult", forKey: .type)
                try container.encode(toolUseId, forKey: .toolUseId)
                try container.encode(isError, forKey: .isError)
            case .askUser(let toolUseId, let question, let options, let multiSelect):
                try container.encode("askUser", forKey: .type)
                try container.encode(toolUseId, forKey: .toolUseId)
                try container.encode(question, forKey: .question)
                try container.encodeIfPresent(options, forKey: .options)
                try container.encode(multiSelect, forKey: .multiSelect)
            }
        }
    }

    enum MessageContent: Equatable, Sendable, Codable {
        case text(String)
        case streaming(String)
        case toolInput([String: AnyCodableValue])
        case toolOutput(String)

        enum CodingKeys: String, CodingKey {
            case type, value, dict
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)

            switch type {
            case "text":
                let value = try container.decode(String.self, forKey: .value)
                self = .text(value)
            case "streaming":
                let value = try container.decode(String.self, forKey: .value)
                self = .streaming(value)
            case "toolInput":
                let dict = try container.decode([String: AnyCodableValue].self, forKey: .dict)
                self = .toolInput(dict)
            case "toolOutput":
                let value = try container.decode(String.self, forKey: .value)
                self = .toolOutput(value)
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown content type")
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .text(let value):
                try container.encode("text", forKey: .type)
                try container.encode(value, forKey: .value)
            case .streaming(let value):
                try container.encode("streaming", forKey: .type)
                try container.encode(value, forKey: .value)
            case .toolInput(let dict):
                try container.encode("toolInput", forKey: .type)
                try container.encode(dict, forKey: .dict)
            case .toolOutput(let value):
                try container.encode("toolOutput", forKey: .type)
                try container.encode(value, forKey: .value)
            }
        }
    }
}

// MARK: - Sample Data

extension ChatMessageItem {
    static let sampleMessages: [ChatMessageItem] = [
        ChatMessageItem(
            id: "msg-1",
            type: .user,
            content: .text("Can you help me refactor this SwiftUI view?"),
            timestamp: Date().addingTimeInterval(-300)
        ),
        ChatMessageItem(
            id: "msg-2",
            type: .assistant,
            content: .text("""
Of course! I'd be happy to help you refactor your SwiftUI view.

## Recommended Approach

Here are the **key improvements** I suggest:

1. Extract the row into a *separate component*
2. Use `@State` for local state management
3. Add proper error handling

### Code Example

```swift
struct ContentView: View {
    @State private var items: [Item] = []

    var body: some View {
        List(items) { item in
            ItemRow(item: item)
        }
    }
}
```
"""),
            timestamp: Date().addingTimeInterval(-240)
        ),
        ChatMessageItem(
            id: "msg-3",
            type: .toolUse(name: "Read", toolUseId: "tool-1"),
            content: .toolInput([
                "file_path": .string("/Users/demo/project/ContentView.swift")
            ]),
            timestamp: Date().addingTimeInterval(-180)
        ),
        ChatMessageItem(
            id: "msg-4",
            type: .toolResult(toolUseId: "tool-1", isError: false),
            content: .toolOutput("File contents: struct ContentView: View { ... }"),
            timestamp: Date().addingTimeInterval(-179)
        ),
        ChatMessageItem(
            id: "msg-5",
            type: .user,
            content: .text("That looks great! Can you also add error handling?"),
            timestamp: Date().addingTimeInterval(-60)
        )
    ]
}
#endif
