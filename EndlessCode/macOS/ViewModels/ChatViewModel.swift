//
//  ChatViewModel.swift
//  EndlessCode
//
//  채팅 화면의 상태 관리
//

import Foundation

// MARK: - ChatServiceProtocol

/// 채팅 서비스 프로토콜 (의존성 주입용)
protocol ChatServiceProtocol: Sendable {
    func loadMessages(for session: Session) async throws -> [ChatMessageItem]
    func sendMessage(_ content: String, to session: Session) -> AsyncStream<ChatMessageItem>
}

// MARK: - DefaultChatService

/// 기본 채팅 서비스 (샘플 데이터 사용)
struct DefaultChatService: ChatServiceProtocol {
    func loadMessages(for session: Session) async throws -> [ChatMessageItem] {
        // 시뮬레이션 딜레이
        try? await Task.sleep(for: .milliseconds(500))
        return ChatMessageItem.sampleMessages
    }

    func sendMessage(_ content: String, to session: Session) -> AsyncStream<ChatMessageItem> {
        AsyncStream { continuation in
            Task {
                // 시뮬레이션 딜레이
                try? await Task.sleep(for: .seconds(1))

                let response = ChatMessageItem(
                    id: UUID().uuidString,
                    type: .assistant,
                    content: .text("This is a simulated response from Claude."),
                    timestamp: Date()
                )
                continuation.yield(response)
                continuation.finish()
            }
        }
    }
}

// MARK: - ChatViewModel

/// 채팅 화면의 상태를 관리하는 ViewModel
@Observable @MainActor
final class ChatViewModel {
    // MARK: - Properties

    let session: Session
    private let chatService: ChatServiceProtocol

    private(set) var messages: [ChatMessageItem] = []
    private(set) var isLoading = false
    private(set) var isStreaming = false
    private(set) var error: ChatError?

    var inputText = ""

    var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    // MARK: - Initialization

    init(session: Session, chatService: ChatServiceProtocol = DefaultChatService()) {
        self.session = session
        self.chatService = chatService
    }

    // MARK: - Actions

    func loadMessages() async {
        isLoading = true
        error = nil

        do {
            messages = try await chatService.loadMessages(for: session)
        } catch {
            self.error = .loadFailed
        }

        isLoading = false
    }

    func sendMessage() async {
        guard canSend else { return }

        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        inputText = ""

        // 사용자 메시지 추가
        let userMessage = ChatMessageItem(
            id: UUID().uuidString,
            type: .user,
            content: .text(content),
            timestamp: Date()
        )
        messages.append(userMessage)

        // 스트리밍 시작
        isStreaming = true

        // 서비스를 통해 메시지 전송 및 응답 수신
        for await response in chatService.sendMessage(content, to: session) {
            messages.append(response)
        }

        isStreaming = false
    }

    func clearError() {
        error = nil
    }
}

// MARK: - ChatMessageItem

/// 채팅 메시지 아이템 (UI 표시용)
struct ChatMessageItem: Identifiable, Equatable, Sendable {
    let id: String
    let type: MessageType
    let content: MessageContent
    let timestamp: Date

    enum MessageType: Equatable, Sendable {
        case user
        case assistant
        case toolUse(name: String, toolUseId: String)
        case toolResult(toolUseId: String, isError: Bool)
        case askUser(toolUseId: String, question: String, options: [QuestionOption]?)
    }

    enum MessageContent: Equatable, Sendable {
        case text(String)
        case streaming(String)
        case toolInput([String: AnyCodableValue])
        case toolOutput(String)
    }
}

// MARK: - ChatError

/// 채팅 에러 타입
enum ChatError: Error, Equatable {
    case connectionFailed
    case sendFailed
    case loadFailed
    case timeout
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
                Of course! I'd be happy to help you refactor your SwiftUI view. Here's a more modular approach:

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

                This separates the row into its own component for better reusability.
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
        ),
        ChatMessageItem(
            id: "msg-6",
            type: .toolUse(name: "Bash", toolUseId: "tool-2"),
            content: .toolInput([
                "command": .string("git diff")
            ]),
            timestamp: Date().addingTimeInterval(-50)
        ),
        ChatMessageItem(
            id: "msg-7",
            type: .toolResult(toolUseId: "tool-2", isError: false),
            content: .toolOutput("""
                diff --git a/Package.swift b/Package.swift
                index 9876543..fedcba9 100644
                --- a/Package.swift
                +++ b/Package.swift
                @@ -10,7 +10,8 @@ let package = Package(
                     dependencies: [
                         .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
                -        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
                +        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
                +        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0")
                     ],
                     targets: [
                         .target(
                diff --git a/Sources/Helpers/OldHelper.swift b/Sources/Helpers/OldHelper.swift
                deleted file mode 100644
                index 2468ace..0000000
                --- a/Sources/Helpers/OldHelper.swift
                +++ /dev/null
                @@ -1,8 +0,0 @@
                -//
                -//  OldHelper.swift
                -//  EndlessCode
                -//
                -
                -struct OldHelper {
                -    static func deprecatedMethod() {}
                -}
                diff --git a/Sources/Models/UserModel.swift b/Sources/Models/UserModel.swift
                index abc1234..def5678 100644
                --- a/Sources/Models/UserModel.swift
                +++ b/Sources/Models/UserModel.swift
                @@ -5,8 +5,10 @@

                 struct UserModel: Codable {
                     let id: String
                -    let name: String
                +    let username: String
                +    let email: String

                     var displayName: String {
                -        name
                +        username
                     }
                 }
                diff --git a/Sources/Views/ContentView.swift b/Sources/Views/ContentView.swift
                index 1234567..abcdefg 100644
                --- a/Sources/Views/ContentView.swift
                +++ b/Sources/Views/ContentView.swift
                @@ -1,5 +1,8 @@
                 struct ContentView: View {
                     @State private var items: [Item] = []
                +    @State private var isLoading = false
                +    @State private var errorMessage: String?

                     var body: some View {
                -        List(items) { item in
                +        Group {
                +            if let error = errorMessage {
                +                Text(error)
                +            } else {
                +                List(items) { item in
                +                    ItemRow(item: item)
                +                }
                +            }
                +        }
                     }
                 }
                diff --git a/Tests/ContentViewTests.swift b/Tests/ContentViewTests.swift
                new file mode 100644
                index 0000000..1a2b3c4
                --- /dev/null
                +++ b/Tests/ContentViewTests.swift
                @@ -0,0 +1,15 @@
                +//
                +//  ContentViewTests.swift
                +//  EndlessCodeTests
                +//
                +
                +import Testing
                +@testable import EndlessCode
                +
                +@Suite("ContentView Tests")
                +struct ContentViewTests {
                +    @Test("Error message is displayed when errorMessage is set")
                +    func errorMessageDisplayed() {
                +        // Test implementation
                +    }
                +}
                """),
            timestamp: Date().addingTimeInterval(-49)
        )
    ]
}
