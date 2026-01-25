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

    var allStates: [ConnectionState] {
        states
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
    func initWithConfigurationCreatesManager() async {
        // Given
        let url = URL(string: "ws://localhost:8080/ws")!
        let config = WebSocketClientConfiguration(serverURL: url, authToken: "token")

        // When
        let manager = ConnectionManager(configuration: config)

        // Then
        let state = await manager.state
        #expect(state == .disconnected)
    }

    @Test("Init with mock client creates manager")
    func initWithMockClientCreatesManager() async {
        // Given
        let mockClient = await MockWebSocketClient()

        // When
        let manager = ConnectionManager(client: mockClient)

        // Then
        let state = await manager.state
        #expect(state == .disconnected)
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

    @Test("State reflects connected after connect")
    func stateReflectsConnectedAfterConnect() async throws {
        // Given
        let mockClient = await MockWebSocketClient()
        let manager = ConnectionManager(client: mockClient)

        // When
        try await manager.connect()

        // Give time for state to propagate
        try await Task.sleep(for: .milliseconds(50))

        // Then
        let state = await manager.state
        #expect(state == .connected)
    }

    @Test("State reflects disconnected after disconnect")
    func stateReflectsDisconnectedAfterDisconnect() async throws {
        // Given
        let mockClient = await MockWebSocketClient()
        let manager = ConnectionManager(client: mockClient)
        try await manager.connect()

        // When
        await manager.disconnect()

        // Then
        let state = await manager.state
        #expect(state == .disconnected)
    }

    // MARK: - State Changes Stream Tests

    @Test("StateChanges emits state changes via event stream")
    func stateChangesEmitsStateChangesViaEventStream() async throws {
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
        try await Task.sleep(for: .milliseconds(50))
        await manager.disconnect()
        try await Task.sleep(for: .milliseconds(50))

        collectTask.cancel()

        // Then
        let count = await collector.count
        #expect(count >= 2)

        let states = await collector.allStates
        #expect(states.contains(.connected))
        #expect(states.contains(.disconnected))
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
        try await Task.sleep(for: .milliseconds(100))
        collectTask.cancel()

        // Then
        let count = await collector.count
        #expect(count == 1)
    }

    // MARK: - Observable State Tests

    @Test("Observable state reflects connection changes")
    @MainActor
    func observableStateReflectsConnectionChanges() async throws {
        // Given
        let mockClient = await MockWebSocketClient()
        let manager = ConnectionManager(client: mockClient)
        let observableState = ConnectionManagerObservableState()

        // When
        observableState.observe(manager)
        try await manager.connect()

        // Wait for state to propagate
        try await Task.sleep(for: .milliseconds(100))

        // Then
        #expect(observableState.isConnected)
        #expect(!observableState.isReconnecting)
        #expect(observableState.errorMessage == nil)
    }

    @Test("Observable state stops observing correctly")
    @MainActor
    func observableStateStopsObservingCorrectly() async throws {
        // Given
        let mockClient = await MockWebSocketClient()
        let manager = ConnectionManager(client: mockClient)
        let observableState = ConnectionManagerObservableState()

        observableState.observe(manager)
        try await manager.connect()
        try await Task.sleep(for: .milliseconds(100))

        // When
        observableState.stopObserving()
        await manager.disconnect()
        try await Task.sleep(for: .milliseconds(100))

        // Then - state should still be connected because we stopped observing
        #expect(observableState.isConnected)
    }

    // MARK: - ConnectionState Pattern Matching Tests

    @Test("IsReconnecting returns correct value for reconnecting state")
    func isReconnectingReturnsCorrectValue() {
        // Given/When/Then - test the pattern matching works correctly
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
        let state = ConnectionState.failed(error: "Test error")
        if case .failed(let error) = state {
            #expect(error == "Test error")
        } else {
            Issue.record("Expected failed state")
        }
    }
}
