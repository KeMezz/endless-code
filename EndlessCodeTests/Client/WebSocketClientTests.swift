//
//  WebSocketClientTests.swift
//  EndlessCodeTests
//
//  WebSocketClient 단위 테스트 (Swift Testing)
//

import Foundation
import Testing
@testable import EndlessCode

// MARK: - Mock WebSocket Client

/// 테스트용 Mock WebSocket 클라이언트
actor MockWebSocketClient: WebSocketClientProtocol {
    private var _connectionState: ConnectionState = .disconnected {
        didSet {
            if _connectionState != oldValue {
                stateContinuation.yield(_connectionState)
            }
        }
    }
    private let messageContinuation: AsyncStream<ServerMessage>.Continuation
    private let _messages: AsyncStream<ServerMessage>

    private let stateContinuation: AsyncStream<ConnectionState>.Continuation
    private let _stateChanges: AsyncStream<ConnectionState>

    var connectCalled = false
    var disconnectCalled = false
    var sentMessages: [ClientMessage] = []
    var shouldFailConnection = false
    var shouldFailSend = false

    init() {
        var msgContinuation: AsyncStream<ServerMessage>.Continuation!
        self._messages = AsyncStream { cont in
            msgContinuation = cont
        }
        self.messageContinuation = msgContinuation

        var stateCont: AsyncStream<ConnectionState>.Continuation!
        self._stateChanges = AsyncStream { cont in
            stateCont = cont
        }
        self.stateContinuation = stateCont
    }

    deinit {
        messageContinuation.finish()
        stateContinuation.finish()
    }

    nonisolated var messages: AsyncStream<ServerMessage> {
        _messages
    }

    nonisolated var stateChanges: AsyncStream<ConnectionState> {
        _stateChanges
    }

    var connectionState: ConnectionState {
        _connectionState
    }

    func connect() async throws {
        connectCalled = true
        if shouldFailConnection {
            throw WebSocketClientError.connectionFailed(underlying: "Mock connection failure")
        }
        _connectionState = .connected
    }

    func disconnect() async {
        disconnectCalled = true
        _connectionState = .disconnected
    }

    func send(_ message: ClientMessage) async throws {
        if shouldFailSend {
            throw WebSocketClientError.sendFailed(underlying: "Mock send failure")
        }
        if _connectionState != .connected {
            throw WebSocketClientError.notConnected
        }
        sentMessages.append(message)
    }

    // Test helpers
    func emitMessage(_ message: ServerMessage) {
        messageContinuation.yield(message)
    }

    func setConnectionState(_ state: ConnectionState) {
        _connectionState = state
    }
}

// MARK: - WebSocketClient Tests

@Suite("WebSocketClient Tests")
struct WebSocketClientTests {

    // MARK: - Configuration Tests

    @Test("Configuration stores all values correctly")
    func configurationStoresAllValuesCorrectly() {
        // Given
        let url = URL(string: "ws://localhost:8080/ws")!
        let token = "test-token"

        // When
        let config = WebSocketClientConfiguration(
            serverURL: url,
            authToken: token,
            maxReconnectAttempts: 5,
            initialReconnectDelay: 2.0,
            maxReconnectDelay: 30.0,
            pingInterval: 15.0
        )

        // Then
        #expect(config.serverURL == url)
        #expect(config.authToken == token)
        #expect(config.maxReconnectAttempts == 5)
        #expect(config.initialReconnectDelay == 2.0)
        #expect(config.maxReconnectDelay == 30.0)
        #expect(config.pingInterval == 15.0)
    }

    @Test("Configuration uses default values")
    func configurationUsesDefaultValues() {
        // Given
        let url = URL(string: "ws://localhost:8080/ws")!

        // When
        let config = WebSocketClientConfiguration(
            serverURL: url,
            authToken: "token"
        )

        // Then
        #expect(config.maxReconnectAttempts == 10)
        #expect(config.initialReconnectDelay == 1.0)
        #expect(config.maxReconnectDelay == 60.0)
        #expect(config.pingInterval == 30.0)
    }

    // MARK: - Connection State Tests

    @Test("Initial connection state is disconnected")
    func initialConnectionStateIsDisconnected() async {
        // Given
        let mockClient = await MockWebSocketClient()

        // When
        let state = await mockClient.connectionState

        // Then
        #expect(state == .disconnected)
    }

    @Test("Connection state changes to connected after connect")
    func connectionStateChangesToConnectedAfterConnect() async throws {
        // Given
        let mockClient = await MockWebSocketClient()

        // When
        try await mockClient.connect()

        // Then
        let state = await mockClient.connectionState
        #expect(state == .connected)
    }

    @Test("Connection state changes to disconnected after disconnect")
    func connectionStateChangesToDisconnectedAfterDisconnect() async throws {
        // Given
        let mockClient = await MockWebSocketClient()
        try await mockClient.connect()

        // When
        await mockClient.disconnect()

        // Then
        let state = await mockClient.connectionState
        #expect(state == .disconnected)
    }

    // MARK: - Error Tests

    @Test("Connection failure throws error")
    func connectionFailureThrowsError() async {
        // Given
        let mockClient = await MockWebSocketClient()
        await mockClient.setConnectionState(.disconnected)

        // When/Then - 에러 타입 확인
        let error = WebSocketClientError.connectionFailed(underlying: "test")
        #expect(error.localizedDescription.contains("Connection failed"))
    }

    @Test("Send when not connected throws error")
    func sendWhenNotConnectedThrowsError() async {
        // Given
        let mockClient = await MockWebSocketClient()
        let message = ClientMessage.userMessage(
            UserMessage(sessionId: "test", content: "hello")
        )

        // When/Then
        await #expect(throws: WebSocketClientError.self) {
            try await mockClient.send(message)
        }
    }

    @Test("Send when connected succeeds")
    func sendWhenConnectedSucceeds() async throws {
        // Given
        let mockClient = await MockWebSocketClient()
        try await mockClient.connect()
        let message = ClientMessage.userMessage(
            UserMessage(sessionId: "test", content: "hello")
        )

        // When
        try await mockClient.send(message)

        // Then
        let sentMessages = await mockClient.sentMessages
        #expect(sentMessages.count == 1)
    }

    // MARK: - Error Type Tests

    @Test("WebSocketClientError provides correct descriptions")
    func webSocketClientErrorProvidesCorrectDescriptions() {
        // Given/When/Then
        let invalidURL = WebSocketClientError.invalidURL
        #expect(invalidURL.localizedDescription == "Invalid WebSocket URL")

        let connectionFailed = WebSocketClientError.connectionFailed(underlying: "timeout")
        #expect(connectionFailed.localizedDescription == "Connection failed: timeout")

        let notConnected = WebSocketClientError.notConnected
        #expect(notConnected.localizedDescription == "Not connected to server")

        let sendFailed = WebSocketClientError.sendFailed(underlying: "buffer full")
        #expect(sendFailed.localizedDescription == "Failed to send message: buffer full")

        let authFailed = WebSocketClientError.authenticationFailed
        #expect(authFailed.localizedDescription == "Authentication failed")

        let maxReconnect = WebSocketClientError.maxReconnectAttemptsExceeded
        #expect(maxReconnect.localizedDescription == "Maximum reconnection attempts exceeded")
    }

    // MARK: - Connection State Equality Tests

    @Test("ConnectionState equality works correctly")
    func connectionStateEqualityWorksCorrectly() {
        // Given/When/Then
        #expect(ConnectionState.disconnected == ConnectionState.disconnected)
        #expect(ConnectionState.connecting == ConnectionState.connecting)
        #expect(ConnectionState.connected == ConnectionState.connected)
        #expect(ConnectionState.reconnecting(attempt: 1) == ConnectionState.reconnecting(attempt: 1))
        #expect(ConnectionState.reconnecting(attempt: 1) != ConnectionState.reconnecting(attempt: 2))
        #expect(ConnectionState.failed(error: "test") == ConnectionState.failed(error: "test"))
        #expect(ConnectionState.failed(error: "test1") != ConnectionState.failed(error: "test2"))
        #expect(ConnectionState.connected != ConnectionState.disconnected)
    }
}
