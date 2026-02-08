//
//  ChatViewModel.swift
//  EndlessCode
//
//  채팅 화면의 상태 관리
//

import Foundation

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
