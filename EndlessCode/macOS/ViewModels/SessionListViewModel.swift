//
//  SessionListViewModel.swift
//  EndlessCode
//
//  세션 목록 ViewModel
//

import Foundation

// MARK: - SessionListViewModel

/// 세션 목록 ViewModel
@Observable @MainActor
final class SessionListViewModel {
    // MARK: - Properties

    /// 모든 세션 목록
    private(set) var allSessions: [SessionSummary] = []

    /// 필터링된 세션 목록
    var filteredSessions: [SessionSummary] {
        var result = allSessions

        // 상태 필터링
        if let stateFilter = stateFilter {
            result = result.filter { $0.state == stateFilter }
        }

        // 검색어 필터링
        if !searchText.isEmpty {
            result = result.filter { session in
                session.projectName.localizedCaseInsensitiveContains(searchText) ||
                (session.lastMessage?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // 정렬
        switch sortOrder {
        case .recent:
            result.sort { $0.lastActiveAt > $1.lastActiveAt }
        case .project:
            result.sort { $0.projectName.localizedCaseInsensitiveCompare($1.projectName) == .orderedAscending }
        case .messageCount:
            result.sort { $0.messageCount > $1.messageCount }
        }

        return result
    }

    /// 활성 세션 목록
    var activeSessions: [SessionSummary] {
        allSessions.filter { $0.state == .active }
    }

    /// 검색어
    var searchText: String = ""

    /// 상태 필터
    var stateFilter: SessionState?

    /// 정렬 순서
    var sortOrder: SessionSortOrder = .recent

    /// 로딩 상태
    private(set) var isLoading: Bool = false

    /// 에러 메시지
    private(set) var error: String?

    // MARK: - Initialization

    init() {}

    // MARK: - Methods

    /// 세션 목록 로드
    @MainActor
    func loadSessions() async {
        isLoading = true
        error = nil

        // TODO: 실제 세션 로드 로직 연동
        // 임시로 샘플 데이터 사용
        allSessions = SessionSummary.sampleSessions

        isLoading = false
    }

    /// 세션 새로고침
    @MainActor
    func refreshSessions() async {
        await loadSessions()
    }

    /// 검색어 지우기
    func clearSearch() {
        searchText = ""
    }

    /// 필터 초기화
    func clearFilters() {
        stateFilter = nil
        searchText = ""
        sortOrder = .recent
    }

    /// 세션 일시정지
    @MainActor
    func pauseSession(_ session: SessionSummary) async {
        // TODO: 실제 세션 일시정지 로직 연동
        guard let index = allSessions.firstIndex(where: { $0.id == session.id }) else { return }
        let oldSession = allSessions[index]

        // SessionSummary is immutable, so recreate with new state
        let updatedSession = SessionSummary(
            id: oldSession.id,
            projectId: oldSession.projectId,
            projectName: oldSession.projectName,
            state: .paused,
            lastMessage: oldSession.lastMessage,
            lastActiveAt: Date(),
            messageCount: oldSession.messageCount
        )
        allSessions[index] = updatedSession
    }

    /// 세션 재개
    @MainActor
    func resumeSession(_ session: SessionSummary) async {
        // TODO: 실제 세션 재개 로직 연동
        guard let index = allSessions.firstIndex(where: { $0.id == session.id }) else { return }
        let oldSession = allSessions[index]

        // SessionSummary is immutable, so recreate with new state
        let updatedSession = SessionSummary(
            id: oldSession.id,
            projectId: oldSession.projectId,
            projectName: oldSession.projectName,
            state: .active,
            lastMessage: oldSession.lastMessage,
            lastActiveAt: Date(),
            messageCount: oldSession.messageCount
        )
        allSessions[index] = updatedSession
    }

    /// 세션 종료
    @MainActor
    func terminateSession(_ session: SessionSummary) async {
        // TODO: 실제 세션 종료 로직 연동
        guard let index = allSessions.firstIndex(where: { $0.id == session.id }) else { return }
        let oldSession = allSessions[index]

        // SessionSummary is immutable, so recreate with new state
        let updatedSession = SessionSummary(
            id: oldSession.id,
            projectId: oldSession.projectId,
            projectName: oldSession.projectName,
            state: .terminated,
            lastMessage: oldSession.lastMessage,
            lastActiveAt: Date(),
            messageCount: oldSession.messageCount
        )
        allSessions[index] = updatedSession
    }
}

// MARK: - SessionSortOrder

/// 세션 정렬 순서
enum SessionSortOrder: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case project = "Project"
    case messageCount = "Messages"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .recent:
            return "clock"
        case .project:
            return "folder"
        case .messageCount:
            return "text.bubble"
        }
    }
}
