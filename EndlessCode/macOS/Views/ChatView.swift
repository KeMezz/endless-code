//
//  ChatView.swift
//  EndlessCode
//
//  채팅 화면 뷰
//

import SwiftUI

// MARK: - ChatView

/// 채팅 화면 뷰
struct ChatView: View {
    let session: Session

    @Environment(AppState.self) private var appState
    @State private var viewModel: ChatViewModel

    init(session: Session) {
        self.session = session
        self._viewModel = State(initialValue: ChatViewModel(session: session))
    }

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            chatHeader

            Divider()

            // 메시지 목록
            messageListContent

            Divider()

            // 입력 영역
            MessageInputView(
                text: $viewModel.inputText,
                isLoading: viewModel.isLoading,
                canSend: viewModel.canSend,
                onSend: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }
            )
        }
        .task {
            await viewModel.loadMessages()
        }
        .accessibilityIdentifier("chatView-\(session.id)")
    }

    // MARK: - Subviews

    @ViewBuilder
    private var chatHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Session")
                    .font(.headline)

                Text(session.projectId)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            sessionStateBadge

            Menu {
                Button("Pause Session", systemImage: "pause.fill") {
                    // TODO(Section-3.4): Pause session - WebSocket을 통해 세션 일시정지 요청
                }
                .disabled(session.state != .active)

                Button("Resume Session", systemImage: "play.fill") {
                    // TODO(Section-3.4): Resume session - WebSocket을 통해 세션 재개 요청
                }
                .disabled(session.state != .paused)

                Divider()

                Button("End Session", systemImage: "xmark.circle", role: .destructive) {
                    // TODO(Section-3.4): End session - WebSocket을 통해 세션 종료 요청
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(width: 32)
            .accessibilityLabel("Session options")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityIdentifier("chatHeader")
    }

    @ViewBuilder
    private var sessionStateBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(stateColor)
                .frame(width: 8, height: 8)

            Text(session.state.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(stateColor.opacity(0.1))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var messageListContent: some View {
        Group {
            if viewModel.isLoading && viewModel.messages.isEmpty {
                loadingView
            } else if viewModel.messages.isEmpty {
                EmptyMessageList()
            } else {
                MessageList(
                    messages: viewModel.messages,
                    isStreaming: viewModel.isStreaming,
                    onCopyCode: { code in
                        copyToClipboard(code)
                    }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)

            Text("Loading messages...")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("chatLoadingView")
    }

    // MARK: - Computed Properties

    private var stateColor: Color {
        switch session.state {
        case .active: return .green
        case .paused: return .orange
        case .terminated: return .gray
        }
    }

    // MARK: - Helpers

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        appState.showToast("Copied to clipboard")
    }
}

// SessionState.displayName은 SessionListView.swift에서 정의됨

// MARK: - Preview

#Preview {
    ChatView(
        session: Session(
            id: "session-1",
            projectId: "project-1",
            state: .active
        )
    )
    .environment(AppState())
    .frame(width: 600, height: 500)
}
