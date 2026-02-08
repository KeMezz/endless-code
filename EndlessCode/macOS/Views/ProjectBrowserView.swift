//
//  ProjectBrowserView.swift
//  EndlessCode
//
//  프로젝트 브라우저 뷰
//

import SwiftUI

// MARK: - ProjectBrowserView

/// 프로젝트 브라우저 뷰
struct ProjectBrowserView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ProjectBrowserViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // 검색 및 필터 영역
            SearchFilterBar(
                searchText: $viewModel.searchText,
                sortOrder: $viewModel.sortOrder,
                onClear: viewModel.clearSearch
            )
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // 프로젝트 목록
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.filteredProjects.isEmpty {
                EmptyProjectsView(
                    hasSearchText: !viewModel.searchText.isEmpty,
                    onClearSearch: viewModel.clearSearch
                )
            } else {
                ProjectListContent(
                    projects: viewModel.filteredProjects,
                    selectedProjectId: appState.selectedProject?.id,
                    onSelect: { project in
                        appState.selectProject(project)
                    }
                )
            }
        }
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        await viewModel.refreshProjects()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh projects")
            }
        }
        .task {
            await viewModel.loadProjects()
        }
        .refreshable {
            await viewModel.refreshProjects()
        }
    }
}

// MARK: - Preview

#Preview {
    ProjectBrowserView()
        .environment(AppState())
        .frame(width: 350, height: 500)
}
