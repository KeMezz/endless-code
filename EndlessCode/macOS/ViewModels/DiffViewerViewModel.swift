//
//  DiffViewerViewModel.swift
//  EndlessCode
//
//  Diff 뷰어 ViewModel - Diff 데이터 관리 및 탐색
//

import Foundation
import SwiftUI

// MARK: - DiffViewerViewModel

/// Diff 뷰어 ViewModel
@Observable @MainActor
final class DiffViewerViewModel {
    // MARK: - Constants

    /// 페이지당 파일 수
    static let filesPerPage = 100

    // MARK: - Properties

    /// 현재 Diff 데이터
    private(set) var diff: UnifiedDiff?

    /// 선택된 파일 ID
    var selectedFileId: String?

    /// 정렬 옵션
    var sortOption: DiffSortOption = .path

    /// 신택스 하이라이팅 활성화
    var showSyntaxHighlighting = true

    /// 로딩 상태
    private(set) var isLoading = false

    /// 에러 메시지
    private(set) var errorMessage: String?

    /// 현재 페이지 (0-indexed)
    private(set) var currentPage = 0

    /// 총 페이지 수
    private(set) var totalPages = 1

    /// 원본 diff 문자열 (fallback용)
    private(set) var rawDiffText: String?

    /// Diff 파서
    private let parser: DiffParserProtocol

    /// 모든 파일 (페이지네이션 전)
    private var allFiles: [DiffFile] = []

    // MARK: - Computed Properties

    /// 현재 페이지의 파일 목록
    var files: [DiffFile] {
        diff?.files ?? []
    }

    /// 전체 통계
    var statistics: DiffStatistics? {
        guard let diff else { return nil }
        return DiffStatistics(from: diff)
    }

    /// 선택된 파일
    var selectedFile: DiffFile? {
        guard let id = selectedFileId else { return nil }
        return files.first { $0.id == id }
    }

    /// 정렬된 파일 목록
    var sortedFiles: [DiffFile] {
        switch sortOption {
        case .path:
            return files.sorted { $0.displayPath < $1.displayPath }
        case .changes:
            return files.sorted { ($0.additions + $0.deletions) > ($1.additions + $1.deletions) }
        case .status:
            return files.sorted { $0.fileStatus.rawValue < $1.fileStatus.rawValue }
        }
    }

    /// 다음 페이지 존재 여부
    var hasNextPage: Bool {
        currentPage < totalPages - 1
    }

    /// 이전 페이지 존재 여부
    var hasPreviousPage: Bool {
        currentPage > 0
    }

    // MARK: - Initialization

    init(parser: DiffParserProtocol = DiffParser()) {
        self.parser = parser
    }

    // MARK: - Public Methods

    /// Diff 문자열 로드 및 파싱
    func loadDiff(_ diffText: String, isStaged: Bool? = nil) {
        isLoading = true
        errorMessage = nil
        rawDiffText = diffText

        do {
            let parsedDiff = try parser.parse(diffText, isStaged: isStaged)
            allFiles = parsedDiff.files

            // 페이지네이션 계산
            totalPages = max(1, (allFiles.count + Self.filesPerPage - 1) / Self.filesPerPage)
            currentPage = 0

            // 첫 페이지 파일로 diff 생성
            let pageFiles = getPageFiles(page: 0)
            self.diff = UnifiedDiff(
                id: parsedDiff.id,
                files: pageFiles,
                isStaged: parsedDiff.isStaged,
                generatedAt: parsedDiff.generatedAt
            )

            // 첫 번째 파일 선택
            if let firstFile = pageFiles.first {
                selectedFileId = firstFile.id
            }
        } catch let error as DiffError {
            errorMessage = error.localizedDescription
            diff = nil
        } catch {
            errorMessage = "Failed to parse diff: \(error.localizedDescription)"
            diff = nil
        }

        isLoading = false
    }

    /// Diff 포함 여부 확인
    func containsDiff(_ text: String) -> Bool {
        parser.containsDiff(text)
    }

    /// 다음 페이지 로드
    func loadNextPage() {
        guard hasNextPage else { return }
        currentPage += 1
        updatePageFiles()
    }

    /// 이전 페이지 로드
    func loadPreviousPage() {
        guard hasPreviousPage else { return }
        currentPage -= 1
        updatePageFiles()
    }

    /// 특정 페이지 로드
    func loadPage(_ page: Int) {
        guard page >= 0 && page < totalPages else { return }
        currentPage = page
        updatePageFiles()
    }

    /// 파일 선택
    func selectFile(_ file: DiffFile) {
        selectedFileId = file.id
    }

    /// ID로 파일 선택
    func selectFile(byId id: String) {
        selectedFileId = id
    }

    /// 다음 파일로 이동
    func selectNextFile() {
        guard let currentId = selectedFileId,
              let currentIndex = sortedFiles.firstIndex(where: { $0.id == currentId }),
              currentIndex < sortedFiles.count - 1 else {
            // 다음 페이지의 첫 번째 파일
            if hasNextPage {
                loadNextPage()
                if let firstFile = sortedFiles.first {
                    selectedFileId = firstFile.id
                }
            }
            return
        }

        selectedFileId = sortedFiles[currentIndex + 1].id
    }

    /// 이전 파일로 이동
    func selectPreviousFile() {
        guard let currentId = selectedFileId,
              let currentIndex = sortedFiles.firstIndex(where: { $0.id == currentId }),
              currentIndex > 0 else {
            // 이전 페이지의 마지막 파일
            if hasPreviousPage {
                loadPreviousPage()
                if let lastFile = sortedFiles.last {
                    selectedFileId = lastFile.id
                }
            }
            return
        }

        selectedFileId = sortedFiles[currentIndex - 1].id
    }

    /// 정렬 변경
    func setSortOption(_ option: DiffSortOption) {
        sortOption = option
    }

    /// 신택스 하이라이팅 토글
    func toggleSyntaxHighlighting() {
        showSyntaxHighlighting.toggle()
    }

    /// Diff 초기화
    func clear() {
        diff = nil
        selectedFileId = nil
        allFiles = []
        currentPage = 0
        totalPages = 1
        errorMessage = nil
        rawDiffText = nil
    }

    // MARK: - Private Methods

    private func getPageFiles(page: Int) -> [DiffFile] {
        let start = page * Self.filesPerPage
        let end = min(start + Self.filesPerPage, allFiles.count)

        guard start < allFiles.count else { return [] }
        return Array(allFiles[start..<end])
    }

    private func updatePageFiles() {
        guard let oldDiff = diff else { return }

        let pageFiles = getPageFiles(page: currentPage)
        self.diff = UnifiedDiff(
            id: oldDiff.id,
            files: pageFiles,
            isStaged: oldDiff.isStaged,
            generatedAt: oldDiff.generatedAt
        )

        // 페이지 변경 시 첫 번째 파일 선택
        if let firstFile = pageFiles.first {
            selectedFileId = firstFile.id
        }
    }
}

// MARK: - Navigation Extension

extension DiffViewerViewModel {
    /// 다음 Hunk로 이동 (선택된 파일 내)
    func navigateToNextHunk() {
        // 현재는 파일 내 자동 스크롤 미지원
        // 향후 구현 시 Hunk 인덱스 추적 필요
    }

    /// 이전 Hunk로 이동 (선택된 파일 내)
    func navigateToPreviousHunk() {
        // 현재는 파일 내 자동 스크롤 미지원
        // 향후 구현 시 Hunk 인덱스 추적 필요
    }
}
