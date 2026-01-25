//
//  SessionManager.swift
//  EndlessCode
//
//  세션 관리자 - 세션 생명주기 관리, 프로젝트/세션 통합 관리
//

import Foundation

// MARK: - SessionManagerProtocol

/// 세션 관리자 프로토콜
protocol SessionManagerProtocol: Sendable {
    func listProjects() async throws -> [Project]
    func listSessions(projectId: String) async throws -> [Session]
    func getAllSessions() async -> [Session]
    func createSession(projectId: String) async throws -> Session
    func resumeSession(sessionId: String) async throws -> Session
    func pauseSession(sessionId: String) async throws
    func terminateSession(sessionId: String) async throws
    func sendMessage(sessionId: String, message: String) async throws
    func getSessionHistory(
        sessionId: String,
        projectId: String,
        limit: Int,
        offset: Int
    ) async throws -> SessionHistory
}

// MARK: - SessionManager

/// 세션 생명주기를 관리하는 중앙 관리자
actor SessionManager: SessionManagerProtocol {
    private let projectDiscovery: ProjectDiscovery
    private let sessionStore: SessionStore
    private let historyLoader: SessionHistoryLoader
    private let codeManager: ClaudeCodeManager

    /// 세션별 메시지 스트림 핸들러
    private var messageHandlers: [String: Task<Void, Never>] = [:]

    /// 세션 상태 변경 콜백
    private var sessionStateCallbacks: [(String, SessionState) -> Void] = []

    init(
        projectDiscovery: ProjectDiscovery,
        sessionStore: SessionStore,
        historyLoader: SessionHistoryLoader,
        codeManager: ClaudeCodeManager
    ) {
        self.projectDiscovery = projectDiscovery
        self.sessionStore = sessionStore
        self.historyLoader = historyLoader
        self.codeManager = codeManager
    }

    // MARK: - Project Operations

    func listProjects() async throws -> [Project] {
        try await projectDiscovery.discoverProjects()
    }

    func getProject(id: String) async throws -> Project? {
        try await projectDiscovery.projectInfo(for: id)
    }

    // MARK: - Session Operations

    func listSessions(projectId: String) async throws -> [Session] {
        await sessionStore.getSessions(projectId: projectId)
    }

    func getAllSessions() async -> [Session] {
        await sessionStore.getAllSessions()
    }

    func getSession(id: String) async -> Session? {
        await sessionStore.getSession(id: id)
    }

    func createSession(projectId: String) async throws -> Session {
        // 세션 생성
        let session = try await sessionStore.createSession(projectId: projectId)

        // 프로젝트 정보 가져오기
        guard let project = try await projectDiscovery.projectInfo(for: projectId) else {
            throw SessionManagerError.projectNotFound(projectId: projectId)
        }

        // CLI 프로세스 시작
        let messageStream = try await codeManager.startSession(
            sessionId: session.id,
            projectPath: project.path
        )

        // 메시지 핸들러 시작
        startMessageHandler(sessionId: session.id, stream: messageStream)

        return session
    }

    func resumeSession(sessionId: String) async throws -> Session {
        guard let session = await sessionStore.getSession(id: sessionId) else {
            throw SessionManagerError.sessionNotFound(sessionId: sessionId)
        }

        // 이미 활성 상태인지 확인
        if session.state == .active {
            return session
        }

        // CLI 프로세스 재개
        let messageStream = try await codeManager.resumeSession(sessionId: sessionId)

        // 상태 업데이트
        try await sessionStore.updateSessionState(id: sessionId, state: .active)

        // 메시지 핸들러 재시작
        startMessageHandler(sessionId: sessionId, stream: messageStream)

        guard let updatedSession = await sessionStore.getSession(id: sessionId) else {
            throw SessionManagerError.sessionNotFound(sessionId: sessionId)
        }

        return updatedSession
    }

    func pauseSession(sessionId: String) async throws {
        guard await sessionStore.getSession(id: sessionId) != nil else {
            throw SessionManagerError.sessionNotFound(sessionId: sessionId)
        }

        // 메시지 핸들러 중지
        stopMessageHandler(sessionId: sessionId)

        // 상태 업데이트
        try await sessionStore.updateSessionState(id: sessionId, state: .paused)

        notifyStateChange(sessionId: sessionId, state: .paused)
    }

    func terminateSession(sessionId: String) async throws {
        guard await sessionStore.getSession(id: sessionId) != nil else {
            throw SessionManagerError.sessionNotFound(sessionId: sessionId)
        }

        // CLI 프로세스 종료
        try await codeManager.terminateSession(sessionId: sessionId)

        // 메시지 핸들러 중지
        stopMessageHandler(sessionId: sessionId)

        // 상태 업데이트
        try await sessionStore.updateSessionState(id: sessionId, state: .terminated)

        notifyStateChange(sessionId: sessionId, state: .terminated)
    }

    // MARK: - Message Operations

    func sendMessage(sessionId: String, message: String) async throws {
        guard let session = await sessionStore.getSession(id: sessionId) else {
            throw SessionManagerError.sessionNotFound(sessionId: sessionId)
        }

        guard session.state == .active else {
            throw SessionManagerError.sessionNotActive(sessionId: sessionId)
        }

        try await codeManager.sendMessage(sessionId: sessionId, message: message)
        try await sessionStore.incrementMessageCount(sessionId: sessionId)
    }

    func getSessionHistory(
        sessionId: String,
        projectId: String,
        limit: Int = 1000,
        offset: Int = 0
    ) async throws -> SessionHistory {
        try await historyLoader.loadHistory(
            sessionId: sessionId,
            projectId: projectId,
            limit: limit,
            offset: offset
        )
    }

    // MARK: - State Callbacks

    func onSessionStateChange(_ callback: @escaping (String, SessionState) -> Void) {
        sessionStateCallbacks.append(callback)
    }

    private func notifyStateChange(sessionId: String, state: SessionState) {
        for callback in sessionStateCallbacks {
            callback(sessionId, state)
        }
    }

    // MARK: - Message Handlers

    private func startMessageHandler(sessionId: String, stream: AsyncStream<ParsedMessage>) {
        // 기존 핸들러가 있으면 중지
        stopMessageHandler(sessionId: sessionId)

        let task = Task { [weak self] in
            for await message in stream {
                await self?.handleMessage(sessionId: sessionId, message: message)
            }

            // 스트림 종료 시 세션 상태 확인
            await self?.handleStreamEnd(sessionId: sessionId)
        }

        messageHandlers[sessionId] = task
    }

    private func stopMessageHandler(sessionId: String) {
        if let task = messageHandlers[sessionId] {
            task.cancel()
            messageHandlers.removeValue(forKey: sessionId)
        }
    }

    private func handleMessage(sessionId: String, message: ParsedMessage) async {
        // 세션 활동 시간 업데이트
        do {
            try await sessionStore.touchSession(id: sessionId)
        } catch {
            // touchSession 실패는 치명적이지 않으나 디버깅을 위해 로깅
            print("⚠️ 세션 활동 시간 업데이트 실패: \(sessionId) - \(error.localizedDescription)")
        }

        // TODO: WebSocket을 통해 클라이언트에 메시지 전달
        // 이 부분은 WebSocketHandler에서 구현
    }

    private func handleStreamEnd(sessionId: String) async {
        // CLI 프로세스가 종료된 경우
        if let state = await codeManager.sessionState(sessionId: sessionId) {
            if case .terminated = state.processState {
                try? await sessionStore.updateSessionState(id: sessionId, state: .terminated)
                notifyStateChange(sessionId: sessionId, state: .terminated)
            }
        }
    }

    // MARK: - Cleanup

    func cleanupIdleSessions(timeout: TimeInterval) async {
        let cutoffDate = Date().addingTimeInterval(-timeout)
        await sessionStore.cleanupOldSessions(olderThan: cutoffDate)
        await codeManager.cleanupIdleSessions(olderThan: timeout)
    }

    func terminateAllSessions() async {
        let sessions = await sessionStore.getAllSessions()
        for session in sessions {
            try? await terminateSession(sessionId: session.id)
        }
    }
}

// MARK: - SessionManagerError

/// 세션 관리자 에러
enum SessionManagerError: Error, Sendable, Equatable {
    case projectNotFound(projectId: String)
    case sessionNotFound(sessionId: String)
    case sessionNotActive(sessionId: String)
    case sessionAlreadyActive(sessionId: String)
}

extension SessionManagerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .projectNotFound(let projectId):
            return "프로젝트를 찾을 수 없습니다: \(projectId)"
        case .sessionNotFound(let sessionId):
            return "세션을 찾을 수 없습니다: \(sessionId)"
        case .sessionNotActive(let sessionId):
            return "세션이 활성 상태가 아닙니다: \(sessionId)"
        case .sessionAlreadyActive(let sessionId):
            return "세션이 이미 활성 상태입니다: \(sessionId)"
        }
    }
}

// MARK: - Factory

extension SessionManager {
    /// 기본 구성으로 SessionManager 생성
    static func createDefault(configuration: ServerConfiguration = .fromEnvironment()) -> SessionManager {
        let projectDiscovery = ProjectDiscovery()
        let sessionStore = SessionStore(projectDiscovery: projectDiscovery)
        let historyLoader = SessionHistoryLoader()
        let codeManager = ClaudeCodeManager(configuration: configuration)

        return SessionManager(
            projectDiscovery: projectDiscovery,
            sessionStore: sessionStore,
            historyLoader: historyLoader,
            codeManager: codeManager
        )
    }
}
