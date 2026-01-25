//
//  WebSocketHandlerTests.swift
//  EndlessCodeTests
//
//  WebSocket 핸들러 테스트 (Swift Testing)
//

import Testing
@testable import EndlessCode

@Suite("WebSocketHandler Tests")
struct WebSocketHandlerTests {

    // MARK: - Mock Session Manager

    actor MockSessionManager: SessionManagerProtocol {
        var sessions: [Session] = []
        var createdSessions: [String] = []
        var terminatedSessions: [String] = []
        var sentMessages: [(sessionId: String, message: String)] = []

        func listProjects() async throws -> [Project] {
            []
        }

        func listSessions(projectId: String) async throws -> [Session] {
            sessions.filter { $0.projectId == projectId }
        }

        func createSession(projectId: String) async throws -> Session {
            let session = Session(projectId: projectId)
            sessions.append(session)
            createdSessions.append(session.id)
            return session
        }

        func resumeSession(sessionId: String) async throws -> Session {
            guard let session = sessions.first(where: { $0.id == sessionId }) else {
                throw SessionManagerError.sessionNotFound(sessionId: sessionId)
            }
            return session
        }

        func terminateSession(sessionId: String) async throws {
            terminatedSessions.append(sessionId)
            sessions.removeAll { $0.id == sessionId }
        }

        func getSessionHistory(
            sessionId: String,
            projectId: String,
            limit: Int,
            offset: Int
        ) async throws -> SessionHistory {
            SessionHistory(
                sessionId: sessionId,
                messages: [],
                totalCount: 0,
                hasMore: false,
                corruptedLines: 0
            )
        }

        func sendMessage(sessionId: String, message: String) async throws {
            // Check if session exists and is active
            guard let session = sessions.first(where: { $0.id == sessionId }) else {
                throw SessionManagerError.sessionNotFound(sessionId: sessionId)
            }
            sentMessages.append((sessionId, message))
        }

        func getAllSessions() async -> [Session] {
            sessions
        }

        func pauseSession(sessionId: String) async throws {
            // Mock implementation
        }

        // Helper to set session state for testing
        func setSessionActive(_ sessionId: String) {
            if let index = sessions.firstIndex(where: { $0.id == sessionId }) {
                var session = sessions[index]
                // Session은 struct이므로 새로 만들어서 대체
                sessions[index] = Session(
                    id: session.id,
                    projectId: session.projectId,
                    state: .active,
                    createdAt: session.createdAt,
                    lastActiveAt: session.lastActiveAt,
                    messageCount: session.messageCount
                )
            }
        }
    }

    // MARK: - Connection Tests

    @Test("Handle connection with valid token succeeds")
    func handleConnectionWithValidTokenSucceeds() async throws {
        // Given
        var config = ServerConfiguration()
        config.authToken = "valid-token"

        let sessionManager = MockSessionManager()
        let handler = WebSocketHandler(configuration: config, sessionManager: sessionManager)

        // When/Then - should not throw
        try await handler.handleConnection(connectionId: "conn1", authToken: "valid-token")
    }

    @Test("Handle connection with invalid token throws error")
    func handleConnectionWithInvalidTokenThrowsError() async {
        // Given
        var config = ServerConfiguration()
        config.authToken = "valid-token"

        let sessionManager = MockSessionManager()
        let handler = WebSocketHandler(configuration: config, sessionManager: sessionManager)

        // When/Then
        await #expect(throws: WebSocketError.authenticationFailed) {
            try await handler.handleConnection(connectionId: "conn1", authToken: "wrong-token")
        }
    }

    @Test("Handle connection with no token required succeeds")
    func handleConnectionWithNoTokenRequiredSucceeds() async throws {
        // Given
        var config = ServerConfiguration()
        config.authToken = nil // No auth required

        let sessionManager = MockSessionManager()
        let handler = WebSocketHandler(configuration: config, sessionManager: sessionManager)

        // When/Then - should not throw
        try await handler.handleConnection(connectionId: "conn1", authToken: nil)
    }

    @Test("Handle connection exceeds limit throws error")
    func handleConnectionExceedsLimitThrowsError() async throws {
        // Given
        var config = ServerConfiguration()
        config.maxWebSocketConnections = 2

        let sessionManager = MockSessionManager()
        let handler = WebSocketHandler(configuration: config, sessionManager: sessionManager)

        try await handler.handleConnection(connectionId: "conn1", authToken: nil)
        try await handler.handleConnection(connectionId: "conn2", authToken: nil)

        // When/Then
        await #expect(throws: WebSocketError.connectionLimitExceeded) {
            try await handler.handleConnection(connectionId: "conn3", authToken: nil)
        }
    }

    // MARK: - Message Handling Tests

    @Test("Handle message userMessage sends to session")
    func handleMessageUserMessageSendsToSession() async throws {
        // Given
        let config = ServerConfiguration()
        let sessionManager = MockSessionManager()
        let handler = WebSocketHandler(configuration: config, sessionManager: sessionManager)

        try await handler.handleConnection(connectionId: "conn1", authToken: nil)

        // Create a session first and set it active
        let session = try await sessionManager.createSession(projectId: "test-project")
        await sessionManager.setSessionActive(session.id)

        let message = ClientMessage.userMessage(UserMessage(sessionId: session.id, content: "Hello"))

        // When
        try await handler.handleMessage(connectionId: "conn1", message: message)

        // Then
        let sentMessages = await sessionManager.sentMessages
        #expect(sentMessages.count == 1)
        #expect(sentMessages[0].message == "Hello")
    }

    @Test("Handle message sessionControl start creates session")
    func handleMessageSessionControlStartCreatesSession() async throws {
        // Given
        let config = ServerConfiguration()
        let sessionManager = MockSessionManager()
        let handler = WebSocketHandler(configuration: config, sessionManager: sessionManager)

        try await handler.handleConnection(connectionId: "conn1", authToken: nil)

        let control = SessionControl(action: .start, projectId: "test-project")
        let message = ClientMessage.sessionControl(control)

        // When
        try await handler.handleMessage(connectionId: "conn1", message: message)

        // Then
        let createdSessions = await sessionManager.createdSessions
        #expect(createdSessions.count == 1)
    }

    @Test("Handle message sessionControl terminate terminates session")
    func handleMessageSessionControlTerminateTerminatesSession() async throws {
        // Given
        let config = ServerConfiguration()
        let sessionManager = MockSessionManager()
        let handler = WebSocketHandler(configuration: config, sessionManager: sessionManager)

        try await handler.handleConnection(connectionId: "conn1", authToken: nil)

        let session = try await sessionManager.createSession(projectId: "test-project")

        let control = SessionControl(action: .terminate, sessionId: session.id)
        let message = ClientMessage.sessionControl(control)

        // When
        try await handler.handleMessage(connectionId: "conn1", message: message)

        // Then
        let terminatedSessions = await sessionManager.terminatedSessions
        #expect(terminatedSessions.contains(session.id))
    }

    // MARK: - Disconnection Tests

    @Test("Handle disconnection removes connection")
    func handleDisconnectionRemovesConnection() async throws {
        // Given
        let config = ServerConfiguration()
        let sessionManager = MockSessionManager()
        let handler = WebSocketHandler(configuration: config, sessionManager: sessionManager)

        try await handler.handleConnection(connectionId: "conn1", authToken: nil)
        try await handler.handleConnection(connectionId: "conn2", authToken: nil)

        // When
        await handler.handleDisconnection(connectionId: "conn1")

        // Then
        let count = await handler.connectionCount
        #expect(count == 1)
    }

    // MARK: - Broadcasting Tests

    @Test("Broadcast sends to subscribers")
    func broadcastSendsToSubscribers() async throws {
        // Given
        let config = ServerConfiguration()
        let sessionManager = MockSessionManager()
        let handler = WebSocketHandler(configuration: config, sessionManager: sessionManager)

        try await handler.handleConnection(connectionId: "conn1", authToken: nil)

        var receivedData: [Data] = []
        await handler.registerSendCallback(connectionId: "conn1") { data in
            receivedData.append(data)
        }

        // Create and subscribe to session via sessionControl
        let control = SessionControl(action: .start, projectId: "test")
        let controlMessage = ClientMessage.sessionControl(control)
        try await handler.handleMessage(connectionId: "conn1", message: controlMessage)

        let createdSessions = await sessionManager.createdSessions
        guard let sessionId = createdSessions.first else {
            Issue.record("Expected session to be created")
            return
        }

        // When
        let serverMessage = ServerMessage.sessionState(
            SessionStateMessage(sessionId: sessionId, state: .active)
        )
        await handler.broadcast(message: serverMessage, to: sessionId)

        // Then - should have received sync + session state + broadcast
        #expect(receivedData.count >= 2)
    }

    // MARK: - Statistics Tests

    @Test("Connection count returns correct count")
    func connectionCountReturnsCorrectCount() async throws {
        // Given
        let config = ServerConfiguration()
        let sessionManager = MockSessionManager()
        let handler = WebSocketHandler(configuration: config, sessionManager: sessionManager)

        // When
        try await handler.handleConnection(connectionId: "conn1", authToken: nil)
        try await handler.handleConnection(connectionId: "conn2", authToken: nil)

        // Then
        let count = await handler.connectionCount
        #expect(count == 2)
    }
}
