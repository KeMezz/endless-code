//
//  WebSocketClient.swift
//  EndlessCode
//
//  WebSocket 클라이언트 - 연결/해제, 메시지 송수신, 자동 재연결
//

import Foundation

// MARK: - WebSocketClientProtocol

/// WebSocket 클라이언트 프로토콜
protocol WebSocketClientProtocol: Sendable {
    /// 서버에 연결
    func connect() async throws

    /// 연결 해제
    func disconnect() async

    /// 메시지 전송
    func send(_ message: ClientMessage) async throws

    /// 수신 메시지 스트림
    var messages: AsyncStream<ServerMessage> { get }

    /// 연결 상태 변경 스트림
    var stateChanges: AsyncStream<ConnectionState> { get }

    /// 연결 상태
    var connectionState: ConnectionState { get async }
}

// MARK: - WebSocketClientError

/// WebSocket 클라이언트 에러
enum WebSocketClientError: Error, LocalizedError, Sendable {
    case invalidURL
    case connectionFailed(underlying: String)
    case notConnected
    case sendFailed(underlying: String)
    case authenticationFailed
    case maxReconnectAttemptsExceeded

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid WebSocket URL"
        case .connectionFailed(let underlying):
            return "Connection failed: \(underlying)"
        case .notConnected:
            return "Not connected to server"
        case .sendFailed(let underlying):
            return "Failed to send message: \(underlying)"
        case .authenticationFailed:
            return "Authentication failed"
        case .maxReconnectAttemptsExceeded:
            return "Maximum reconnection attempts exceeded"
        }
    }
}

// MARK: - WebSocketClientConfiguration

/// WebSocket 클라이언트 설정
struct WebSocketClientConfiguration: Sendable {
    let serverURL: URL
    let authToken: String
    let maxReconnectAttempts: Int
    let initialReconnectDelay: TimeInterval
    let maxReconnectDelay: TimeInterval
    let pingInterval: TimeInterval

    init(
        serverURL: URL,
        authToken: String,
        maxReconnectAttempts: Int = 10,
        initialReconnectDelay: TimeInterval = 1.0,
        maxReconnectDelay: TimeInterval = 60.0,
        pingInterval: TimeInterval = 30.0
    ) {
        self.serverURL = serverURL
        self.authToken = authToken
        self.maxReconnectAttempts = maxReconnectAttempts
        self.initialReconnectDelay = initialReconnectDelay
        self.maxReconnectDelay = maxReconnectDelay
        self.pingInterval = pingInterval
    }
}

// MARK: - WebSocketClient

/// WebSocket 클라이언트 구현
actor WebSocketClient: WebSocketClientProtocol {
    // MARK: - Properties

    private let configuration: WebSocketClientConfiguration
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    private var _connectionState: ConnectionState = .disconnected {
        didSet {
            if _connectionState != oldValue {
                stateContinuation.yield(_connectionState)
            }
        }
    }
    private var reconnectAttempt: Int = 0
    private var shouldReconnect: Bool = false
    private var pingTask: Task<Void, Never>?
    private var receiveTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?

    private let messageContinuation: AsyncStream<ServerMessage>.Continuation
    private let _messages: AsyncStream<ServerMessage>

    private let stateContinuation: AsyncStream<ConnectionState>.Continuation
    private let _stateChanges: AsyncStream<ConnectionState>

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Initialization

    init(configuration: WebSocketClientConfiguration) {
        self.configuration = configuration
        self.urlSession = URLSession(configuration: .default)

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

        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }

    deinit {
        messageContinuation.finish()
        stateContinuation.finish()
    }

    // MARK: - WebSocketClientProtocol

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
        guard _connectionState != .connected && _connectionState != .connecting else {
            return
        }

        _connectionState = .connecting
        shouldReconnect = true
        reconnectAttempt = 0

        try await performConnect()
    }

    func disconnect() async {
        shouldReconnect = false
        await cleanup()
        _connectionState = .disconnected
    }

    func send(_ message: ClientMessage) async throws {
        guard let webSocketTask = webSocketTask,
              webSocketTask.state == .running else {
            throw WebSocketClientError.notConnected
        }

        do {
            let data = try encoder.encode(message)
            try await webSocketTask.send(.data(data))
        } catch {
            throw WebSocketClientError.sendFailed(underlying: error.localizedDescription)
        }
    }

    // MARK: - Private Methods

    private func performConnect() async throws {
        var request = URLRequest(url: configuration.serverURL)
        request.setValue("Bearer \(configuration.authToken)", forHTTPHeaderField: "Authorization")

        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()

        // Wait for connection to be established
        do {
            // Send a ping to verify connection
            try await sendPingAndWait()
            _connectionState = .connected
            reconnectAttempt = 0

            startReceiving()
            startPinging()
        } catch {
            await cleanup()
            throw WebSocketClientError.connectionFailed(underlying: error.localizedDescription)
        }
    }

    private func sendPingAndWait() async throws {
        guard let webSocketTask = webSocketTask else {
            throw WebSocketClientError.notConnected
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            webSocketTask.sendPing { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func startReceiving() {
        receiveTask?.cancel()
        receiveTask = Task { [weak self] in
            guard let self = self else { return }

            while !Task.isCancelled {
                do {
                    guard let webSocketTask = await self.webSocketTask else { break }

                    let message = try await webSocketTask.receive()
                    await self.handleReceivedMessage(message)
                } catch {
                    if !Task.isCancelled {
                        await self.handleDisconnection(error: error)
                    }
                    break
                }
            }
        }
    }

    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message) async {
        do {
            let data: Data
            switch message {
            case .data(let d):
                data = d
            case .string(let s):
                data = Data(s.utf8)
            @unknown default:
                return
            }

            let serverMessage = try decoder.decode(ServerMessage.self, from: data)
            messageContinuation.yield(serverMessage)
        } catch {
            // Log parsing error but don't disconnect
            print("Failed to parse message: \(error)")
        }
    }

    private func handleDisconnection(error: Error) async {
        await cleanup()

        if shouldReconnect {
            await attemptReconnect()
        } else {
            _connectionState = .failed(error: error.localizedDescription)
        }
    }

    private func attemptReconnect() async {
        guard shouldReconnect else { return }
        guard reconnectAttempt < configuration.maxReconnectAttempts else {
            _connectionState = .failed(error: WebSocketClientError.maxReconnectAttemptsExceeded.localizedDescription)
            return
        }

        reconnectAttempt += 1
        _connectionState = .reconnecting(attempt: reconnectAttempt)

        // Exponential backoff with jitter
        let delay = calculateReconnectDelay()

        reconnectTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            guard !Task.isCancelled && shouldReconnect else { return }

            do {
                try await performConnect()
            } catch {
                await attemptReconnect()
            }
        }
    }

    private func calculateReconnectDelay() -> TimeInterval {
        let exponentialDelay = configuration.initialReconnectDelay * pow(2.0, Double(reconnectAttempt - 1))
        let cappedDelay = min(exponentialDelay, configuration.maxReconnectDelay)
        // Add jitter (0-25%)
        let jitter = cappedDelay * Double.random(in: 0...0.25)
        return cappedDelay + jitter
    }

    private func startPinging() {
        pingTask?.cancel()
        pingTask = Task { [weak self] in
            guard let self = self else { return }

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(configuration.pingInterval * 1_000_000_000))

                guard !Task.isCancelled else { break }

                do {
                    try await self.sendPingAndWait()
                } catch {
                    if !Task.isCancelled {
                        await self.handleDisconnection(error: error)
                    }
                    break
                }
            }
        }
    }

    private func cleanup() async {
        pingTask?.cancel()
        pingTask = nil

        receiveTask?.cancel()
        receiveTask = nil

        reconnectTask?.cancel()
        reconnectTask = nil

        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
}
