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

// MARK: - Preview

#Preview {
    SessionListView()
        .environment(AppState())
        .frame(width: 400, height: 600)
}
