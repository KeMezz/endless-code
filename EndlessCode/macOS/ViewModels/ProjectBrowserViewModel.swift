//
//  ProjectBrowserViewModel.swift
//  EndlessCode
//
//  프로젝트 브라우저 ViewModel
//

import Foundation

// MARK: - ProjectBrowserViewModel

/// 프로젝트 브라우저 ViewModel
@Observable @MainActor
final class ProjectBrowserViewModel {
    // MARK: - Properties

    /// 모든 프로젝트 목록
    private(set) var allProjects: [Project] = []

    /// 필터링된 프로젝트 목록
    var filteredProjects: [Project] {
        var result = allProjects

        // 검색어 필터링
        if !searchText.isEmpty {
            result = result.filter { project in
                project.name.localizedCaseInsensitiveContains(searchText) ||
                project.path.localizedCaseInsensitiveContains(searchText)
            }
        }

        // 정렬
        switch sortOrder {
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .recent:
            result.sort { ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast) }
        case .sessionCount:
            result.sort { $0.sessionCount > $1.sessionCount }
        }

        return result
    }

    /// 검색어
    var searchText: String = ""

    /// 정렬 순서
    var sortOrder: ProjectSortOrder = .recent

    /// 로딩 상태
    private(set) var isLoading: Bool = false

    /// 에러 메시지
    private(set) var error: String?

    // MARK: - Initialization

    init() {}

    // MARK: - Methods

    /// 프로젝트 목록 로드
    @MainActor
    func loadProjects() async {
        isLoading = true
        error = nil

        // TODO: 실제 프로젝트 발견 로직 연동
        // 임시로 샘플 데이터 사용
        allProjects = Project.sampleProjects

        isLoading = false
    }

    /// 프로젝트 새로고침
    @MainActor
    func refreshProjects() async {
        await loadProjects()
    }

    /// 검색어 지우기
    func clearSearch() {
        searchText = ""
    }
}

// MARK: - ProjectSortOrder

/// 프로젝트 정렬 순서
enum ProjectSortOrder: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case name = "Name"
    case sessionCount = "Sessions"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .recent:
            return "clock"
        case .name:
            return "textformat.abc"
        case .sessionCount:
            return "bubble.left.and.bubble.right"
        }
    }
}

// MARK: - Sample Data

extension Project {
    /// 샘플 프로젝트 데이터
    /// Note: 첫 번째 프로젝트는 홈 디렉토리를 사용하여 실제 파일 탐색 가능
    static var sampleProjects: [Project] {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            Project(
                id: "project-1",
                name: "Home",
                path: homeDir,
                sessionCount: 5,
                lastUsed: Date()
            ),
            Project(
                id: "project-2",
                name: "SwiftUI Demo",
                path: "/Users/user/projects/SwiftUI-Demo",
                sessionCount: 3,
                lastUsed: Date().addingTimeInterval(-3600)
            ),
            Project(
                id: "project-3",
                name: "API Server",
                path: "/Users/user/projects/api-server",
                sessionCount: 8,
                lastUsed: Date().addingTimeInterval(-7200)
            ),
            Project(
                id: "project-4",
                name: "Mobile App",
                path: "/Users/user/projects/mobile-app",
                sessionCount: 2,
                lastUsed: Date().addingTimeInterval(-86400)
            ),
        ]
    }
}
