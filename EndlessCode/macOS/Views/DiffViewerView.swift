//
//  DiffViewerView.swift
//  EndlessCode
//
//  Diff 뷰어 메인 뷰
//  - 파일 목록 사이드바
//  - 통계 바
//  - Diff 콘텐츠 표시
//

import SwiftUI

// MARK: - DiffViewerView

/// Diff 뷰어 메인 뷰
struct DiffViewerView: View {
    @Bindable var viewModel: DiffViewerViewModel

    @State private var showFileList = true

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else if viewModel.diff != nil {
                diffContent
            } else {
                emptyView
            }
        }
        .accessibilityIdentifier("diffViewerView")
    }

    // MARK: - Main Content

    @ViewBuilder
    private var diffContent: some View {
        VStack(spacing: 0) {
            // 툴바
            toolbar

            Divider()

            // 통계 바
            if let statistics = viewModel.statistics {
                DiffStatisticsBar(statistics: statistics)
                Divider()
            }

            // 메인 콘텐츠
            HStack(spacing: 0) {
                // 파일 목록 사이드바
                if showFileList {
                    DiffFileList(
                        files: viewModel.sortedFiles,
                        selectedFileId: $viewModel.selectedFileId,
                        sortOption: viewModel.sortOption
                    )
                    .frame(width: 280)

                    Divider()
                }

                // Diff 콘텐츠
                mainDiffContent
            }

            // 페이지네이션 바 (필요 시)
            if viewModel.totalPages > 1 {
                paginationBar
            }
        }
    }

    @ViewBuilder
    private var mainDiffContent: some View {
        if let selectedFile = viewModel.selectedFile {
            ScrollView {
                DiffFileView(
                    file: selectedFile,
                    showSyntaxHighlighting: viewModel.showSyntaxHighlighting
                )
                .padding()
            }
            .frame(maxWidth: .infinity)
        } else {
            noFileSelectedView
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            // 파일 목록 토글
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showFileList.toggle()
                }
            } label: {
                Image(systemName: "sidebar.left")
                    .font(.body)
            }
            .buttonStyle(.plain)
            .help("Toggle file list")
            .accessibilityIdentifier("toggleFileListButton")

            Divider()
                .frame(height: 16)

            // 이전/다음 파일 네비게이션
            HStack(spacing: 4) {
                Button {
                    viewModel.selectPreviousFile()
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.sortedFiles.first?.id == viewModel.selectedFileId && !viewModel.hasPreviousPage)
                .help("Previous file")
                .accessibilityIdentifier("previousFileButton")

                Button {
                    viewModel.selectNextFile()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.sortedFiles.last?.id == viewModel.selectedFileId && !viewModel.hasNextPage)
                .help("Next file")
                .accessibilityIdentifier("nextFileButton")
            }

            Spacer()

            // 정렬 옵션
            sortMenu

            Divider()
                .frame(height: 16)

            // 신택스 하이라이팅 토글
            Button {
                viewModel.toggleSyntaxHighlighting()
            } label: {
                Image(systemName: viewModel.showSyntaxHighlighting ? "paintbrush.fill" : "paintbrush")
                    .font(.body)
            }
            .buttonStyle(.plain)
            .help(viewModel.showSyntaxHighlighting ? "Disable syntax highlighting" : "Enable syntax highlighting")
            .accessibilityIdentifier("syntaxHighlightingToggle")

            // staged 상태 표시
            if let isStaged = viewModel.diff?.isStaged {
                Divider()
                    .frame(height: 16)

                Text(isStaged ? "Staged" : "Unstaged")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isStaged ? .green : .orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((isStaged ? Color.green : Color.orange).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }

    private var sortMenu: some View {
        Menu {
            ForEach(DiffSortOption.allCases) { option in
                Button {
                    viewModel.setSortOption(option)
                } label: {
                    HStack {
                        Image(systemName: option.iconName)
                        Text(option.displayName)
                        if viewModel.sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.caption)
                Text("Sort")
                    .font(.caption)
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .accessibilityIdentifier("sortMenu")
    }

    // MARK: - Pagination

    private var paginationBar: some View {
        HStack {
            Button {
                viewModel.loadPreviousPage()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .font(.caption)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.hasPreviousPage)

            Spacer()

            Text("Page \(viewModel.currentPage + 1) of \(viewModel.totalPages)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                viewModel.loadNextPage()
            } label: {
                HStack(spacing: 4) {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
                .font(.caption)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.hasNextPage)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Parsing diff...")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)

            Text("Failed to parse diff")
                .font(.headline)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // 원본 텍스트 표시 옵션
            if let rawText = viewModel.rawDiffText {
                Divider()
                    .padding(.vertical)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Raw diff content:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ScrollView {
                        Text(rawText)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 300)
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("No diff to display")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Diff content will appear here when available")
                .font(.body)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noFileSelectedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("Select a file")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Choose a file from the list to view changes")
                .font(.body)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("Diff Viewer") {
    let viewModel = DiffViewerViewModel()

    let sampleDiff = """
    diff --git a/Sources/Example.swift b/Sources/Example.swift
    index abc123..def456 100644
    --- a/Sources/Example.swift
    +++ b/Sources/Example.swift
    @@ -1,5 +1,7 @@
     import Foundation

    -let oldValue = 42
    +let newValue = 100
    +let anotherValue = 200

     print("Done")
    """

    return DiffViewerView(viewModel: viewModel)
        .onAppear {
            viewModel.loadDiff(sampleDiff)
        }
        .frame(width: 900, height: 600)
}

#Preview("Diff Viewer - Empty") {
    DiffViewerView(viewModel: DiffViewerViewModel())
        .frame(width: 600, height: 400)
}

#Preview("Diff Viewer - Loading") {
    let viewModel = DiffViewerViewModel()

    return DiffViewerView(viewModel: viewModel)
        .onAppear {
            // 로딩 상태 시뮬레이션을 위해 내부 상태 조작 불가
            // Preview에서는 빈 상태 표시
        }
        .frame(width: 600, height: 400)
}
