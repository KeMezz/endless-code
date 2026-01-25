//
//  FileTreeView.swift
//  EndlessCode
//
//  파일 트리 뷰 - OutlineGroup 기반 트리 구조
//

import SwiftUI

// MARK: - FileTreeView

/// 파일 트리 뷰
struct FileTreeView: View {
    @Bindable var viewModel: FileExplorerViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if let root = viewModel.rootItem {
                    ForEach(root.children ?? []) { item in
                        FileTreeItemView(
                            item: item,
                            viewModel: viewModel,
                            depth: 0
                        )
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .accessibilityIdentifier("fileTreeView")
    }
}

// MARK: - FileTreeItemView

/// 파일 트리 아이템 뷰 (재귀)
struct FileTreeItemView: View {
    let item: FileSystemItem
    @Bindable var viewModel: FileExplorerViewModel
    let depth: Int

    /// 성능 최적화를 위한 최대 표시 깊이
    /// 이 깊이를 초과하면 DepthLimitWarning을 표시하여 무한 렌더링 방지
    private static let maxDisplayDepth = 20

    /// 확장 상태
    private var isExpanded: Bool {
        viewModel.expandedFolderIds.contains(item.id)
    }

    /// 선택 상태
    private var isSelected: Bool {
        viewModel.selectedFile?.id == item.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 아이템 행
            FileItemRow(
                item: item,
                isExpanded: isExpanded,
                isSelected: isSelected,
                depth: depth,
                onToggle: {
                    Task {
                        await viewModel.toggleFolder(item)
                    }
                },
                onSelect: {
                    if item.isDirectory {
                        Task {
                            await viewModel.toggleFolder(item)
                        }
                    } else {
                        viewModel.selectFile(item)
                    }
                }
            )

            // 자식 (확장된 경우)
            if item.isDirectory && isExpanded {
                if depth < Self.maxDisplayDepth {
                    ForEach(item.children ?? []) { child in
                        FileTreeItemView(
                            item: child,
                            viewModel: viewModel,
                            depth: depth + 1
                        )
                    }
                } else {
                    // 깊이 제한 경고
                    DepthLimitWarning(depth: depth)
                        .padding(.leading, CGFloat((depth + 1) * 20 + 24))
                }
            }
        }
        .accessibilityIdentifier("fileTreeItem-\(item.name)")
    }
}

// MARK: - FileItemRow

/// 파일 아이템 행
struct FileItemRow: View {
    let item: FileSystemItem
    let isExpanded: Bool
    let isSelected: Bool
    let depth: Int
    let onToggle: () -> Void
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 4) {
            // 들여쓰기
            Spacer()
                .frame(width: CGFloat(depth * 20))

            // 확장/축소 버튼 (폴더만)
            if item.isDirectory {
                Button(action: onToggle) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("toggleButton-\(item.name)")
            } else {
                Spacer()
                    .frame(width: 16)
            }

            // 아이콘
            FileTypeIcon(item: item)
                .frame(width: 20, height: 20)

            // 파일명
            Text(item.name)
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? .white : .primary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            // Git 상태 뱃지
            if let status = item.gitStatus {
                GitStatusBadge(status: status)
            }

            // 심볼릭 링크 표시
            if item.isSymbolicLink {
                Image(systemName: "link")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(rowBackground)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityIdentifier("fileRow-\(item.name)")
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 4)
                .fill(.blue)
        } else if isHovered {
            RoundedRectangle(cornerRadius: 4)
                .fill(.gray.opacity(0.1))
        } else {
            Color.clear
        }
    }
}

// MARK: - FileTypeIcon

/// 파일 타입 아이콘
struct FileTypeIcon: View {
    let item: FileSystemItem

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 14))
            .foregroundStyle(iconColor)
    }

    private var iconName: String {
        if item.isDirectory {
            return "folder.fill"
        }
        return item.fileType.iconName
    }

    private var iconColor: Color {
        if item.isDirectory {
            return .blue
        }

        switch item.fileType {
        case .swift:
            return .orange
        case .javascript, .typescript:
            return .yellow
        case .python:
            return .green
        case .rust:
            return .orange
        case .go:
            return .cyan
        case .json, .yaml:
            return .purple
        case .markdown:
            return .blue
        case .html, .css:
            return .pink
        case .image:
            return .green
        default:
            return .secondary
        }
    }
}

// MARK: - GitStatusBadge

/// Git 상태 뱃지
struct GitStatusBadge: View {
    let status: GitFileStatus

    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(badgeColor, in: RoundedRectangle(cornerRadius: 3))
            .accessibilityIdentifier("gitBadge-\(status.rawValue)")
    }

    private var badgeColor: Color {
        switch status {
        case .modified:
            return .orange
        case .added:
            return .green
        case .deleted:
            return .red
        case .renamed, .copied:
            return .blue
        case .untracked:
            return .gray
        case .ignored:
            return .gray.opacity(0.5)
        case .unmerged:
            return .purple
        }
    }
}

// MARK: - DepthLimitWarning

/// 깊이 제한 경고
struct DepthLimitWarning: View {
    let depth: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text("Maximum depth reached (\(depth) levels)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    let viewModel = FileExplorerViewModel(
        project: Project(id: "1", name: "TestProject", path: "/tmp/test")
    )
    return FileTreeView(viewModel: viewModel)
        .frame(width: 300, height: 500)
}
