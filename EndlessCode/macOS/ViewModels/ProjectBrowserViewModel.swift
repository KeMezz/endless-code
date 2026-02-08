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

// MARK: - Sample Data

extension Project {
    /// 샘플 프로젝트 데이터
    /// UI 테스트 모드에서는 샌드박스 내 테스트 디렉토리 사용
    static var sampleProjects: [Project] {
        let testProjectPath = setupTestProjectIfNeeded()

        return [
            Project(
                id: "project-1",
                name: "TestProject",
                path: testProjectPath,
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

    /// 테스트 프로젝트 디렉토리 설정
    /// UI 테스트 모드이거나, 홈 디렉토리 접근 불가 시 샌드박스 내 테스트 디렉토리 생성
    private static func setupTestProjectIfNeeded() -> String {
        let fileManager = FileManager.default

        // 앱의 Documents 디렉토리 (샌드박스 내)
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return fileManager.homeDirectoryForCurrentUser.path
        }

        let testProjectURL = documentsURL.appendingPathComponent("TestProject")

        // UI 테스트 모드 확인
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")

        // 테스트 프로젝트가 없거나 UI 테스트 모드면 생성
        if isUITesting || !fileManager.fileExists(atPath: testProjectURL.path) {
            createTestProjectStructure(at: testProjectURL)
        }

        return testProjectURL.path
    }

    /// 테스트용 프로젝트 구조 생성
    private static func createTestProjectStructure(at url: URL) {
        let fileManager = FileManager.default

        // 기존 디렉토리 삭제 후 재생성
        try? fileManager.removeItem(at: url)

        do {
            // 루트 디렉토리
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

            // src 폴더
            let srcURL = url.appendingPathComponent("src")
            try fileManager.createDirectory(at: srcURL, withIntermediateDirectories: true)

            // src/main.swift
            let mainSwiftContent = """
            import Foundation

            func main() {
                print("Hello, World!")
            }

            main()
            """
            try mainSwiftContent.write(
                to: srcURL.appendingPathComponent("main.swift"),
                atomically: true,
                encoding: .utf8
            )

            // src/utils.swift
            let utilsContent = """
            import Foundation

            struct Utils {
                static func formatDate(_ date: Date) -> String {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    return formatter.string(from: date)
                }
            }
            """
            try utilsContent.write(
                to: srcURL.appendingPathComponent("utils.swift"),
                atomically: true,
                encoding: .utf8
            )

            // tests 폴더
            let testsURL = url.appendingPathComponent("tests")
            try fileManager.createDirectory(at: testsURL, withIntermediateDirectories: true)

            // tests/test_main.swift
            let testContent = """
            import XCTest

            final class MainTests: XCTestCase {
                func testExample() {
                    XCTAssertTrue(true)
                }
            }
            """
            try testContent.write(
                to: testsURL.appendingPathComponent("test_main.swift"),
                atomically: true,
                encoding: .utf8
            )

            // README.md
            let readmeContent = """
            # TestProject

            This is a test project for E2E testing.

            ## Structure

            - `src/` - Source files
            - `tests/` - Test files
            """
            try readmeContent.write(
                to: url.appendingPathComponent("README.md"),
                atomically: true,
                encoding: .utf8
            )

            // config.json
            let configContent = """
            {
                "name": "TestProject",
                "version": "1.0.0",
                "debug": true
            }
            """
            try configContent.write(
                to: url.appendingPathComponent("config.json"),
                atomically: true,
                encoding: .utf8
            )

        } catch {
            print("Failed to create test project structure: \(error)")
        }
    }
}
