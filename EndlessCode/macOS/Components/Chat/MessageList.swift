//
//  MessageList.swift
//  EndlessCode
//
//  채팅 메시지 목록 컴포넌트
//

import SwiftUI

// MARK: - MessageList

/// 채팅 메시지 목록 뷰
struct MessageList: View {
    let messages: [ChatMessageItem]
    let isStreaming: Bool
    let onCopyCode: ((String) -> Void)?

    @State private var scrollPosition: String?
    @State private var cachedGroups: [MessageGroup] = []

    init(
        messages: [ChatMessageItem],
        isStreaming: Bool = false,
        onCopyCode: ((String) -> Void)? = nil
    ) {
        self.messages = messages
        self.isStreaming = isStreaming
        self.onCopyCode = onCopyCode
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(cachedGroups) { group in
                        DateSeparator(date: group.date)
                            .id("date-\(group.id)")

                        ForEach(group.messages) { message in
                            MessageBubble(message: message, onCopyCode: onCopyCode)
                                .id(message.id)
                        }
                    }

                    if isStreaming {
                        streamingIndicator
                            .id("streaming")
                    }

                    // 하단 여백
                    Color.clear.frame(height: 16)
                        .id("bottom")
                }
                .padding(.top, 16)
            }
            .scrollPosition(id: $scrollPosition, anchor: .bottom)
            .onAppear {
                cachedGroups = computeGroupedMessages(messages)
            }
            .onChange(of: messages) { _, newMessages in
                cachedGroups = computeGroupedMessages(newMessages)
            }
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: isStreaming) { _, streaming in
                if streaming {
                    scrollToBottom(proxy: proxy)
                }
            }
        }
        .accessibilityIdentifier("messageList")
    }

    // MARK: - Subviews

    @ViewBuilder
    private var streamingIndicator: some View {
        HStack {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.purple.gradient)

                    Image(systemName: "sparkle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 32, height: 32)

                HStack(spacing: 4) {
                    Text("Claude is thinking")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    TypingIndicator()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Spacer()
        }
        .accessibilityIdentifier("streamingIndicator")
    }

    // MARK: - Helpers

    /// 메시지를 날짜별로 그룹화 (메모이제이션을 위한 별도 함수)
    private func computeGroupedMessages(_ messages: [ChatMessageItem]) -> [MessageGroup] {
        let calendar = Calendar.current
        var groups: [MessageGroup] = []
        var currentGroup: MessageGroup?

        for message in messages {
            let messageDay = calendar.startOfDay(for: message.timestamp)

            if let group = currentGroup, calendar.isDate(group.date, inSameDayAs: messageDay) {
                currentGroup?.messages.append(message)
            } else {
                if let group = currentGroup {
                    groups.append(group)
                }
                currentGroup = MessageGroup(date: messageDay, messages: [message])
            }
        }

        if let group = currentGroup {
            groups.append(group)
        }

        return groups
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            if isStreaming {
                proxy.scrollTo("streaming", anchor: .bottom)
            } else {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }
}

// MARK: - MessageGroup

/// 날짜별 메시지 그룹
struct MessageGroup: Identifiable {
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()

    let date: Date
    var messages: [ChatMessageItem]

    /// date 기반의 안정적인 ID (SwiftUI 재렌더링 최적화)
    var id: String {
        Self.dateFormatter.string(from: date)
    }
}

// MARK: - DateSeparator

/// 날짜 구분선
struct DateSeparator: View {
    let date: Date

    var body: some View {
        HStack {
            line
            Text(formattedDate)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
            line
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .accessibilityIdentifier("dateSeparator")
    }

    @ViewBuilder
    private var line: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.2))
            .frame(height: 1)
    }

    private var formattedDate: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}

// MARK: - EmptyMessageList

/// 빈 메시지 목록 뷰
struct EmptyMessageList: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("Start a conversation")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Text("Send a message to Claude to begin.")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("emptyMessageList")
    }
}

// MARK: - Preview

#Preview("Message List") {
    MessageList(
        messages: ChatMessageItem.sampleMessages,
        isStreaming: false
    )
    .frame(width: 600, height: 500)
}

#Preview("Streaming") {
    MessageList(
        messages: ChatMessageItem.sampleMessages,
        isStreaming: true
    )
    .frame(width: 600, height: 500)
}

#Preview("Empty") {
    EmptyMessageList()
        .frame(width: 600, height: 500)
}
