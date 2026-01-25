//
//  ProjectDiscovery.swift
//  EndlessCode
//
//  프로젝트 검색 - ~/.claude/projects 디렉토리 스캔, 메타데이터 추출
//

import Foundation

// MARK: - ProjectDiscoveryProtocol

/// 프로젝트 검색 프로토콜
protocol ProjectDiscoveryProtocol: Sendable {
    func discoverProjects() async throws -> [Project]
    func projectInfo(for projectId: String) async throws -> Project?
    func validateProject(at path: String) async -> Bool
}

// MARK: - ProjectDiscovery

/// Claude 프로젝트를 검색하는 서비스
actor ProjectDiscovery: ProjectDiscoveryProtocol {
    private let claudeBasePath: String
    private let fileManager: FileManager

    /// 캐시된 프로젝트 목록
    private var cachedProjects: [String: Project] = [:]
    private var lastScanDate: Date?
    private let cacheDuration: TimeInterval = 60 // 1분 캐시

    init(claudeBasePath: String? = nil) {
        self.claudeBasePath = claudeBasePath ?? Self.defaultClaudeBasePath()
        self.fileManager = FileManager.default
    }

    private static func defaultClaudeBasePath() -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.claude"
    }

    // MARK: - Public API

    func discoverProjects() async throws -> [Project] {
        // 캐시 확인
        if let lastScan = lastScanDate,
           Date().timeIntervalSince(lastScan) < cacheDuration,
           !cachedProjects.isEmpty {
            return Array(cachedProjects.values).sorted { ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast) }
        }

        let projectsPath = "\(claudeBasePath)/projects"

        guard fileManager.fileExists(atPath: projectsPath) else {
            return []
        }

        var projects: [Project] = []

        // projects 디렉토리 내의 모든 항목 스캔
        let contents = try fileManager.contentsOfDirectory(atPath: projectsPath)

        for item in contents {
            let itemPath = "\(projectsPath)/\(item)"

            // 디렉토리인지 확인
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                continue
            }

            // 프로젝트 정보 추출
            if let project = await extractProjectInfo(from: itemPath, projectDirName: item) {
                projects.append(project)
                cachedProjects[project.id] = project
            }
        }

        lastScanDate = Date()

        // 최근 사용 순으로 정렬
        return projects.sorted { ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast) }
    }

    func projectInfo(for projectId: String) async throws -> Project? {
        // 캐시에서 먼저 확인
        if let cached = cachedProjects[projectId] {
            return cached
        }

        // 전체 스캔 후 확인
        _ = try await discoverProjects()
        return cachedProjects[projectId]
    }

    func validateProject(at path: String) async -> Bool {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            return false
        }

        // 디렉토리가 아니면 false
        guard isDirectory.boolValue else {
            return false
        }

        // 기본적인 유효성 검사: 읽기 권한이 있는지
        return fileManager.isReadableFile(atPath: path)
    }

    // MARK: - Private Methods

    private func extractProjectInfo(from projectDirPath: String, projectDirName: String) async -> Project? {
        // 프로젝트 디렉토리 이름에서 실제 경로 복원
        // Claude는 프로젝트 경로를 인코딩하여 디렉토리 이름으로 사용
        let originalPath = decodeProjectPath(from: projectDirName)

        // 세션 수 계산
        let sessionCount = countSessions(in: projectDirPath)

        // 마지막 사용 시간 계산
        let lastUsed = getLastModificationDate(of: projectDirPath)

        // 프로젝트 이름 추출
        let projectName = Project.nameFromPath(originalPath)

        return Project(
            id: projectDirName,
            name: projectName,
            path: originalPath,
            sessionCount: sessionCount,
            lastUsed: lastUsed
        )
    }

    private func decodeProjectPath(from encodedName: String) -> String {
        // Claude는 경로의 '/'를 '-'로 변환하고 앞에 '-'를 붙임
        // 예: /Users/foo/project -> -Users-foo-project
        var path = encodedName

        // 맨 앞의 '-' 제거
        if path.hasPrefix("-") {
            path = String(path.dropFirst())
        }

        // '-'를 '/'로 변환
        path = path.replacingOccurrences(of: "-", with: "/")

        // 맨 앞에 '/' 추가
        if !path.hasPrefix("/") {
            path = "/" + path
        }

        return path
    }

    private func countSessions(in projectDirPath: String) -> Int {
        // 세션 파일 (*.jsonl) 개수 카운트
        guard let contents = try? fileManager.contentsOfDirectory(atPath: projectDirPath) else {
            return 0
        }

        return contents.filter { $0.hasSuffix(".jsonl") }.count
    }

    private func getLastModificationDate(of path: String) -> Date? {
        guard let attributes = try? fileManager.attributesOfItem(atPath: path),
              let modDate = attributes[.modificationDate] as? Date else {
            return nil
        }
        return modDate
    }

    /// 캐시 무효화
    func invalidateCache() {
        cachedProjects.removeAll()
        lastScanDate = nil
    }
}

// MARK: - ProjectDiscoveryError

/// 프로젝트 검색 에러
enum ProjectDiscoveryError: Error, Sendable {
    case claudeDirectoryNotFound
    case projectNotFound(projectId: String)
    case accessDenied(path: String)
}

extension ProjectDiscoveryError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .claudeDirectoryNotFound:
            return "Claude 디렉토리를 찾을 수 없습니다 (~/.claude)"
        case .projectNotFound(let projectId):
            return "프로젝트를 찾을 수 없습니다: \(projectId)"
        case .accessDenied(let path):
            return "접근 권한이 없습니다: \(path)"
        }
    }
}
