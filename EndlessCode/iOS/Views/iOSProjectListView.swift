//
//  iOSProjectListView.swift
//  EndlessCode
//
//  iOS 프로젝트 목록 뷰
//

#if os(iOS)
import SwiftUI

struct iOSProjectListView: View {
    @Environment(iOSAppState.self) private var appState
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            ZStack {
                if appState.projects.isEmpty {
                    emptyStateView
                } else {
                    projectList
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    connectionIndicator
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Projects")
                .font(.title2.bold())

            Text("Connect to a server to see your projects")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Project List

    private var projectList: some View {
        List {
            ForEach(appState.projects) { project in
                NavigationLink {
                    iOSSessionListView(project: project)
                } label: {
                    ProjectCard(project: project)
                }
                .accessibilityIdentifier("projectRow-\(project.id)")
            }
        }
        .refreshable {
            await refreshProjects()
        }
        .listStyle(.insetGrouped)
        .accessibilityIdentifier("iosProjectListView")
    }

    // MARK: - Connection Indicator

    private var connectionIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(appState.connectionState == .connected ? .green : .red)
                .frame(width: 8, height: 8)

            Text(appState.connectionState == .connected ? "Connected" : "Disconnected")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Methods

    private func refreshProjects() async {
        isRefreshing = true
        // 실제로는 서버에서 프로젝트 목록을 가져옴
        try? await Task.sleep(for: .seconds(1))
        isRefreshing = false
    }
}

// MARK: - Project Card

private struct ProjectCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.blue)

                Text(project.name)
                    .font(.headline)

                Spacer()

                if project.sessionCount > 0 {
                    SessionCountBadge(count: project.sessionCount)
                }
            }

            Text(project.path)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if let lastUsed = project.lastUsed {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)

                    Text(lastUsed, style: .relative)
                        .font(.caption2)

                    Text("ago")
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Session Count Badge

private struct SessionCountBadge: View {
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.caption2)

            Text("\(count)")
                .font(.caption.bold())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.blue)
        )
    }
}

// MARK: - Preview

#Preview("Project List") {
    iOSProjectListView()
        .environment(iOSAppState.preview)
        .preferredColorScheme(.dark)
}

#Preview("Empty State") {
    iOSProjectListView()
        .environment(iOSAppState())
        .preferredColorScheme(.dark)
}
#endif
