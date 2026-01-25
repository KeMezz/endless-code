//
//  SessionStore.swift
//  EndlessCode
//
//  세션 저장소 - CRUD, 메모리 캐시, 상태 관리
//

import Foundation

// MARK: - SessionStoreProtocol

/// 세션 저장소 프로토콜
protocol SessionStoreProtocol: Sendable {
    func createSession(projectId: String) async throws -> Session
    func getSession(id: String) async -> Session?
    func getSessions(projectId: String) async -> [Session]
    func getAllSessions() async -> [Session]
    func updateSession(_ session: Session) async throws
    func deleteSession(id: String) async throws
    func getActiveSessions() async -> [Session]
    func updateSessionState(id: String, state: SessionState) async throws
    func touchSession(id: String) async throws
    func incrementMessageCount(sessionId: String) async throws
    func cleanupOldSessions(olderThan date: Date) async
}

// MARK: - SessionStore

/// 세션을 관리하는 저장소 Actor
actor SessionStore: SessionStoreProtocol {
    private var sessions: [String: Session] = [:]
    private let projectDiscovery: ProjectDiscoveryProtocol

    init(projectDiscovery: ProjectDiscoveryProtocol) {
        self.projectDiscovery = projectDiscovery
    }

    // MARK: - CRUD Operations

    func createSession(projectId: String) async throws -> Session {
        // 프로젝트 유효성 확인
        guard let project = try await projectDiscovery.projectInfo(for: projectId) else {
            throw SessionStoreError.projectNotFound(projectId: projectId)
        }

        // 프로젝트 경로 유효성 확인
        guard await projectDiscovery.validateProject(at: project.path) else {
            throw SessionStoreError.invalidProjectPath(path: project.path)
        }

        let session = Session(
            projectId: projectId,
            state: .active
        )

        sessions[session.id] = session
        return session
    }

    func getSession(id: String) async -> Session? {
        sessions[id]
    }

    func getSessions(projectId: String) async -> [Session] {
        sessions.values
            .filter { $0.projectId == projectId }
            .sorted { $0.lastActiveAt > $1.lastActiveAt }
    }

    func getAllSessions() async -> [Session] {
        Array(sessions.values).sorted { $0.lastActiveAt > $1.lastActiveAt }
    }

    func updateSession(_ session: Session) async throws {
        guard sessions[session.id] != nil else {
            throw SessionStoreError.sessionNotFound(sessionId: session.id)
        }

        sessions[session.id] = session
    }

    func deleteSession(id: String) async throws {
        guard sessions[id] != nil else {
            throw SessionStoreError.sessionNotFound(sessionId: id)
        }

        sessions.removeValue(forKey: id)
    }

    func getActiveSessions() async -> [Session] {
        sessions.values
            .filter { $0.state == .active }
            .sorted { $0.lastActiveAt > $1.lastActiveAt }
    }

    // MARK: - State Management

    /// 세션 상태 변경
    func updateSessionState(id: String, state: SessionState) async throws {
        guard var session = sessions[id] else {
            throw SessionStoreError.sessionNotFound(sessionId: id)
        }

        session.state = state
        session.lastActiveAt = Date()
        sessions[id] = session
    }

    /// 세션 활동 시간 업데이트
    func touchSession(id: String) async throws {
        guard var session = sessions[id] else {
            throw SessionStoreError.sessionNotFound(sessionId: id)
        }

        session.lastActiveAt = Date()
        sessions[id] = session
    }

    /// 메시지 수 증가
    func incrementMessageCount(sessionId: String) async throws {
        guard var session = sessions[sessionId] else {
            throw SessionStoreError.sessionNotFound(sessionId: sessionId)
        }

        session.messageCount += 1
        session.lastActiveAt = Date()
        sessions[sessionId] = session
    }

    // MARK: - Bulk Operations

    /// 프로젝트의 모든 세션 삭제
    func deleteSessionsForProject(projectId: String) async {
        let sessionsToDelete = sessions.values.filter { $0.projectId == projectId }
        for session in sessionsToDelete {
            sessions.removeValue(forKey: session.id)
        }
    }

    /// 특정 상태의 세션 삭제
    func deleteSessionsWithState(_ state: SessionState) async {
        let sessionsToDelete = sessions.values.filter { $0.state == state }
        for session in sessionsToDelete {
            sessions.removeValue(forKey: session.id)
        }
    }

    /// 오래된 세션 정리
    func cleanupOldSessions(olderThan date: Date) async {
        let sessionsToDelete = sessions.values.filter { $0.lastActiveAt < date }
        for session in sessionsToDelete {
            sessions.removeValue(forKey: session.id)
        }
    }

    // MARK: - Statistics

    /// 세션 통계
    func statistics() async -> SessionStatistics {
        let allSessions = Array(sessions.values)
        let active = allSessions.filter { $0.state == .active }.count
        let paused = allSessions.filter { $0.state == .paused }.count
        let terminated = allSessions.filter { $0.state == .terminated }.count
        let totalMessages = allSessions.reduce(0) { $0 + $1.messageCount }

        return SessionStatistics(
            totalSessions: allSessions.count,
            activeSessions: active,
            pausedSessions: paused,
            terminatedSessions: terminated,
            totalMessages: totalMessages
        )
    }
}

// MARK: - SessionStatistics

/// 세션 통계 정보
struct SessionStatistics: Sendable, Equatable {
    let totalSessions: Int
    let activeSessions: Int
    let pausedSessions: Int
    let terminatedSessions: Int
    let totalMessages: Int
}

// MARK: - SessionStoreError

/// 세션 저장소 에러
enum SessionStoreError: Error, Sendable, Equatable {
    case projectNotFound(projectId: String)
    case invalidProjectPath(path: String)
    case sessionNotFound(sessionId: String)
    case sessionAlreadyExists(sessionId: String)
}

extension SessionStoreError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .projectNotFound(let projectId):
            return "프로젝트를 찾을 수 없습니다: \(projectId)"
        case .invalidProjectPath(let path):
            return "유효하지 않은 프로젝트 경로: \(path)"
        case .sessionNotFound(let sessionId):
            return "세션을 찾을 수 없습니다: \(sessionId)"
        case .sessionAlreadyExists(let sessionId):
            return "이미 존재하는 세션: \(sessionId)"
        }
    }
}
