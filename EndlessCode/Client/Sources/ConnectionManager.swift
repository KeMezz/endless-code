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
actor ConnectionManager: ConnectionManagerProtocol {
    // MARK: - Properties

    private let client: any WebSocketClientProtocol
    private var stateMonitorTask: Task<Void, Never>?
    private var messageForwardTask: Task<Void, Never>?

    private let stateContinuation: AsyncStream<ConnectionState>.Continuation
    private let _stateChanges: AsyncStream<ConnectionState>

    private let messageContinuation: AsyncStream<ServerMessage>.Continuation
    private let _messages: AsyncStream<ServerMessage>

    private var _currentState: ConnectionState = .disconnected

    // MARK: - Initialization

    init(client: any WebSocketClientProtocol) {
        self.client = client

        let streams = Self.makeStreams()
        self._stateChanges = streams.stateStream
        self.stateContinuation = streams.stateCont
        self._messages = streams.messageStream
        self.messageContinuation = streams.msgCont
    }

    init(configuration: WebSocketClientConfiguration) {
        let client = WebSocketClient(configuration: configuration)
        self.client = client

        let streams = Self.makeStreams()
        self._stateChanges = streams.stateStream
        self.stateContinuation = streams.stateCont
        self._messages = streams.messageStream
        self.messageContinuation = streams.msgCont
    }

    private static func makeStreams() -> (
        stateStream: AsyncStream<ConnectionState>,
        stateCont: AsyncStream<ConnectionState>.Continuation,
        messageStream: AsyncStream<ServerMessage>,
        msgCont: AsyncStream<ServerMessage>.Continuation
    ) {
        var stateCont: AsyncStream<ConnectionState>.Continuation!
        let stateStream = AsyncStream<ConnectionState> { cont in
            stateCont = cont
        }

        var msgCont: AsyncStream<ServerMessage>.Continuation!
        let messageStream = AsyncStream<ServerMessage> { cont in
            msgCont = cont
        }

        return (stateStream, stateCont, messageStream, msgCont)
    }

    deinit {
        stateMonitorTask?.cancel()
        messageForwardTask?.cancel()
        stateContinuation.finish()
        messageContinuation.finish()
    }

    // MARK: - ConnectionManagerProtocol

    var state: ConnectionState {
        _currentState
    }

    nonisolated var stateChanges: AsyncStream<ConnectionState> {
        _stateChanges
    }

    nonisolated var messages: AsyncStream<ServerMessage> {
        _messages
    }

    func connect() async throws {
        startStateMonitoring()
        startForwardingMessages()
        try await client.connect()
    }

    func disconnect() async {
        stateMonitorTask?.cancel()
        stateMonitorTask = nil

        messageForwardTask?.cancel()
        messageForwardTask = nil

        await client.disconnect()
        updateState(.disconnected)
    }

    func send(_ message: ClientMessage) async throws {
        try await client.send(message)
    }

    // MARK: - Private Methods

    private func startStateMonitoring() {
        stateMonitorTask?.cancel()
        stateMonitorTask = Task {
            for await newState in client.stateChanges {
                guard !Task.isCancelled else { break }
                await updateState(newState)
            }
        }
    }

    private func startForwardingMessages() {
        messageForwardTask?.cancel()
        messageForwardTask = Task {
            for await message in client.messages {
                guard !Task.isCancelled else { break }
                messageContinuation.yield(message)
            }
        }
    }

    private func updateState(_ newState: ConnectionState) {
        guard _currentState != newState else { return }
        _currentState = newState
        stateContinuation.yield(newState)
    }
}

// MARK: - ConnectionManagerObservableState

/// SwiftUI 연동을 위한 Observable 상태 래퍼
/// ConnectionManager actor의 상태를 MainActor에서 관찰 가능하게 제공
@MainActor
@Observable
final class ConnectionManagerObservableState {
    // MARK: - Properties

    private(set) var currentState: ConnectionState = .disconnected
    private var stateTask: Task<Void, Never>?

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /// ConnectionManager의 상태 변경 감시 시작
    func observe(_ manager: ConnectionManager) {
        stateTask?.cancel()
        stateTask = Task { [weak self] in
            for await state in manager.stateChanges {
                guard !Task.isCancelled else { break }
                self?.currentState = state
            }
        }
    }

    /// 감시 중지
    func stopObserving() {
        stateTask?.cancel()
        stateTask = nil
    }

    // MARK: - Computed Properties

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
