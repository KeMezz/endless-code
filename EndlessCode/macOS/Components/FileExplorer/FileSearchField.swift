//
//  FileSearchField.swift
//  EndlessCode
//
//  파일 검색 필드 - 검색어 입력, 디바운싱, 결과 하이라이팅
//

import SwiftUI

// MARK: - FileSearchField

/// 파일 검색 필드
struct FileSearchField: View {
    @Binding var searchText: String
    let projectName: String
    var onSubmit: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search files in \(projectName)", text: $searchText)
                .textFieldStyle(.plain)
                .onSubmit {
                    onSubmit?()
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("clearSearchButton")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityIdentifier("fileSearchField")
    }
}

// MARK: - FileFilterChips

/// 파일 필터 칩 목록
struct FileFilterChips: View {
    @Binding var activeFilter: FileFilterOption
    let currentBranch: String
    let modifiedCount: Int
    let newCount: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 브랜치 칩
                BranchChip(branchName: currentBranch)

                // 필터 칩들
                ForEach(FileFilterOption.allCases) { filter in
                    FilterChip(
                        filter: filter,
                        isActive: activeFilter == filter,
                        count: countForFilter(filter),
                        onTap: {
                            activeFilter = filter
                        }
                    )
                }
            }
            .padding(.horizontal, 12)
        }
        .accessibilityIdentifier("fileFilterChips")
    }

    private func countForFilter(_ filter: FileFilterOption) -> Int? {
        switch filter {
        case .modified:
            return modifiedCount > 0 ? modifiedCount : nil
        case .new:
            return newCount > 0 ? newCount : nil
        default:
            return nil
        }
    }
}

// MARK: - BranchChip

/// 브랜치 칩
struct BranchChip: View {
    let branchName: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 10))
            Text(branchName)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.blue, in: Capsule())
        .foregroundStyle(.white)
        .accessibilityIdentifier("branchChip-\(branchName)")
    }
}

// MARK: - FilterChip

/// 필터 칩
struct FilterChip: View {
    let filter: FileFilterOption
    let isActive: Bool
    let count: Int?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: filter.iconName)
                    .font(.system(size: 10))

                Text(filter.rawValue)
                    .font(.system(size: 12, weight: .medium))

                if let count = count {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(badgeColor, in: Capsule())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isActive ? .gray.opacity(0.3) : .gray.opacity(0.1), in: Capsule())
            .foregroundStyle(isActive ? .primary : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("filterChip-\(filter.rawValue)")
    }

    private var badgeColor: Color {
        switch filter {
        case .modified:
            return .orange
        case .new:
            return .green
        default:
            return .gray
        }
    }
}

// MARK: - SearchResultsView

/// 검색 결과 뷰
struct SearchResultsView: View {
    let results: [FileSystemItem]
    let searchText: String
    let onSelect: (FileSystemItem) -> Void

    var body: some View {
        if results.isEmpty {
            emptyResultsView
        } else {
            resultsList
        }
    }

    private var emptyResultsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No results for \"\(searchText)\"")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(results) { item in
                    SearchResultRow(
                        item: item,
                        searchText: searchText,
                        onTap: {
                            onSelect(item)
                        }
                    )
                }
            }
        }
        .accessibilityIdentifier("searchResultsList")
    }
}

// MARK: - SearchResultRow

/// 검색 결과 행
struct SearchResultRow: View {
    let item: FileSystemItem
    let searchText: String
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                FileTypeIcon(item: item)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    // 파일명 (하이라이트)
                    highlightedText(item.name, searchText: searchText)
                        .font(.system(size: 13, weight: .medium))

                    // 경로
                    Text(item.path)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                }

                Spacer()

                // Git 상태
                if let status = item.gitStatus {
                    GitStatusBadge(status: status)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isHovered ? .gray.opacity(0.1) : .clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityIdentifier("searchResult-\(item.name)")
    }

    /// 검색어 하이라이트
    @ViewBuilder
    private func highlightedText(_ text: String, searchText: String) -> some View {
        let lowercasedText = text.lowercased()
        let lowercasedSearch = searchText.lowercased()

        if let range = lowercasedText.range(of: lowercasedSearch) {
            let startIndex = text.distance(from: text.startIndex, to: range.lowerBound)
            let length = searchText.count

            let before = String(text.prefix(startIndex))
            let match = String(text.dropFirst(startIndex).prefix(length))
            let after = String(text.dropFirst(startIndex + length))

            Text(before) + Text(match).foregroundStyle(.orange).bold() + Text(after)
        } else {
            Text(text)
        }
    }
}

// MARK: - Preview

#Preview("Search Field") {
    @Previewable @State var searchText = ""
    FileSearchField(searchText: $searchText, projectName: "EndlessCode")
        .padding()
}

#Preview("Filter Chips") {
    @Previewable @State var filter = FileFilterOption.all
    FileFilterChips(
        activeFilter: $filter,
        currentBranch: "main",
        modifiedCount: 3,
        newCount: 1
    )
    .padding()
}
