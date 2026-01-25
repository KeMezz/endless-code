//
//  MessageRouterTests.swift
//  EndlessCodeTests
//
//  MessageRouter 단위 테스트 (Swift Testing)
//

import Foundation
import Testing
@testable import EndlessCode

// MARK: - Mock Connection Manager

/// 테스트용 Mock ConnectionManager
actor MockConnectionManager: ConnectionManagerProtocol {
    private var _state: ConnectionState = .disconnected
    private let stateContinuation: AsyncStream<ConnectionState>.Continuation
    private let _stateChanges: AsyncStream<ConnectionState>
    private let messageContinuation: AsyncStream<ServerMessage>.Continuation
    private let _messages: AsyncStream<ServerMessage>

    var sentMessages: [ClientMessage] = []

    init() {
        var stateCont: AsyncStream<ConnectionState>.Continuation!
        self._stateChanges = AsyncStream { cont in
            stateCont = cont
        }
        self.stateContinuation = stateCont

        var msgCont: AsyncStream<ServerMessage>.Continuation!
        self._messages = AsyncStream { cont in
            msgCont = cont
        }
        self.messageContinuation = msgCont
    }

    deinit {
        stateContinuation.finish()
        messageContinuation.finish()
    }

    var state: ConnectionState {
        _state
    }

    nonisolated var stateChanges: AsyncStream<ConnectionState> {
        _stateChanges
    }

    nonisolated var messages: AsyncStream<ServerMessage> {
        _messages
    }

    func connect() async throws {
        _state = .connected
        stateContinuation.yield(.connected)
    }

    func disconnect() async {
        _state = .disconnected
        stateContinuation.yield(.disconnected)
    }

    func send(_ message: ClientMessage) async throws {
        sentMessages.append(message)
    }

    // Test helpers
    func emitMessage(_ message: ServerMessage) {
        messageContinuation.yield(message)
    }
}

// MARK: - Test Helper Actors

private actor OutputCollector<T: Sendable> {
    private var items: [T] = []

    func append(_ item: T) {
        items.append(item)
    }

    var count: Int {
        items.count
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    var first: T? {
        items.first
    }

    var all: [T] {
        items
    }
}

@Suite("MessageRouter Tests")
struct MessageRouterTests {

    // MARK: - CLI Output Routing Tests

    @Test("Routes CLI output messages")
    func routesCLIOutputMessages() async throws {
        // Given
        let mockManager = await MockConnectionManager()
        let router = await MessageRouter(connectionManager: mockManager)

        let collector = OutputCollector<CLIOutput>()
        let collectTask = Task {
            for await output in router.cliOutputs {
                await collector.append(output)
                if await collector.count >= 1 {
                    break
                }
            }
        }

        // Allow Task to start listening
        try await Task.sleep(for: .milliseconds(50))

        // When
        await router.start()

        let chatMessage = ChatMessage(role: .assistant, content: "Hello")
        let cliOutput = CLIOutput(
            sessionId: "test-session",
            message: .chat(chatMessage)
        )
        await mockManager.emitMessage(.cliOutput(cliOutput))

        // Wait for message to be processed
        try await Task.sleep(for: .milliseconds(200))
        collectTask.cancel()
        await router.stop()

        // Then
        let count = await collector.count
        let first = await collector.first
        #expect(count == 1)
        #expect(first?.sessionId == "test-session")
    }

    // MARK: - Session State Routing Tests

    @Test("Routes session state messages")
    func routesSessionStateMessages() async throws {
        // Given
        let mockManager = await MockConnectionManager()
        let router = await MessageRouter(connectionManager: mockManager)

        let collector = OutputCollector<SessionStateMessage>()
        let collectTask = Task {
            for await state in router.sessionStates {
                await collector.append(state)
                if await collector.count >= 1 {
                    break
                }
            }
        }

        try await Task.sleep(for: .milliseconds(50))

        // When
        await router.start()

        let stateMessage = SessionStateMessage(
            sessionId: "test-session",
            state: .active
        )
        await mockManager.emitMessage(.sessionState(stateMessage))

        try await Task.sleep(for: .milliseconds(200))
        collectTask.cancel()
        await router.stop()

        // Then
        let count = await collector.count
        let first = await collector.first
        #expect(count == 1)
        #expect(first?.sessionId == "test-session")
        #expect(first?.state == .active)
    }

    // MARK: - Prompt Request Routing Tests

    @Test("Routes prompt request messages")
    func routesPromptRequestMessages() async throws {
        // Given
        let mockManager = await MockConnectionManager()
        let router = await MessageRouter(connectionManager: mockManager)

        let collector = OutputCollector<PromptRequest>()
        let collectTask = Task {
            for await request in router.promptRequests {
                await collector.append(request)
                if await collector.count >= 1 {
                    break
                }
            }
        }

        try await Task.sleep(for: .milliseconds(50))

        // When
        await router.start()

        let question = AskUserQuestion(
            toolUseId: "tool-1",
            question: "Continue?"
        )
        let promptRequest = PromptRequest(
            sessionId: "test-session",
            promptId: "prompt-1",
            question: question
        )
        await mockManager.emitMessage(.promptRequest(promptRequest))

        try await Task.sleep(for: .milliseconds(200))
        collectTask.cancel()
        await router.stop()

        // Then
        let count = await collector.count
        let first = await collector.first
        #expect(count == 1)
        #expect(first?.sessionId == "test-session")
        #expect(first?.promptId == "prompt-1")
    }

    // MARK: - Error Routing Tests

    @Test("Routes error messages")
    func routesErrorMessages() async throws {
        // Given
        let mockManager = await MockConnectionManager()
        let router = await MessageRouter(connectionManager: mockManager)

        let collector = OutputCollector<ErrorMessage>()
        let collectTask = Task {
            for await error in router.errors {
                await collector.append(error)
                if await collector.count >= 1 {
                    break
                }
            }
        }

        try await Task.sleep(for: .milliseconds(50))

        // When
        await router.start()

        let errorMessage = ErrorMessage(
            code: "TEST_ERROR",
            message: "Test error message",
            sessionId: "test-session"
        )
        await mockManager.emitMessage(.error(errorMessage))

        try await Task.sleep(for: .milliseconds(200))
        collectTask.cancel()
        await router.stop()

        // Then
        let count = await collector.count
        let first = await collector.first
        #expect(count == 1)
        #expect(first?.code == "TEST_ERROR")
        #expect(first?.message == "Test error message")
    }

    // MARK: - Sync Routing Tests

    @Test("Routes sync messages")
    func routesSyncMessages() async throws {
        // Given
        let mockManager = await MockConnectionManager()
        let router = await MessageRouter(connectionManager: mockManager)

        let collector = OutputCollector<SyncMessage>()
        let collectTask = Task {
            for await sync in router.syncs {
                await collector.append(sync)
                if await collector.count >= 1 {
                    break
                }
            }
        }

        try await Task.sleep(for: .milliseconds(50))

        // When
        await router.start()

        let session = Session(projectId: "project-1")
        let syncMessage = SyncMessage(
            sessions: [session],
            recentMessages: []
        )
        await mockManager.emitMessage(.sync(syncMessage))

        try await Task.sleep(for: .milliseconds(200))
        collectTask.cancel()
        await router.stop()

        // Then
        let count = await collector.count
        let first = await collector.first
        #expect(count == 1)
        #expect(first?.sessions.count == 1)
    }

    // MARK: - Filtered Stream Tests

    @Test("Filters CLI outputs by session ID")
    func filtersCLIOutputsBySessionId() async throws {
        // Given
        let mockManager = await MockConnectionManager()
        let router = await MessageRouter(connectionManager: mockManager)

        let collector = OutputCollector<CLIOutput>()
        let collectTask = Task {
            for await output in router.cliOutputs(for: "session-1") {
                await collector.append(output)
                if await collector.count >= 1 {
                    break
                }
            }
        }

        try await Task.sleep(for: .milliseconds(50))

        // When
        await router.start()

        // Emit message for different session (should be filtered out)
        let chatMessage1 = ChatMessage(role: .assistant, content: "Hello")
        let output1 = CLIOutput(sessionId: "session-2", message: .chat(chatMessage1))
        await mockManager.emitMessage(.cliOutput(output1))

        // Emit message for target session
        let chatMessage2 = ChatMessage(role: .assistant, content: "World")
        let output2 = CLIOutput(sessionId: "session-1", message: .chat(chatMessage2))
        await mockManager.emitMessage(.cliOutput(output2))

        try await Task.sleep(for: .milliseconds(300))
        collectTask.cancel()
        await router.stop()

        // Then
        let count = await collector.count
        let first = await collector.first
        #expect(count == 1)
        #expect(first?.sessionId == "session-1")
    }

    // MARK: - Start/Stop Tests

    @Test("Stop cancels routing")
    func stopCancelsRouting() async throws {
        // Given
        let mockManager = await MockConnectionManager()
        let router = await MessageRouter(connectionManager: mockManager)

        let collector = OutputCollector<CLIOutput>()
        let collectTask = Task {
            for await output in router.cliOutputs {
                await collector.append(output)
            }
        }

        try await Task.sleep(for: .milliseconds(50))

        // When
        await router.start()
        await router.stop()

        // Emit message after stop
        let chatMessage = ChatMessage(role: .assistant, content: "Hello")
        let output = CLIOutput(sessionId: "test", message: .chat(chatMessage))
        await mockManager.emitMessage(.cliOutput(output))

        try await Task.sleep(for: .milliseconds(100))
        collectTask.cancel()

        // Then - no messages should be received after stop
        let isEmpty = await collector.isEmpty
        #expect(isEmpty)
    }

    // MARK: - Multiple Message Types Tests

    @Test("Routes multiple message types correctly")
    func routesMultipleMessageTypesCorrectly() async throws {
        // Given
        let mockManager = await MockConnectionManager()
        let router = await MessageRouter(connectionManager: mockManager)

        actor Counter {
            var cliCount = 0
            var stateCount = 0
            var errorCount = 0

            func incrementCli() { cliCount += 1 }
            func incrementState() { stateCount += 1 }
            func incrementError() { errorCount += 1 }
        }

        let counter = Counter()

        let cliTask = Task {
            for await _ in router.cliOutputs {
                await counter.incrementCli()
                if await counter.cliCount >= 1 { break }
            }
        }

        let stateTask = Task {
            for await _ in router.sessionStates {
                await counter.incrementState()
                if await counter.stateCount >= 1 { break }
            }
        }

        let errorTask = Task {
            for await _ in router.errors {
                await counter.incrementError()
                if await counter.errorCount >= 1 { break }
            }
        }

        try await Task.sleep(for: .milliseconds(50))

        // When
        await router.start()

        let chatMessage = ChatMessage(role: .assistant, content: "Hello")
        await mockManager.emitMessage(.cliOutput(CLIOutput(sessionId: "s1", message: .chat(chatMessage))))
        await mockManager.emitMessage(.sessionState(SessionStateMessage(sessionId: "s1", state: .active)))
        await mockManager.emitMessage(.error(ErrorMessage(code: "ERR", message: "Error")))

        try await Task.sleep(for: .milliseconds(300))

        cliTask.cancel()
        stateTask.cancel()
        errorTask.cancel()
        await router.stop()

        // Then
        let cliCount = await counter.cliCount
        let stateCount = await counter.stateCount
        let errorCount = await counter.errorCount
        #expect(cliCount == 1)
        #expect(stateCount == 1)
        #expect(errorCount == 1)
    }
}

// MARK: - MessageHandler Tests

@Suite("MessageHandler Tests")
struct MessageHandlerTests {

    @Test("Handler receives CLI output messages")
    func handlerReceivesCLIOutputMessages() async throws {
        // Given
        let mockManager = await MockConnectionManager()
        let router = await MessageRouter(connectionManager: mockManager)
        let handler = await MessageHandler(router: router)

        actor Counter {
            var count = 0
            func increment() { count += 1 }
        }

        let counter = Counter()
        await handler.onCLIOutput { _ in
            await counter.increment()
        }

        try await Task.sleep(for: .milliseconds(50))

        // When
        await router.start()

        let chatMessage = ChatMessage(role: .assistant, content: "Hello")
        let output = CLIOutput(sessionId: "test", message: .chat(chatMessage))
        await mockManager.emitMessage(.cliOutput(output))

        try await Task.sleep(for: .milliseconds(200))
        await router.stop()
        await handler.removeAllHandlers()

        // Then
        let receivedCount = await counter.count
        #expect(receivedCount == 1)
    }

    @Test("Remove all handlers stops receiving messages")
    func removeAllHandlersStopsReceivingMessages() async throws {
        // Given
        let mockManager = await MockConnectionManager()
        let router = await MessageRouter(connectionManager: mockManager)
        let handler = await MessageHandler(router: router)

        actor Counter {
            var count = 0
            func increment() { count += 1 }
        }

        let counter = Counter()
        await handler.onCLIOutput { _ in
            await counter.increment()
        }

        try await Task.sleep(for: .milliseconds(50))

        // When
        await router.start()
        await handler.removeAllHandlers()

        let chatMessage = ChatMessage(role: .assistant, content: "Hello")
        let output = CLIOutput(sessionId: "test", message: .chat(chatMessage))
        await mockManager.emitMessage(.cliOutput(output))

        try await Task.sleep(for: .milliseconds(200))
        await router.stop()

        // Then - no messages should be received after removing handlers
        let receivedCount = await counter.count
        #expect(receivedCount == 0)
    }
}
