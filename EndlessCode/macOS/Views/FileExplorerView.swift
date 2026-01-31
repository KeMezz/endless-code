//
//  FileExplorerView.swift
//  EndlessCode
//
//  파일 탐색기 메인 뷰 - 검색, 필터, 트리, 뷰어 통합
//

import SwiftUI

// MARK: - FileExplorerView

/// 파일 탐색기 메인 뷰
struct FileExplorerView: View {
    let project: Project
    @State private var viewModel: FileExplorerViewModel

    init(project: Project) {
        self.project = project
        self._viewModel = State(initialValue: FileExplorerViewModel(project: project))
    }

    var body: some View {
        HSplitView {
            // 왼쪽: 파일 트리
            fileTreePanel
                .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)

            // 오른쪽: 파일 뷰어
            fileViewerPanel
        }
        .navigationTitle(project.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                toolbarItems
            }
        }
        .task {
            await viewModel.loadFileTree()
        }
        .accessibilityIdentifier("fileExplorerView")
    }

    // MARK: - File Tree Panel

    private var fileTreePanel: some View {
        VStack(spacing: 0) {
            // 헤더
            fileTreeHeader

            Divider()

            // 검색 필드
            FileSearchField(
                searchText: $viewModel.searchText,
                projectName: project.name
            )
            .padding(8)

            // 필터 칩
            FileFilterChips(
                activeFilter: $viewModel.activeFilter,
                currentBranch: viewModel.currentBranch,
                modifiedCount: viewModel.modifiedFileCount,
                newCount: viewModel.newFileCount
            )
            .padding(.bottom, 8)

            Divider()

            // 콘텐츠 (검색 결과 또는 트리)
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                // 에러 표시
                errorView(error)
            } else if !viewModel.searchText.isEmpty {
                // 검색 모드
                SearchResultsView(
                    results: viewModel.searchResults,
                    searchText: viewModel.searchText,
                    onSelect: { item in
                        viewModel.selectFile(item)
                    }
                )
            } else {
                // 트리 모드
                FileTreeView(viewModel: viewModel)
            }

            Divider()

            // 하단: 활성 경로
            activePathBar
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityIdentifier("fileTreePanel")
    }

    private var fileTreeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.headline)
                Text("PROJECT EXPLORER")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                // 설정 버튼 액션
            } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("explorerSettingsButton")
        }
        .padding(12)
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading files...")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.orange)

            Text("Failed to load files")
                .font(.headline)

            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry") {
                Task {
                    await viewModel.loadFileTree()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("fileTreeError")
    }

    private var activePathBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ACTIVE PATH")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(viewModel.selectedFile?.path ?? project.path)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.head)
            }

            Spacer()

            // 즐겨찾기 버튼
            Button {
                // 즐겨찾기 토글
            } label: {
                Image(systemName: "star")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("favoriteButton")

            // 새 파일 버튼
            Button {
                // 새 파일 생성
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("newFileButton")
        }
        .padding(12)
        .accessibilityIdentifier("activePathBar")
    }

    // MARK: - File Viewer Panel

    private var fileViewerPanel: some View {
        Group {
            if let selectedFile = viewModel.selectedFile {
                FileContentView(file: selectedFile)
            } else {
                emptyViewerPlaceholder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("fileViewerPanel")
    }

    private var emptyViewerPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Select a file to view")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Choose a file from the tree on the left\nto view its contents here.")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var toolbarItems: some View {
        // 새로고침 버튼
        Button {
            Task {
                await viewModel.loadFileTree()
            }
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .help("Refresh file tree")
        .accessibilityIdentifier("refreshButton")

        // Git 상태 새로고침
        Button {
            Task {
                await viewModel.refreshGitStatus()
            }
        } label: {
            Image(systemName: "arrow.triangle.branch")
        }
        .help("Refresh Git status")
        .accessibilityIdentifier("refreshGitButton")
    }
}

// MARK: - Preview

#Preview {
    let project = Project(
        id: "1",
        name: "EndlessCode",
        path: "/Users/hyeongjin/codes/personal/endless-code"
    )
    return NavigationStack {
        FileExplorerView(project: project)
    }
    .frame(width: 1000, height: 700)
}
