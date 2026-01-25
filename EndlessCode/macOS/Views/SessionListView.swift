//
//  SessionListView.swift
//  EndlessCode
//
//  세션 목록 뷰
//

import SwiftUI

// MARK: - SessionListView

/// 세션 목록 뷰
struct SessionListView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = SessionListViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // 검색 및 필터 영역
            SessionSearchFilterBar(
                searchText: $viewModel.searchText,
                stateFilter: $viewModel.stateFilter,
                sortOrder: $viewModel.sortOrder,
                onClear: viewModel.clearSearch
            )
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // 세션 목록
            if viewModel.isLoading {
                SessionLoadingView()
            } else if viewModel.filteredSessions.isEmpty {
                EmptySessionsView(
                    hasFilters: !viewModel.searchText.isEmpty || viewModel.stateFilter != nil,
                    onClearFilters: viewModel.clearFilters
                )
            } else {
                SessionListContent(
                    sessions: viewModel.filteredSessions,
                    selectedSessionId: appState.selectedSession?.id,
                    onSelect: { session in
                        selectSession(session)
                    },
                    onPause: { session in
                        Task { await viewModel.pauseSession(session) }
                    },
                    onResume: { session in
                        Task { await viewModel.resumeSession(session) }
                    },
                    onTerminate: { session in
                        Task { await viewModel.terminateSession(session) }
                    }
                )
            }
        }
        .navigationTitle("Sessions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        await viewModel.refreshSessions()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh sessions")
            }
        }
        .task {
            await viewModel.loadSessions()
        }
        .refreshable {
            await viewModel.refreshSessions()
        }
    }

    private func selectSession(_ summary: SessionSummary) {
        // SessionSummary를 Session으로 변환
        let session = Session(
            id: summary.id,
            projectId: summary.projectId,
            state: summary.state,
            lastActiveAt: summary.lastActiveAt,
            messageCount: summary.messageCount
        )
        appState.selectSession(session)
    }
}

// MARK: - SessionSearchFilterBar

/// 세션 검색 및 필터 바
struct SessionSearchFilterBar: View {
    @Binding var searchText: String
    @Binding var stateFilter: SessionState?
    @Binding var sortOrder: SessionSortOrder
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 검색 필드
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search sessions...", text: $searchText)
                    .textFieldStyle(.plain)
                    .accessibilityIdentifier("sessionSearchField")

                if !searchText.isEmpty {
                    Button(action: onClear) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
            )

            // 상태 필터
            Menu {
                Button {
                    stateFilter = nil
                } label: {
                    if stateFilter == nil {
                        Label("All", systemImage: "checkmark")
                    } else {
                        Text("All")
                    }
                }

                Divider()

                ForEach([SessionState.active, .paused, .terminated], id: \.self) { state in
                    Button {
                        stateFilter = state
                    } label: {
                        if stateFilter == state {
                            Label(state.displayName, systemImage: "checkmark")
                        } else {
                            Text(state.displayName)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: stateFilter?.icon ?? "line.3.horizontal.decrease.circle")
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(stateFilter != nil ? .primary : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(stateFilter != nil ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.1))
                )
            }
            .menuStyle(.borderlessButton)
            .accessibilityIdentifier("sessionStateFilter")

            // 정렬 메뉴
            Menu {
                ForEach(SessionSortOrder.allCases) { order in
                    Button {
                        sortOrder = order
                    } label: {
                        Label(order.rawValue, systemImage: order.icon)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: sortOrder.icon)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                )
            }
            .menuStyle(.borderlessButton)
            .accessibilityIdentifier("sessionSortMenu")
        }
    }
}

// MARK: - SessionListContent

/// 세션 목록 콘텐츠
struct SessionListContent: View {
    let sessions: [SessionSummary]
    let selectedSessionId: String?
    let onSelect: (SessionSummary) -> Void
    var onPause: ((SessionSummary) -> Void)?
    var onResume: ((SessionSummary) -> Void)?
    var onTerminate: ((SessionSummary) -> Void)?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                // 활성 세션 섹션
                let activeSessions = sessions.filter { $0.state == .active }
                if !activeSessions.isEmpty {
                    SessionSection(
                        title: "Active",
                        sessions: activeSessions,
                        selectedSessionId: selectedSessionId,
                        onSelect: onSelect,
                        onPause: onPause,
                        onResume: onResume,
                        onTerminate: onTerminate
                    )
                }

                // 일시정지 세션 섹션
                let pausedSessions = sessions.filter { $0.state == .paused }
                if !pausedSessions.isEmpty {
                    SessionSection(
                        title: "Paused",
                        sessions: pausedSessions,
                        selectedSessionId: selectedSessionId,
                        onSelect: onSelect,
                        onPause: onPause,
                        onResume: onResume,
                        onTerminate: onTerminate
                    )
                }

                // 종료된 세션 섹션
                let terminatedSessions = sessions.filter { $0.state == .terminated }
                if !terminatedSessions.isEmpty {
                    SessionSection(
                        title: "Completed",
                        sessions: terminatedSessions,
                        selectedSessionId: selectedSessionId,
                        onSelect: onSelect,
                        onPause: onPause,
                        onResume: onResume,
                        onTerminate: onTerminate
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .accessibilityIdentifier("sessionList")
    }
}

// MARK: - SessionSection

/// 세션 섹션
struct SessionSection: View {
    let title: String
    let sessions: [SessionSummary]
    let selectedSessionId: String?
    let onSelect: (SessionSummary) -> Void
    var onPause: ((SessionSummary) -> Void)?
    var onResume: ((SessionSummary) -> Void)?
    var onTerminate: ((SessionSummary) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
                .padding(.top, 8)

            ForEach(sessions) { session in
                SessionCard(
                    session: session,
                    isSelected: session.id == selectedSessionId,
                    onTap: { onSelect(session) },
                    onPause: onPause != nil ? { onPause?(session) } : nil,
                    onResume: onResume != nil ? { onResume?(session) } : nil,
                    onTerminate: onTerminate != nil ? { onTerminate?(session) } : nil
                )
            }
        }
    }
}

// MARK: - SessionLoadingView

/// 세션 로딩 뷰
struct SessionLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading sessions...")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - EmptySessionsView

/// 빈 세션 뷰
struct EmptySessionsView: View {
    let hasFilters: Bool
    let onClearFilters: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasFilters ? "magnifyingglass" : "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            if hasFilters {
                Text("No sessions found")
                    .font(.headline)

                Text("Try adjusting your filters")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Button("Clear Filters") {
                    onClearFilters()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("No sessions")
                    .font(.headline)

                Text("Start a new session from a project to begin chatting with Claude")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 250)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - SessionState Extension

extension SessionState {
    var displayName: String {
        switch self {
        case .active:
            return "Active"
        case .paused:
            return "Paused"
        case .terminated:
            return "Completed"
        }
    }

    var icon: String {
        switch self {
        case .active:
            return "circle.fill"
        case .paused:
            return "pause.circle.fill"
        case .terminated:
            return "checkmark.circle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    SessionListView()
        .environment(AppState())
        .frame(width: 400, height: 600)
}
