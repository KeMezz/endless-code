//
//  SessionCard.swift
//  EndlessCode
//
//  세션 카드 컴포넌트
//

import SwiftUI

// MARK: - SessionCard

/// 세션 카드 컴포넌트
struct SessionCard: View {
    let session: SessionSummary
    let isSelected: Bool
    let onTap: () -> Void
    var onPause: (() -> Void)?
    var onResume: (() -> Void)?
    var onTerminate: (() -> Void)?

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 상태 인디케이터
                SessionStateIndicator(state: session.state)

                // 세션 정보
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(session.projectName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Spacer()

                        Text(relativeTimeText)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    if let lastMessage = session.lastMessage {
                        Text(lastMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else {
                        Text("No messages yet")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .italic()
                    }
                }

                // 메시지 수 뱃지
                if session.messageCount > 0 {
                    MessageCountBadge(count: session.messageCount)
                }

                // 화살표
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            sessionContextMenu
        }
        .accessibilityIdentifier("sessionCard-\(session.id)")
    }

    @ViewBuilder
    private var sessionContextMenu: some View {
        switch session.state {
        case .active:
            if let onPause = onPause {
                Button {
                    onPause()
                } label: {
                    Label("Pause Session", systemImage: "pause.circle")
                }
            }

            if let onTerminate = onTerminate {
                Divider()
                Button(role: .destructive) {
                    onTerminate()
                } label: {
                    Label("End Session", systemImage: "stop.circle")
                }
            }

        case .paused:
            if let onResume = onResume {
                Button {
                    onResume()
                } label: {
                    Label("Resume Session", systemImage: "play.circle")
                }
            }

            if let onTerminate = onTerminate {
                Divider()
                Button(role: .destructive) {
                    onTerminate()
                } label: {
                    Label("End Session", systemImage: "stop.circle")
                }
            }

        case .terminated:
            // 종료된 세션은 관리 액션 없음
            EmptyView()
        }
    }

    private var relativeTimeText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: session.lastActiveAt, relativeTo: Date())
    }
}

// MARK: - SessionStateIndicator

/// 세션 상태 인디케이터
struct SessionStateIndicator: View {
    let state: SessionState

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 36, height: 36)

            Image(systemName: iconName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(iconColor)
        }
    }

    private var iconName: String {
        switch state {
        case .active:
            return "bubble.left.and.bubble.right.fill"
        case .paused:
            return "pause.circle.fill"
        case .terminated:
            return "checkmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch state {
        case .active:
            return .green
        case .paused:
            return .orange
        case .terminated:
            return .gray
        }
    }

    private var backgroundColor: Color {
        iconColor.opacity(0.15)
    }
}

// MARK: - MessageCountBadge

/// 메시지 수 뱃지
struct MessageCountBadge: View {
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "text.bubble.fill")
                .font(.caption2)

            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.secondary.opacity(0.1))
        )
    }
}

// MARK: - SessionCardCompact

/// 컴팩트 세션 카드 (사이드바용)
struct SessionCardCompact: View {
    let session: SessionSummary
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            // 상태 점
            Circle()
                .fill(stateColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.projectName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(lastActiveText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if session.messageCount > 0 {
                Text("\(session.messageCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
    }

    private var stateColor: Color {
        switch session.state {
        case .active:
            return .green
        case .paused:
            return .orange
        case .terminated:
            return .gray
        }
    }

    private var lastActiveText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: session.lastActiveAt, relativeTo: Date())
    }
}

// MARK: - Sample Data

extension SessionSummary {
    /// 샘플 세션 데이터
    static var sampleSessions: [SessionSummary] {
        [
            SessionSummary(
                id: "session-1",
                projectId: "project-1",
                projectName: "EndlessCode",
                state: .active,
                lastMessage: "I've implemented the session management feature...",
                lastActiveAt: Date(),
                messageCount: 15
            ),
            SessionSummary(
                id: "session-2",
                projectId: "project-2",
                projectName: "SwiftUI Demo",
                state: .paused,
                lastMessage: "Let me check the animation code.",
                lastActiveAt: Date().addingTimeInterval(-1800),
                messageCount: 8
            ),
            SessionSummary(
                id: "session-3",
                projectId: "project-3",
                projectName: "API Server",
                state: .active,
                lastMessage: "The API endpoint is now working correctly.",
                lastActiveAt: Date().addingTimeInterval(-3600),
                messageCount: 23
            ),
            SessionSummary(
                id: "session-4",
                projectId: "project-1",
                projectName: "EndlessCode",
                state: .terminated,
                lastMessage: "Session completed successfully.",
                lastActiveAt: Date().addingTimeInterval(-86400),
                messageCount: 42
            ),
        ]
    }
}

// MARK: - Preview

#Preview("Session Card") {
    VStack(spacing: 8) {
        SessionCard(
            session: SessionSummary.sampleSessions[0],
            isSelected: false,
            onTap: {}
        )

        SessionCard(
            session: SessionSummary.sampleSessions[1],
            isSelected: true,
            onTap: {}
        )

        SessionCard(
            session: SessionSummary.sampleSessions[3],
            isSelected: false,
            onTap: {}
        )
    }
    .padding()
    .frame(width: 400)
}

#Preview("Session Card Compact") {
    VStack(spacing: 4) {
        ForEach(SessionSummary.sampleSessions) { session in
            SessionCardCompact(
                session: session,
                isSelected: session.id == "session-1"
            )
        }
    }
    .padding()
    .frame(width: 280)
}
