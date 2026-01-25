//
//  ConnectionManager.swift
//  EndlessCode
//
//  연결 상태 모니터링 및 상태 이벤트 발행
//

import Foundation

// MARK: - ConnectionManagerProtocol

/// 연결 관리자 프로토콜
protocol ConnectionManagerProtocol: Sendable {
    /// 서버에 연결
    func connect() async throws

    /// 연결 해제
    func disconnect() async

    /// 메시지 전송
    func send(_ message: ClientMessage) async throws

    /// 현재 연결 상태
    var state: ConnectionState { get async }

    /// 연결 상태 변경 스트림
    var stateChanges: AsyncStream<ConnectionState> { get }

    /// 수신 메시지 스트림
    var messages: AsyncStream<ServerMessage> { get }
}

// MARK: - ConnectionManager

/// 연결 관리자 구현
/// WebSocketClient를 래핑하여 연결 상태 모니터링 및 이벤트 발행
@Observable
final class ConnectionManager: ConnectionManagerProtocol, @unchecked Sendable {
    // MARK: - Properties

    private let client: any WebSocketClientProtocol
    private let stateContinuation: AsyncStream<ConnectionState>.Continuation
    private let _stateChanges: AsyncStream<ConnectionState>

    private var monitorTask: Task<Void, Never>?
    private var messageForwardTask: Task<Void, Never>?

    private let messageContinuation: AsyncStream<ServerMessage>.Continuation
    private let _messages: AsyncStream<ServerMessage>

    private var _state: ConnectionState = .disconnected
    private let lock = NSLock()

    // MARK: - Initialization

    nonisolated init(client: any WebSocketClientProtocol) {
        self.client = client

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

    convenience init(configuration: WebSocketClientConfiguration) {
        let client = WebSocketClient(configuration: configuration)
        self.init(client: client)
    }

    deinit {
        monitorTask?.cancel()
        messageForwardTask?.cancel()
        stateContinuation.finish()
        messageContinuation.finish()
    }

    // MARK: - ConnectionManagerProtocol

    var state: ConnectionState {
        get async {
            await client.connectionState
        }
    }

    nonisolated var stateChanges: AsyncStream<ConnectionState> {
        _stateChanges
    }

    nonisolated var messages: AsyncStream<ServerMessage> {
        _messages
    }

    func connect() async throws {
        startMonitoring()
        startForwardingMessages()
        try await client.connect()
    }

    func disconnect() async {
        monitorTask?.cancel()
        monitorTask = nil

        messageForwardTask?.cancel()
        messageForwardTask = nil

        await client.disconnect()
        updateState(.disconnected)
    }

    func send(_ message: ClientMessage) async throws {
        try await client.send(message)
    }

    // MARK: - Private Methods

    private func startMonitoring() {
        monitorTask?.cancel()
        monitorTask = Task { [weak self] in
            guard let self = self else { return }

            var previousState: ConnectionState?

            while !Task.isCancelled {
                let currentState = await self.client.connectionState

                if currentState != previousState {
                    self.updateState(currentState)
                    previousState = currentState
                }

                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
        }
    }

    private func startForwardingMessages() {
        messageForwardTask?.cancel()
        messageForwardTask = Task { [weak self] in
            guard let self = self else { return }

            for await message in self.client.messages {
                guard !Task.isCancelled else { break }
                self.messageContinuation.yield(message)
            }
        }
    }

    private func updateState(_ newState: ConnectionState) {
        lock.lock()
        _state = newState
        lock.unlock()

        stateContinuation.yield(newState)
    }
}

// MARK: - ConnectionManager Observable Properties

extension ConnectionManager {
    /// 현재 연결 상태 (동기 접근)
    var currentState: ConnectionState {
        lock.lock()
        defer { lock.unlock() }
        return _state
    }

    /// 연결 여부
    var isConnected: Bool {
        currentState == .connected
    }

    /// 재연결 중 여부
    var isReconnecting: Bool {
        if case .reconnecting = currentState {
            return true
        }
        return false
    }

    /// 에러 메시지 (실패 상태일 때)
    var errorMessage: String? {
        if case .failed(let error) = currentState {
            return error
        }
        return nil
    }
}
