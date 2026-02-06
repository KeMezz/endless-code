//
//  DiffFileView.swift
//  EndlessCode
//
//  단일 파일 Diff 뷰 및 파일 목록 컴포넌트
//

import SwiftUI

// MARK: - DiffFileView

/// 단일 파일의 Diff 전체 뷰
struct DiffFileView: View {
    let file: DiffFile
    let showSyntaxHighlighting: Bool

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 파일 헤더
            fileHeader

            if isExpanded {
                // Hunks
                if file.isBinary {
                    binaryFileContent
                } else {
                    fileContent
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .accessibilityIdentifier("diffFile-\(file.id)")
    }

    // MARK: - Subviews

    private var fileHeader: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                // 확장/축소 아이콘
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 12)

                // 파일 상태 아이콘
                Image(systemName: file.fileStatus.iconName)
                    .font(.caption)
                    .foregroundStyle(statusColor)

                // 파일 경로
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.displayPath)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    if file.fileStatus == .renamed,
                       let oldPath = file.oldPath {
                        Text("← \(oldPath)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // 파일 상태 뱃지
                statusBadge

                // 변경 통계
                statisticsView
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("diffFileHeader-\(file.id)")
    }

    @ViewBuilder
    private var statusBadge: some View {
        Text(file.fileStatus.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(statusColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var statisticsView: some View {
        HStack(spacing: 6) {
            if file.additions > 0 {
                HStack(spacing: 2) {
                    Text("+\(file.additions)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                }
            }
            if file.deletions > 0 {
                HStack(spacing: 2) {
                    Text("-\(file.deletions)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    @ViewBuilder
    private var fileContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(file.hunks) { hunk in
                DiffHunkView(
                    hunk: hunk,
                    fileExtension: file.fileExtension,
                    showSyntaxHighlighting: showSyntaxHighlighting
                )

                if hunk.id != file.hunks.last?.id {
                    Divider()
                        .padding(.vertical, 4)
                }
            }
        }
        .padding(.bottom, 8)
    }

    private var binaryFileContent: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.fill")
                .foregroundStyle(.secondary)
            Text("Binary file differs")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
    }

    // MARK: - Computed Properties

    private var statusColor: Color {
        switch file.fileStatus {
        case .added:
            return .green
        case .deleted:
            return .red
        case .modified:
            return .orange
        case .renamed:
            return .blue
        case .copied:
            return .purple
        }
    }
}

// MARK: - DiffFileListItem

/// 파일 목록의 단일 아이템 (사이드바용)
struct DiffFileListItem: View {
    let file: DiffFile
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                // 파일 상태 아이콘
                Image(systemName: file.fileStatus.iconName)
                    .font(.caption)
                    .foregroundStyle(statusColor)
                    .frame(width: 16)

                // 파일명
                Text(fileName)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                // 변경 통계
                HStack(spacing: 4) {
                    if file.additions > 0 {
                        Text("+\(file.additions)")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                    if file.deletions > 0 {
                        Text("-\(file.deletions)")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
                .fixedSize()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("diffFileListItem-\(file.id)")
    }

    private var fileName: String {
        (file.displayPath as NSString).lastPathComponent
    }

    private var statusColor: Color {
        switch file.fileStatus {
        case .added:
            return .green
        case .deleted:
            return .red
        case .modified:
            return .orange
        case .renamed:
            return .blue
        case .copied:
            return .purple
        }
    }
}

// MARK: - DiffFileList

/// Diff 파일 목록 (사이드바)
struct DiffFileList: View {
    let files: [DiffFile]
    @Binding var selectedFileId: String?
    let sortOption: DiffSortOption

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 헤더
            header

            Divider()

            // 파일 목록
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(sortedFiles) { file in
                        DiffFileListItem(
                            file: file,
                            isSelected: selectedFileId == file.id,
                            onSelect: { selectedFileId = file.id }
                        )
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
        }
        .accessibilityIdentifier("diffFileList")
    }

    private var header: some View {
        HStack {
            Text("Changed Files")
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(files.count)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var sortedFiles: [DiffFile] {
        switch sortOption {
        case .path:
            return files.sorted { $0.displayPath < $1.displayPath }
        case .changes:
            return files.sorted { ($0.additions + $0.deletions) > ($1.additions + $1.deletions) }
        case .status:
            return files.sorted { $0.fileStatus.rawValue < $1.fileStatus.rawValue }
        }
    }
}

// MARK: - DiffStatisticsBar

/// Diff 전체 통계 바
struct DiffStatisticsBar: View {
    let statistics: DiffStatistics

    var body: some View {
        HStack(spacing: 16) {
            // 파일 수
            statisticItem(
                icon: "doc.text",
                label: "Files",
                value: "\(statistics.totalFiles)"
            )

            Divider()
                .frame(height: 16)

            // 추가 라인
            statisticItem(
                icon: "plus",
                label: "Additions",
                value: "+\(statistics.totalAdditions)",
                color: .green
            )

            // 삭제 라인
            statisticItem(
                icon: "minus",
                label: "Deletions",
                value: "-\(statistics.totalDeletions)",
                color: .red
            )

            Spacer()

            // 변경 비율 바
            changeBar
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .accessibilityIdentifier("diffStatisticsBar")
    }

    private func statisticItem(
        icon: String,
        label: String,
        value: String,
        color: Color = .primary
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var changeBar: some View {
        GeometryReader { geometry in
            let total = CGFloat(statistics.totalChanges)
            let additionRatio = total > 0 ? CGFloat(statistics.totalAdditions) / total : 0.5

            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.green)
                    .frame(width: geometry.size.width * additionRatio)

                Rectangle()
                    .fill(Color.red)
                    .frame(width: geometry.size.width * (1 - additionRatio))
            }
            .clipShape(RoundedRectangle(cornerRadius: 2))
        }
        .frame(width: 100, height: 6)
    }
}

// MARK: - Preview

#Preview("Diff File View") {
    let sampleFile = DiffFile(
        oldPath: "Sources/Example.swift",
        newPath: "Sources/Example.swift",
        hunks: [
            DiffHunk(
                header: "@@ -1,5 +1,7 @@",
                oldStart: 1,
                oldCount: 5,
                newStart: 1,
                newCount: 7,
                contextText: "import Foundation",
                lines: [
                    DiffLine(type: .context, content: "import Foundation", oldLineNumber: 1, newLineNumber: 1),
                    DiffLine(type: .context, content: "", oldLineNumber: 2, newLineNumber: 2),
                    DiffLine(type: .deleted, content: "let oldValue = 42", oldLineNumber: 3, newLineNumber: nil),
                    DiffLine(type: .added, content: "let newValue = 100", oldLineNumber: nil, newLineNumber: 3),
                    DiffLine(type: .added, content: "let anotherValue = 200", oldLineNumber: nil, newLineNumber: 4),
                    DiffLine(type: .context, content: "", oldLineNumber: 4, newLineNumber: 5),
                    DiffLine(type: .context, content: "print(\"Done\")", oldLineNumber: 5, newLineNumber: 6),
                ]
            )
        ],
        isBinary: false,
        fileStatus: .modified
    )

    DiffFileView(file: sampleFile, showSyntaxHighlighting: true)
        .frame(width: 700)
        .padding()
}

#Preview("Diff File List") {
    let files = [
        DiffFile(oldPath: nil, newPath: "new-file.swift", hunks: [], fileStatus: .added),
        DiffFile(oldPath: "deleted.swift", newPath: nil, hunks: [], fileStatus: .deleted),
        DiffFile(oldPath: "modified.swift", newPath: "modified.swift", hunks: [], fileStatus: .modified),
    ]

    DiffFileList(
        files: files,
        selectedFileId: .constant(files[0].id),
        sortOption: .path
    )
    .frame(width: 250, height: 300)
}

#Preview("Statistics Bar") {
    let diff = UnifiedDiff(
        files: [
            DiffFile(oldPath: "a.swift", newPath: "a.swift", hunks: [
                DiffHunk(header: "@@", oldStart: 1, oldCount: 5, newStart: 1, newCount: 8, lines: [
                    DiffLine(type: .added, content: "1", oldLineNumber: nil, newLineNumber: 1),
                    DiffLine(type: .added, content: "2", oldLineNumber: nil, newLineNumber: 2),
                    DiffLine(type: .added, content: "3", oldLineNumber: nil, newLineNumber: 3),
                    DiffLine(type: .deleted, content: "old", oldLineNumber: 1, newLineNumber: nil),
                ])
            ], fileStatus: .modified),
            DiffFile(oldPath: nil, newPath: "b.swift", hunks: [], fileStatus: .added),
        ]
    )

    DiffStatisticsBar(statistics: DiffStatistics(from: diff))
        .frame(width: 500)
}
