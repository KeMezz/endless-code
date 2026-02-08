//
//  ChatService.swift
//  EndlessCode
//
//  채팅 메시지 송수신 서비스
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
