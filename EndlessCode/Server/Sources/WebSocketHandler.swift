//
//  WebSocketHandler.swift
//  EndlessCode
//
//  WebSocket 핸들러 - 연결 관리, 인증, 메시지 라우팅, 재연결 지원
//

import Foundation

// MARK: - WebSocketConnection

/// WebSocket 연결 정보
struct WebSocketConnection: Sendable, Identifiable {
    let id: String
    let connectedAt: Date
    var lastPingAt: Date
    var subscribedSessions: Set<String>
}

// MARK: - WebSocketHandlerProtocol

/// WebSocket 핸들러 프로토콜
protocol WebSocketHandlerProtocol: Sendable {
    func handleConnection(connectionId: String, authToken: String?) async throws
    func handleDisconnection(connectionId: String) async
    func handleMessage(connectionId: String, data: Data) async
    func handleMessage(connectionId: String, message: ClientMessage) async throws
    func broadcast(message: ServerMessage, to sessionId: String) async
    func broadcastToAll(message: ServerMessage) async
}

// MARK: - WebSocketHandler

/// WebSocket 연결과 메시지를 관리하는 Actor
actor WebSocketHandler: WebSocketHandlerProtocol {
    private let configuration: ServerConfiguration
    private let sessionManager: SessionManagerProtocol

    /// 활성 연결 목록
    private var connections: [String: WebSocketConnection] = [:]

    /// 세션별 구독 연결 목록
    private var sessionSubscribers: [String: Set<String>] = [:]

    /// 메시지 전송 콜백 (실제 WebSocket 전송은 외부에서 구현)
    private var sendCallbacks: [String: @Sendable (Data) async throws -> Void] = [:]

    /// 연결 종료 콜백
    private var closeCallbacks: [String: @Sendable () async -> Void] = [:]

    /// 메시지 버퍼 (재연결 시 재전송용)
    private var messageBuffers: [String: [ServerMessage]] = [:]
    private let maxBufferSize = 100

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        configuration: ServerConfiguration,
        sessionManager: SessionManagerProtocol
    ) {
        self.configuration = configuration
        self.sessionManager = sessionManager

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    // MARK: - Connection Management

    func handleConnection(connectionId: String, authToken: String?) async throws {
        // 토큰 인증
        if let expectedToken = configuration.authToken {
            guard authToken == expectedToken else {
                throw WebSocketError.authenticationFailed
            }
        }

        // 연결 수 제한 확인
        guard connections.count < configuration.maxWebSocketConnections else {
            throw WebSocketError.connectionLimitExceeded
        }

        // 연결 등록
        let connection = WebSocketConnection(
            id: connectionId,
            connectedAt: Date(),
            lastPingAt: Date(),
            subscribedSessions: []
        )
        connections[connectionId] = connection

        // 초기 동기화 메시지 전송
        await sendInitialSync(to: connectionId)
    }

    func handleDisconnection(connectionId: String) async {
        guard let connection = connections[connectionId] else { return }

        // 세션 구독 정리
        for sessionId in connection.subscribedSessions {
            sessionSubscribers[sessionId]?.remove(connectionId)
        }

        // 연결 제거
        connections.removeValue(forKey: connectionId)
        sendCallbacks.removeValue(forKey: connectionId)
        closeCallbacks.removeValue(forKey: connectionId)
    }

    func registerSendCallback(
        connectionId: String,
        callback: @escaping @Sendable (Data) async throws -> Void
    ) {
        sendCallbacks[connectionId] = callback
    }

    func registerCloseCallback(
        connectionId: String,
        callback: @escaping @Sendable () async -> Void
    ) {
        closeCallbacks[connectionId] = callback
    }

    // MARK: - Message Handling

    func handleMessage(connectionId: String, data: Data) async {
        guard connections[connectionId] != nil else { return }

        do {
            let message = try decoder.decode(ClientMessage.self, from: data)
            await processClientMessage(connectionId: connectionId, message: message)
        } catch {
            await sendError(
                to: connectionId,
                code: .invalidMessage,
                message: "메시지 파싱 실패: \(error.localizedDescription)"
            )
        }
    }

    /// ClientMessage를 직접 받는 오버로드 (Routes.swift에서 사용)
    func handleMessage(connectionId: String, message: ClientMessage) async throws {
        guard connections[connectionId] != nil else {
            throw WebSocketError.connectionNotFound
        }
        await processClientMessage(connectionId: connectionId, message: message)
    }

    private func processClientMessage(
        connectionId: String,
        message: ClientMessage
    ) async {
        switch message {
        case .userMessage(let userMessage):
            await handleUserMessage(connectionId: connectionId, message: userMessage)

        case .promptResponse(let response):
            await handlePromptResponse(connectionId: connectionId, response: response)

        case .sessionControl(let control):
            await handleSessionControl(connectionId: connectionId, control: control)
        }
    }

    private func handleUserMessage(
        connectionId: String,
        message: UserMessage
    ) async {
        do {
            try await sessionManager.sendMessage(
                sessionId: message.sessionId,
                message: message.content
            )

            // 세션 구독
            subscribeToSession(connectionId: connectionId, sessionId: message.sessionId)
        } catch {
            await sendError(
                to: connectionId,
                code: .sessionNotFound,
                message: error.localizedDescription,
                sessionId: message.sessionId
            )
        }
    }

    private func handlePromptResponse(
        connectionId: String,
        response: PromptResponse
    ) async {
        // 응답 포맷팅
        let formattedResponse = formatPromptResponse(response)

        do {
            try await sessionManager.sendMessage(
                sessionId: response.sessionId,
                message: formattedResponse
            )
        } catch {
            await sendError(
                to: connectionId,
                code: .sessionNotFound,
                message: error.localizedDescription,
                sessionId: response.sessionId
            )
        }
    }

    private func handleSessionControl(
        connectionId: String,
        control: SessionControl
    ) async {
        do {
            switch control.action {
            case .start:
                guard let projectId = control.projectId else {
                    throw WebSocketError.missingParameter("projectId")
                }
                let session = try await sessionManager.createSession(projectId: projectId)
                subscribeToSession(connectionId: connectionId, sessionId: session.id)
                await sendSessionState(to: connectionId, sessionId: session.id, state: .active)

            case .pause:
                guard let sessionId = control.sessionId else {
                    throw WebSocketError.missingParameter("sessionId")
                }
                try await sessionManager.pauseSession(sessionId: sessionId)
                await sendSessionState(to: connectionId, sessionId: sessionId, state: .paused)

            case .resume:
                guard let sessionId = control.sessionId else {
                    throw WebSocketError.missingParameter("sessionId")
                }
                let session = try await sessionManager.resumeSession(sessionId: sessionId)
                subscribeToSession(connectionId: connectionId, sessionId: session.id)
                await sendSessionState(to: connectionId, sessionId: session.id, state: .active)

            case .terminate:
                guard let sessionId = control.sessionId else {
                    throw WebSocketError.missingParameter("sessionId")
                }
                try await sessionManager.terminateSession(sessionId: sessionId)
                await sendSessionState(to: connectionId, sessionId: sessionId, state: .terminated)
            }
        } catch {
            await sendError(
                to: connectionId,
                code: .internalError,
                message: error.localizedDescription,
                sessionId: control.sessionId
            )
        }
    }

    // MARK: - Broadcasting

    func broadcast(message: ServerMessage, to sessionId: String) async {
        // 메시지 버퍼링
        bufferMessage(message, for: sessionId)

        // 구독자에게 전송
        guard let subscribers = sessionSubscribers[sessionId] else { return }

        for connectionId in subscribers {
            await send(message: message, to: connectionId)
        }
    }

    func broadcastToAll(message: ServerMessage) async {
        for connectionId in connections.keys {
            await send(message: message, to: connectionId)
        }
    }

    // MARK: - Private Helpers

    private func subscribeToSession(connectionId: String, sessionId: String) {
        connections[connectionId]?.subscribedSessions.insert(sessionId)

        if sessionSubscribers[sessionId] == nil {
            sessionSubscribers[sessionId] = []
        }
        sessionSubscribers[sessionId]?.insert(connectionId)
    }

    private func send(message: ServerMessage, to connectionId: String) async {
        guard let callback = sendCallbacks[connectionId] else { return }

        do {
            let data = try encoder.encode(message)
            try await callback(data)
        } catch {
            // 전송 실패 - 연결 종료 고려
            print("WebSocket 메시지 전송 실패: \(error)")
        }
    }

    private func sendError(
        to connectionId: String,
        code: WebSocketErrorCode,
        message: String,
        sessionId: String? = nil
    ) async {
        let errorMessage = ErrorMessage(
            code: code.rawValue,
            message: message,
            sessionId: sessionId
        )
        await send(message: .error(errorMessage), to: connectionId)
    }

    private func sendSessionState(
        to connectionId: String,
        sessionId: String,
        state: SessionState,
        error: String? = nil
    ) async {
        let stateMessage = SessionStateMessage(
            sessionId: sessionId,
            state: state,
            error: error
        )
        await send(message: .sessionState(stateMessage), to: connectionId)
    }

    private func sendInitialSync(to connectionId: String) async {
        let sessions = await sessionManager.getAllSessions()
        let syncMessage = SyncMessage(sessions: sessions, recentMessages: [])
        await send(message: .sync(syncMessage), to: connectionId)
    }

    private func bufferMessage(_ message: ServerMessage, for sessionId: String) {
        if messageBuffers[sessionId] == nil {
            messageBuffers[sessionId] = []
        }

        messageBuffers[sessionId]?.append(message)

        // 버퍼 크기 제한
        if let count = messageBuffers[sessionId]?.count, count > maxBufferSize {
            messageBuffers[sessionId]?.removeFirst(count - maxBufferSize)
        }
    }

    private func formatPromptResponse(_ response: PromptResponse) -> String {
        // 선택된 옵션들을 CLI가 이해할 수 있는 형식으로 변환
        if let customInput = response.customInput, !customInput.isEmpty {
            return customInput
        }

        if response.selectedOptions.count == 1 {
            return response.selectedOptions[0]
        }

        return response.selectedOptions.joined(separator: ", ")
    }

    // MARK: - Ping/Pong

    func handlePing(connectionId: String) async {
        connections[connectionId]?.lastPingAt = Date()
    }

    func checkStaleConnections(timeout: TimeInterval) async {
        let now = Date()
        var staleConnections: [String] = []

        for (connectionId, connection) in connections {
            if now.timeIntervalSince(connection.lastPingAt) > timeout {
                staleConnections.append(connectionId)
            }
        }

        for connectionId in staleConnections {
            if let closeCallback = closeCallbacks[connectionId] {
                await closeCallback()
            }
            await handleDisconnection(connectionId: connectionId)
        }
    }

    // MARK: - Reconnection Support

    func handleReconnection(connectionId: String, lastMessageId: String?) async throws {
        guard connections[connectionId] != nil else {
            throw WebSocketError.connectionNotFound
        }

        // TODO: lastMessageId 이후의 버퍼된 메시지 재전송
        // 현재는 전체 동기화로 대체
        await sendInitialSync(to: connectionId)
    }

    // MARK: - Statistics

    var connectionCount: Int {
        connections.count
    }

    var activeSessionIds: [String] {
        Array(sessionSubscribers.keys)
    }
}

// MARK: - WebSocketError

/// WebSocket 에러
enum WebSocketError: Error, Sendable, Equatable {
    case authenticationFailed
    case connectionLimitExceeded
    case connectionNotFound
    case missingParameter(String)
    case invalidMessage
}

extension WebSocketError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "인증 실패"
        case .connectionLimitExceeded:
            return "연결 수 제한 초과"
        case .connectionNotFound:
            return "연결을 찾을 수 없음"
        case .missingParameter(let param):
            return "필수 파라미터 누락: \(param)"
        case .invalidMessage:
            return "잘못된 메시지 형식"
        }
    }
}
