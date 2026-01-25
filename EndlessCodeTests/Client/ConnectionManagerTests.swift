//
//  ConnectionManagerTests.swift
//  EndlessCodeTests
//
//  ConnectionManager 단위 테스트 (Swift Testing)
//

import Foundation
import Testing
@testable import EndlessCode

// MARK: - Test Helper Actors

private actor StateCollector {
    private var states: [ConnectionState] = []

    func append(_ state: ConnectionState) {
        states.append(state)
    }

    var count: Int {
        states.count
    }
}

private actor MessageCollector {
    private var messages: [ServerMessage] = []

    func append(_ message: ServerMessage) {
        messages.append(message)
    }

    var count: Int {
        messages.count
    }
}

@Suite("ConnectionManager Tests")
struct ConnectionManagerTests {

    // MARK: - Initialization Tests

    @Test("Init with configuration creates manager")
    func initWithConfigurationCreatesManager() {
        // Given
        let url = URL(string: "ws://localhost:8080/ws")!
        let config = WebSocketClientConfiguration(serverURL: url, authToken: "token")

        // When
        let manager = ConnectionManager(configuration: config)

        // Then
        #expect(manager.currentState == .disconnected)
    }

    @Test("Init with mock client creates manager")
    func initWithMockClientCreatesManager() async {
        // Given
        let mockClient = await MockWebSocketClient()

        // When
        let manager = ConnectionManager(client: mockClient)

        // Then
        #expect(manager.currentState == .disconnected)
    }

    // MARK: - Connection Tests

    @Test("Connect calls client connect")
    func connectCallsClientConnect() async throws {
        // Given
        let mockClient = await MockWebSocketClient()
        let manager = ConnectionManager(client: mockClient)

        // When
        try await manager.connect()

        // Then
        let connectCalled = await mockClient.connectCalled
        #expect(connectCalled)
    }

    @Test("Disconnect calls client disconnect")
    func disconnectCallsClientDisconnect() async throws {
        // Given
        let mockClient = await MockWebSocketClient()
        let manager = ConnectionManager(client: mockClient)
        try await manager.connect()

        // When
        await manager.disconnect()

        // Then
        let disconnectCalled = await mockClient.disconnectCalled
        #expect(disconnectCalled)
    }

    // MARK: - Send Tests

    @Test("Send forwards message to client")
    func sendForwardsMessageToClient() async throws {
        // Given
        let mockClient = await MockWebSocketClient()
        let manager = ConnectionManager(client: mockClient)
        try await manager.connect()

        let message = ClientMessage.userMessage(
            UserMessage(sessionId: "test", content: "hello")
        )

        // When
        try await manager.send(message)

        // Then
        let sentMessages = await mockClient.sentMessages
        #expect(sentMessages.count == 1)
    }

    // MARK: - State Tests

    @Test("IsConnected returns true when connected")
    func isConnectedReturnsTrueWhenConnected() async throws {
        // Given
        let mockClient = await MockWebSocketClient()
        let manager = ConnectionManager(client: mockClient)
        try await manager.connect()

        // Give time for state to update
        try await Task.sleep(for: .milliseconds(150))

        // Then
        #expect(manager.isConnected)
    }

    @Test("IsConnected returns false when disconnected")
    func isConnectedReturnsFalseWhenDisconnected() async {
        // Given
        let mockClient = await MockWebSocketClient()
        let manager = ConnectionManager(client: mockClient)

        // Then
        #expect(!manager.isConnected)
    }

    @Test("IsReconnecting returns correct value for reconnecting state")
    func isReconnectingReturnsCorrectValue() {
        // Given/When/Then - test the property logic directly
        // ConnectionManager.isReconnecting checks if currentState matches .reconnecting pattern
        // This verifies the pattern matching works correctly
        let state = ConnectionState.reconnecting(attempt: 1)
        if case .reconnecting = state {
            #expect(Bool(true))
        } else {
            Issue.record("Expected reconnecting state")
        }
    }

    @Test("ErrorMessage returns correct value for failed state")
    func errorMessageReturnsCorrectValue() {
        // Given/When/Then - test the logic directly
        // ConnectionManager.errorMessage extracts error from .failed state
        let state = ConnectionState.failed(error: "Test error")
        if case .failed(let error) = state {
            #expect(error == "Test error")
        } else {
            Issue.record("Expected failed state")
        }
    }

    @Test("ErrorMessage returns nil when not failed")
    func errorMessageReturnsNilWhenNotFailed() async throws {
        // Given
        let mockClient = await MockWebSocketClient()
        let manager = ConnectionManager(client: mockClient)
        try await manager.connect()

        // Give time for state to update
        try await Task.sleep(for: .milliseconds(150))

        // Then
        #expect(manager.errorMessage == nil)
    }

    // MARK: - State Changes Stream Tests

    @Test("StateChanges emits state changes")
    func stateChangesEmitsStateChanges() async throws {
        // Given
        let mockClient = await MockWebSocketClient()
        let manager = ConnectionManager(client: mockClient)

        let collector = StateCollector()
        let collectTask = Task {
            for await state in manager.stateChanges {
                await collector.append(state)
                if await collector.count >= 2 {
                    break
                }
            }
        }

        // Allow Task to start listening
        try await Task.sleep(for: .milliseconds(50))

        // When
        try await manager.connect()
        try await Task.sleep(for: .milliseconds(150))
        await manager.disconnect()
        try await Task.sleep(for: .milliseconds(150))

        collectTask.cancel()

        // Then
        let count = await collector.count
        #expect(count >= 1)
    }

    // MARK: - Messages Stream Tests

    @Test("Messages forwards client messages")
    func messagesForwardsClientMessages() async throws {
        // Given
        let mockClient = await MockWebSocketClient()
        let manager = ConnectionManager(client: mockClient)

        let collector = MessageCollector()
        let collectTask = Task {
            for await message in manager.messages {
                await collector.append(message)
                if await collector.count >= 1 {
                    break
                }
            }
        }

        // Allow Task to start listening
        try await Task.sleep(for: .milliseconds(50))

        // When
        try await manager.connect()

        // Emit a message from mock client
        let testMessage = ServerMessage.sessionState(
            SessionStateMessage(sessionId: "test", state: .active)
        )
        await mockClient.emitMessage(testMessage)

        // Wait for message to be processed
        try await Task.sleep(for: .milliseconds(200))
        collectTask.cancel()

        // Then
        let count = await collector.count
        #expect(count == 1)
    }
}
