//
//  Routes.swift
//  EndlessCode
//
//  Vapor 라우트 정의 - HTTP API 및 WebSocket 엔드포인트
//

import Vapor
import NIOWebSocket

// MARK: - Route Configuration

/// Vapor 앱에 라우트 등록
func configureRoutes(_ app: Application, serverApp: ServerApp) throws {
    // Health check
    app.get("health") { _ in
        ["status": "ok"]
    }

    // API v1
    let api = app.grouped("api", "v1")

    // 프로젝트 API
    try api.register(collection: ProjectRoutes(serverApp: serverApp))

    // 세션 API
    try api.register(collection: SessionRoutes(serverApp: serverApp))

    // WebSocket
    app.webSocket("ws") { req, ws in
        await handleWebSocket(req: req, ws: ws, serverApp: serverApp)
    }
}

// MARK: - Project Routes

struct ProjectRoutes: RouteCollection {
    let serverApp: ServerApp

    func boot(routes: RoutesBuilder) throws {
        let projects = routes.grouped("projects")

        // GET /api/v1/projects - 프로젝트 목록
        projects.get(use: listProjects)

        // GET /api/v1/projects/:id - 프로젝트 상세
        projects.get(":id", use: getProject)

        // GET /api/v1/projects/:id/sessions - 프로젝트의 세션 목록
        projects.get(":id", "sessions", use: listProjectSessions)
    }

    @Sendable
    func listProjects(req: Request) async throws -> [ProjectDTO] {
        guard let sessionManager = await serverApp.getSessionManager() else {
            throw Abort(.serviceUnavailable, reason: "서버가 준비되지 않았습니다")
        }

        let projects = try await sessionManager.listProjects()
        return projects.map { ProjectDTO(from: $0) }
    }

    @Sendable
    func getProject(req: Request) async throws -> ProjectDTO {
        guard let id = req.parameters.get("id") else {
            throw Abort(.badRequest, reason: "프로젝트 ID가 필요합니다")
        }

        guard let sessionManager = await serverApp.getSessionManager() else {
            throw Abort(.serviceUnavailable, reason: "서버가 준비되지 않았습니다")
        }

        guard let project = try await sessionManager.getProject(id: id) else {
            throw Abort(.notFound, reason: "프로젝트를 찾을 수 없습니다: \(id)")
        }

        return ProjectDTO(from: project)
    }

    @Sendable
    func listProjectSessions(req: Request) async throws -> [SessionDTO] {
        guard let id = req.parameters.get("id") else {
            throw Abort(.badRequest, reason: "프로젝트 ID가 필요합니다")
        }

        guard let sessionManager = await serverApp.getSessionManager() else {
            throw Abort(.serviceUnavailable, reason: "서버가 준비되지 않았습니다")
        }

        let sessions = try await sessionManager.listSessions(projectId: id)
        return sessions.map { SessionDTO(from: $0) }
    }
}

// MARK: - Session Routes

struct SessionRoutes: RouteCollection {
    let serverApp: ServerApp

    func boot(routes: RoutesBuilder) throws {
        let sessions = routes.grouped("sessions")

        // GET /api/v1/sessions - 모든 세션 목록
        sessions.get(use: listSessions)

        // POST /api/v1/sessions - 새 세션 생성
        sessions.post(use: createSession)

        // GET /api/v1/sessions/:id - 세션 상세
        sessions.get(":id", use: getSession)

        // POST /api/v1/sessions/:id/resume - 세션 재개
        sessions.post(":id", "resume", use: resumeSession)

        // POST /api/v1/sessions/:id/pause - 세션 일시정지
        sessions.post(":id", "pause", use: pauseSession)

        // DELETE /api/v1/sessions/:id - 세션 종료
        sessions.delete(":id", use: terminateSession)

        // GET /api/v1/sessions/:id/history - 세션 히스토리
        sessions.get(":id", "history", use: getSessionHistory)
    }

    @Sendable
    func listSessions(req: Request) async throws -> [SessionDTO] {
        guard let sessionManager = await serverApp.getSessionManager() else {
            throw Abort(.serviceUnavailable, reason: "서버가 준비되지 않았습니다")
        }

        let sessions = await sessionManager.getAllSessions()
        return sessions.map { SessionDTO(from: $0) }
    }

    @Sendable
    func createSession(req: Request) async throws -> SessionDTO {
        let input = try req.content.decode(CreateSessionInput.self)

        guard let sessionManager = await serverApp.getSessionManager() else {
            throw Abort(.serviceUnavailable, reason: "서버가 준비되지 않았습니다")
        }

        let session = try await sessionManager.createSession(projectId: input.projectId)
        return SessionDTO(from: session)
    }

    @Sendable
    func getSession(req: Request) async throws -> SessionDTO {
        guard let id = req.parameters.get("id") else {
            throw Abort(.badRequest, reason: "세션 ID가 필요합니다")
        }

        guard let sessionManager = await serverApp.getSessionManager() else {
            throw Abort(.serviceUnavailable, reason: "서버가 준비되지 않았습니다")
        }

        guard let session = await sessionManager.getSession(id: id) else {
            throw Abort(.notFound, reason: "세션을 찾을 수 없습니다: \(id)")
        }

        return SessionDTO(from: session)
    }

    @Sendable
    func resumeSession(req: Request) async throws -> SessionDTO {
        guard let id = req.parameters.get("id") else {
            throw Abort(.badRequest, reason: "세션 ID가 필요합니다")
        }

        guard let sessionManager = await serverApp.getSessionManager() else {
            throw Abort(.serviceUnavailable, reason: "서버가 준비되지 않았습니다")
        }

        let session = try await sessionManager.resumeSession(sessionId: id)
        return SessionDTO(from: session)
    }

    @Sendable
    func pauseSession(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id") else {
            throw Abort(.badRequest, reason: "세션 ID가 필요합니다")
        }

        guard let sessionManager = await serverApp.getSessionManager() else {
            throw Abort(.serviceUnavailable, reason: "서버가 준비되지 않았습니다")
        }

        try await sessionManager.pauseSession(sessionId: id)
        return .ok
    }

    @Sendable
    func terminateSession(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id") else {
            throw Abort(.badRequest, reason: "세션 ID가 필요합니다")
        }

        guard let sessionManager = await serverApp.getSessionManager() else {
            throw Abort(.serviceUnavailable, reason: "서버가 준비되지 않았습니다")
        }

        try await sessionManager.terminateSession(sessionId: id)
        return .noContent
    }

    @Sendable
    func getSessionHistory(req: Request) async throws -> SessionHistoryDTO {
        guard let id = req.parameters.get("id") else {
            throw Abort(.badRequest, reason: "세션 ID가 필요합니다")
        }

        let projectId = req.query["projectId"] ?? ""
        let limit = req.query["limit"] ?? 1000
        let offset = req.query["offset"] ?? 0

        guard let sessionManager = await serverApp.getSessionManager() else {
            throw Abort(.serviceUnavailable, reason: "서버가 준비되지 않았습니다")
        }

        let history = try await sessionManager.getSessionHistory(
            sessionId: id,
            projectId: projectId,
            limit: limit,
            offset: offset
        )

        return SessionHistoryDTO(from: history)
    }
}

// MARK: - WebSocket Handler

@Sendable
private func handleWebSocket(req: Request, ws: WebSocket, serverApp: ServerApp) async {
    let connectionId = UUID().uuidString

    // 인증 확인
    let authToken = await serverApp.getConfiguration().authToken
    if let requiredToken = authToken {
        let providedToken = req.headers.bearerAuthorization?.token
        guard providedToken == requiredToken else {
            try? await ws.close(code: .policyViolation)
            return
        }
    }

    // WebSocket 핸들러에 연결 등록
    guard let handler = await serverApp.getWebSocketHandler() else {
        try? await ws.close(code: .unexpectedServerError)
        return
    }

    // 연결 등록
    do {
        try await handler.handleConnection(connectionId: connectionId, authToken: authToken)
    } catch {
        try? await ws.close(code: .policyViolation)
        return
    }

    // 메시지 수신 처리
    ws.onText { _, text in
        Task {
            await handleWebSocketMessage(text: text, connectionId: connectionId, ws: ws, handler: handler)
        }
    }

    // 연결 해제 처리
    ws.onClose.whenComplete { _ in
        Task {
            await handler.handleDisconnection(connectionId: connectionId)
        }
    }
}

@Sendable
private func handleWebSocketMessage(
    text: String,
    connectionId: String,
    ws: WebSocket,
    handler: WebSocketHandler
) async {
    guard let data = text.data(using: .utf8) else { return }

    do {
        let decoder = JSONDecoder()
        let message = try decoder.decode(ClientMessage.self, from: data)
        try await handler.handleMessage(connectionId: connectionId, message: message)
    } catch {
        // 에러 메시지 전송
        let errorMessage = ErrorMessage(
            code: WebSocketErrorCode.invalidMessage.rawValue,
            message: "잘못된 메시지 형식: \(error.localizedDescription)"
        )
        if let errorData = try? JSONEncoder().encode(ServerMessage.error(errorMessage)),
           let errorString = String(data: errorData, encoding: .utf8) {
            try? await ws.send(errorString)
        }
    }
}

// MARK: - DTOs

struct ProjectDTO: Content {
    let id: String
    let name: String
    let path: String
    let sessionCount: Int
    let lastUsed: Date?

    nonisolated init(from project: Project) {
        self.id = project.id
        self.name = project.name
        self.path = project.path
        self.sessionCount = project.sessionCount
        self.lastUsed = project.lastUsed
    }
}

struct SessionDTO: Content {
    let id: String
    let projectId: String
    let state: String
    let createdAt: Date
    let lastActiveAt: Date
    let messageCount: Int

    nonisolated init(from session: Session) {
        self.id = session.id
        self.projectId = session.projectId
        self.state = session.state.rawValue
        self.createdAt = session.createdAt
        self.lastActiveAt = session.lastActiveAt
        self.messageCount = session.messageCount
    }
}

struct CreateSessionInput: Content {
    let projectId: String
}

struct SessionHistoryDTO: Content {
    let sessionId: String
    let messages: [ParsedMessageDTO]
    let totalCount: Int
    let hasMore: Bool

    nonisolated init(from history: SessionHistory) {
        self.sessionId = history.sessionId
        self.messages = history.messages.map { ParsedMessageDTO(from: $0) }
        self.totalCount = history.totalCount
        self.hasMore = history.hasMore
    }
}

// MARK: - Server Statistics

struct ServerStatisticsDTO: Content {
    let isRunning: Bool
    let activeSessions: Int
    let totalSessions: Int
    let activeConnections: Int
    let pendingPrompts: Int

    nonisolated init(from stats: ServerStatistics) {
        self.isRunning = stats.isRunning
        self.activeSessions = stats.activeSessions
        self.totalSessions = stats.totalSessions
        self.activeConnections = stats.activeConnections
        self.pendingPrompts = stats.pendingPrompts
    }
}
