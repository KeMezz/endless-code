//
//  iOSSessionListView.swift
//  EndlessCode
//
//  iOS 세션 목록 뷰
//

#if os(iOS)
import SwiftUI

struct iOSSessionListView: View {
    @Environment(iOSAppState.self) private var appState
    let project: Project

    private var projectSessions: [Session] {
        appState.activeSessions.filter { $0.projectId == project.id }
    }

    var body: some View {
        ZStack {
            if projectSessions.isEmpty {
                emptyStateView
            } else {
                sessionList
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    createNewSession()
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Sessions")
                .font(.title2.bold())

            Text("Create a new session to start chatting")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Create Session") {
                createNewSession()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding()
    }

    // MARK: - Session List

    private var sessionList: some View {
        List {
            ForEach(projectSessions) { session in
                Button {
                    appState.selectSession(session)
                } label: {
                    SessionCard(session: session)
                }
                .accessibilityIdentifier("sessionRow-\(session.id)")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Methods

    private func createNewSession() {
        // 실제로는 서버에 새 세션 생성 요청
        appState.showToast("Session created")
    }
}

// MARK: - Session Card

private struct SessionCard: View {
    let session: Session

    var body: some View {
        HStack(spacing: 12) {
            // State Indicator
            Circle()
                .fill(stateColor)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Session \(session.id.prefix(8))")
                        .font(.headline)

                    Spacer()

                    Text(session.state.rawValue.capitalized)
                        .font(.caption.bold())
                        .foregroundStyle(stateColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(stateColor.opacity(0.2))
                        )
                }

                HStack {
                    Image(systemName: "message.fill")
                        .font(.caption2)

                    Text("\(session.messageCount) messages")
                        .font(.caption)

                    Spacer()

                    Image(systemName: "clock")
                        .font(.caption2)

                    Text(session.lastActiveAt, style: .relative)
                        .font(.caption)

                    Text("ago")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var stateColor: Color {
        switch session.state {
        case .active: return .green
        case .paused: return .orange
        case .terminated: return .red
        }
    }
}

// MARK: - Preview

#Preview("Session List") {
    NavigationStack {
        iOSSessionListView(
            project: Project(
                id: "proj-1",
                name: "DashboardApp",
                path: "/Users/demo/projects/DashboardApp",
                sessionCount: 2
            )
        )
        .environment(iOSAppState.preview)
        .preferredColorScheme(.dark)
    }
}

#Preview("Empty State") {
    NavigationStack {
        iOSSessionListView(
            project: Project(
                id: "proj-empty",
                name: "EmptyProject",
                path: "/Users/demo/projects/EmptyProject",
                sessionCount: 0
            )
        )
        .environment(iOSAppState())
        .preferredColorScheme(.dark)
    }
}
#endif
