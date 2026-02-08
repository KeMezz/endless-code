//
//  FileExplorerViewModel.swift
//  EndlessCode
//
//  파일 탐색기 ViewModel - 파일 트리, 검색, 필터 관리
//

import Foundation
import SwiftUI

// MARK: - FileExplorerViewModel

/// 파일 탐색기 ViewModel
@Observable @MainActor
final class FileExplorerViewModel {
    // MARK: - Constants

    /// 최대 디렉토리 깊이
    static let maxDepth = 50

    /// 검색 디바운스 시간 (ms)
    static let searchDebounceMs: UInt64 = 300

    // MARK: - Properties

    /// 프로젝트 정보
    private(set) var project: Project

    /// 루트 디렉토리 아이템
    private(set) var rootItem: FileSystemItem?

    /// 확장된 폴더 ID 집합
    var expandedFolderIds: Set<String> = []

    /// 선택된 파일
    var selectedFile: FileSystemItem?

    /// 검색어
    var searchText: String = "" {
        didSet {
            debounceSearch()
        }
    }

    /// 활성 필터
    var activeFilter: FileFilterOption = .all

    /// 현재 브랜치 이름
    private(set) var currentBranch: String = "main"

    /// Git 상태 맵 (경로 -> 상태)
    private(set) var gitStatusMap: [String: GitFileStatus] = [:]

    /// 로딩 상태
    private(set) var isLoading = false

    /// 에러 메시지
    private(set) var errorMessage: String?

    /// 검색 결과
    private(set) var searchResults: [FileSystemItem] = []

    /// 검색 디바운스 태스크
    private var searchTask: Task<Void, Never>?

    /// 파일 시스템 서비스
    private let fileSystemService: FileSystemServiceProtocol

    /// Git 서비스
    private let gitService: GitServiceProtocol

    // MARK: - Computed Properties

    /// 필터링된 파일 목록
    var filteredItems: [FileSystemItem] {
        guard let root = rootItem else { return [] }
        return filterItems(root.children ?? [], filter: activeFilter)
    }

    /// 수정된 파일 수
    var modifiedFileCount: Int {
        gitStatusMap.values.filter { $0 == .modified }.count
    }

    /// 새로운 파일 수
    var newFileCount: Int {
        gitStatusMap.values.filter { $0 == .added || $0 == .untracked }.count
    }

    // MARK: - Initialization

    init(
        project: Project,
        fileSystemService: FileSystemServiceProtocol? = nil,
        gitService: GitServiceProtocol? = nil
    ) {
        self.project = project
        self.fileSystemService = fileSystemService ?? FileSystemService()
        self.gitService = gitService ?? GitService()
    }

    // MARK: - Public Methods

    /// 파일 트리 로드
    func loadFileTree() async {
        isLoading = true
        errorMessage = nil

        do {
            let rootPath = project.path
            rootItem = try await fileSystemService.loadDirectory(
                at: rootPath,
                maxDepth: 1
            )

            // Git 상태 로드
            await loadGitStatus()

            // 루트 폴더 기본 확장
            if let root = rootItem {
                expandedFolderIds.insert(root.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// 폴더 확장/축소 토글
    func toggleFolder(_ item: FileSystemItem) async {
        guard item.isDirectory else { return }

        if expandedFolderIds.contains(item.id) {
            // 축소
            expandedFolderIds.remove(item.id)
        } else {
            // 확장 - 자식 로드
            await expandFolder(item)
        }
    }

    /// ID로 현재 아이템 상태 조회
    func getItem(byId id: String) -> FileSystemItem? {
        guard let root = rootItem else { return nil }
        return findItem(in: root, withId: id)
    }

    /// 재귀적으로 아이템 찾기
    private func findItem(in item: FileSystemItem, withId id: String) -> FileSystemItem? {
        if item.id == id {
            return item
        }
        if let children = item.children {
            for child in children {
                if let found = findItem(in: child, withId: id) {
                    return found
                }
            }
        }
        return nil
    }

    /// 폴더 확장 (자식 로드)
    func expandFolder(_ item: FileSystemItem) async {
        guard item.isDirectory else { return }
        guard !expandedFolderIds.contains(item.id) else { return }

        // 깊이 체크
        let depth = item.depth
        if depth >= Self.maxDepth {
            errorMessage = "Maximum directory depth (\(Self.maxDepth)) exceeded"
            return
        }

        do {
            // 지연 로딩 - 자식만 로드
            let children = try await fileSystemService.loadDirectory(
                at: item.path,
                maxDepth: 1
            )

            // 루트 아이템 업데이트
            if var root = rootItem {
                updateChildren(in: &root, for: item.id, with: children.children ?? [])
                rootItem = root
            }

            // Git 상태 적용
            applyGitStatus()

            expandedFolderIds.insert(item.id)
        } catch {
            errorMessage = "Failed to load folder: \(error.localizedDescription)"
        }
    }

    /// 파일 선택
    func selectFile(_ item: FileSystemItem) {
        guard !item.isDirectory else { return }
        selectedFile = item
    }

    /// 검색 실행
    func performSearch() async {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }

        let query = searchText.lowercased()
        var results: [FileSystemItem] = []

        // 재귀적으로 검색
        if let root = rootItem {
            searchInItem(root, query: query, results: &results)
        }

        // Fuzzy 매칭 정렬 (매칭 점수 기준)
        searchResults = results.sorted { item1, item2 in
            let score1 = fuzzyMatchScore(item1.name.lowercased(), query: query)
            let score2 = fuzzyMatchScore(item2.name.lowercased(), query: query)
            return score1 > score2
        }
    }

    /// 필터 변경
    func setFilter(_ filter: FileFilterOption) {
        activeFilter = filter
    }

    /// Git 상태 새로고침
    func refreshGitStatus() async {
        await loadGitStatus()
        applyGitStatus()
    }

    // MARK: - Private Methods

    /// 검색 디바운스
    private func debounceSearch() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: Self.searchDebounceMs * 1_000_000)
            guard !Task.isCancelled else { return }
            await performSearch()
        }
    }

    /// Git 상태 로드
    private func loadGitStatus() async {
        do {
            let (branch, statuses) = try await gitService.getStatus(at: project.path)
            currentBranch = branch
            gitStatusMap = statuses
        } catch {
            // Git 상태 로드 실패는 무시 (Git 저장소가 아닐 수 있음)
            currentBranch = "main"
            gitStatusMap = [:]
        }
    }

    /// Git 상태 적용
    private func applyGitStatus() {
        guard var root = rootItem else { return }
        applyGitStatusRecursively(to: &root)
        rootItem = root
    }

    /// 재귀적으로 Git 상태 적용
    private func applyGitStatusRecursively(to item: inout FileSystemItem) {
        // 현재 아이템에 상태 적용
        if let status = gitStatusMap[item.path] {
            item.gitStatus = status
        }

        // 자식에 재귀 적용
        if var children = item.children {
            for index in children.indices {
                applyGitStatusRecursively(to: &children[index])
            }
            item.children = children
        }
    }

    /// 자식 업데이트
    private func updateChildren(
        in item: inout FileSystemItem,
        for targetId: String,
        with newChildren: [FileSystemItem]
    ) {
        if item.id == targetId {
            item.children = newChildren
            return
        }

        if var children = item.children {
            for index in children.indices {
                updateChildren(in: &children[index], for: targetId, with: newChildren)
            }
            item.children = children
        }
    }

    /// 필터링
    private func filterItems(_ items: [FileSystemItem], filter: FileFilterOption) -> [FileSystemItem] {
        switch filter {
        case .all:
            return items
        case .modified:
            return items.filter { item in
                if item.isDirectory {
                    return hasModifiedChildren(item)
                }
                return item.gitStatus == .modified
            }
        case .recent:
            // 최근 24시간 내 수정된 파일
            let oneDayAgo = Date().addingTimeInterval(-24 * 60 * 60)
            return items.filter { item in
                if let modDate = item.modificationDate {
                    return modDate > oneDayAgo
                }
                return false
            }
        case .new:
            return items.filter { item in
                if item.isDirectory {
                    return hasNewChildren(item)
                }
                return item.gitStatus == .added || item.gitStatus == .untracked
            }
        }
    }

    /// 수정된 자식이 있는지 확인 (깊이 제한 포함)
    private func hasModifiedChildren(_ item: FileSystemItem, depth: Int = 0) -> Bool {
        guard depth < Self.maxDepth else { return false }
        if item.gitStatus == .modified { return true }
        guard let children = item.children else { return false }
        return children.contains { hasModifiedChildren($0, depth: depth + 1) }
    }

    /// 새 자식이 있는지 확인 (깊이 제한 포함)
    private func hasNewChildren(_ item: FileSystemItem, depth: Int = 0) -> Bool {
        guard depth < Self.maxDepth else { return false }
        if item.gitStatus == .added || item.gitStatus == .untracked { return true }
        guard let children = item.children else { return false }
        return children.contains { hasNewChildren($0, depth: depth + 1) }
    }

    /// 아이템 내 검색
    private func searchInItem(
        _ item: FileSystemItem,
        query: String,
        results: inout [FileSystemItem]
    ) {
        // 파일명 매칭
        if item.name.lowercased().contains(query) || fuzzyMatch(item.name.lowercased(), query: query) {
            results.append(item)
        }

        // 자식 재귀 검색
        if let children = item.children {
            for child in children {
                searchInItem(child, query: query, results: &results)
            }
        }
    }

    /// Fuzzy 매칭 확인
    private func fuzzyMatch(_ text: String, query: String) -> Bool {
        var queryIndex = query.startIndex
        for char in text {
            if queryIndex < query.endIndex && char == query[queryIndex] {
                queryIndex = query.index(after: queryIndex)
            }
        }
        return queryIndex == query.endIndex
    }

    /// Fuzzy 매칭 점수 계산
    private func fuzzyMatchScore(_ text: String, query: String) -> Int {
        // 정확히 시작하면 높은 점수
        if text.hasPrefix(query) { return 100 }

        // 포함하면 중간 점수
        if text.contains(query) { return 50 }

        // Fuzzy 매칭이면 낮은 점수
        if fuzzyMatch(text, query: query) { return 25 }

        return 0
    }
}
