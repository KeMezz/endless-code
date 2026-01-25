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

// MARK: - SearchFilterBar

/// 검색 및 필터 바
struct SearchFilterBar: View {
    @Binding var searchText: String
    @Binding var sortOrder: ProjectSortOrder
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 검색 필드
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search projects...", text: $searchText)
                    .textFieldStyle(.plain)
                    .accessibilityIdentifier("projectSearchField")

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

            // 정렬 메뉴
            Menu {
                ForEach(ProjectSortOrder.allCases) { order in
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
            .accessibilityIdentifier("projectSortMenu")
        }
    }
}

// MARK: - ProjectListContent

/// 프로젝트 목록 콘텐츠
struct ProjectListContent: View {
    let projects: [Project]
    let selectedProjectId: String?
    let onSelect: (Project) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(projects) { project in
                    ProjectCard(
                        project: project,
                        isSelected: project.id == selectedProjectId,
                        onTap: { onSelect(project) }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .accessibilityIdentifier("projectList")
    }
}

// MARK: - LoadingView

/// 로딩 뷰
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading projects...")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - EmptyProjectsView

/// 빈 프로젝트 뷰
struct EmptyProjectsView: View {
    let hasSearchText: Bool
    let onClearSearch: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasSearchText ? "magnifyingglass" : "folder")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            if hasSearchText {
                Text("No projects found")
                    .font(.headline)

                Text("Try adjusting your search")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Button("Clear Search") {
                    onClearSearch()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("No projects")
                    .font(.headline)

                Text("Projects will appear here once you start using Claude Code")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 250)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    ProjectBrowserView()
        .environment(AppState())
        .frame(width: 350, height: 500)
}
