//
//  iOSChatView.swift
//  EndlessCode
//
//  iOS 채팅 뷰 (모바일 최적화)
//

#if os(iOS)
import SwiftUI

struct iOSChatView: View {
    @Environment(iOSAppState.self) private var appState
    @State private var messageInput = ""
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if appState.selectedSession == nil {
                    emptyStateView
                } else {
                    messageListView
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
        }
    }

    // MARK: - Navigation Title

    private var navigationTitle: String {
        guard let session = appState.selectedSession else {
            return "Chat"
        }
        return "Session \(session.id.prefix(8))"
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Session Selected")
                .font(.title2.bold())

            Text("Select a session from the Projects tab to start chatting")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // MARK: - Message List View

    private var messageListView: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(appState.messages) { message in
                            MobileMessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: appState.messages.count) { _, _ in
                    // 새 메시지가 추가되면 하단으로 스크롤
                    if let lastMessage = appState.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .accessibilityIdentifier("iosChatView")

            Divider()

            MobileMessageInput(
                text: $messageInput,
                onSend: sendMessage
            )
        }
    }

    // MARK: - Methods

    private func sendMessage() {
        guard !messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        // 실제로는 서버로 메시지 전송
        let newMessage = ChatMessageItem(
            id: UUID().uuidString,
            type: .user,
            content: .text(messageInput),
            timestamp: Date()
        )

        appState.messages.append(newMessage)
        messageInput = ""

        // Mock: 어시스턴트 응답 시뮬레이션
        Task {
            try? await Task.sleep(for: .seconds(1))
            let response = ChatMessageItem(
                id: UUID().uuidString,
                type: .assistant,
                content: .text("This is a mock response to: \(newMessage.content)"),
                timestamp: Date()
            )
            appState.messages.append(response)
        }
    }
}

// MARK: - Preview

#Preview("Chat with Messages") {
    iOSChatView()
        .environment({
            let state = iOSAppState.preview
            state.selectedSession = state.activeSessions.first
            state.messages = ChatMessageItem.sampleMessages
            return state
        }())
        .preferredColorScheme(.dark)
}

#Preview("Empty State") {
    iOSChatView()
        .environment(iOSAppState())
        .preferredColorScheme(.dark)
}
#endif
