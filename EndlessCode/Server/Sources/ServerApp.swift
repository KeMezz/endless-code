//
//  ServerApp.swift
//  EndlessCode
//
//  서버 애플리케이션 엔트리포인트
//

import Foundation

// MARK: - ServerApp

/// 서버 애플리케이션
@MainActor
final class ServerApp {
    private let configuration: ServerConfiguration
    private var sessionManager: SessionManager?
    private var promptManager: PromptManager?
    private var webSocketHandler: WebSocketHandler?

    private var isRunning = false
    private var cleanupTask: Task<Void, Never>?

    init(configuration: ServerConfiguration = .fromEnvironment()) {
        self.configuration = configuration
    }

    // MARK: - Lifecycle

    func start() async throws {
        guard !isRunning else { return }

        isRunning = true

        // 매니저 초기화
        sessionManager = SessionManager.createDefault(configuration: configuration)
        promptManager = PromptManager(timeoutSeconds: configuration.promptTimeoutSeconds)

        // WebSocket 핸들러 초기화
        if let sessionManager = sessionManager {
            webSocketHandler = WebSocketHandler(
                configuration: configuration,
                sessionManager: sessionManager
            )
        }

        // 정기 정리 작업 시작
        startCleanupTask()

        print("EndlessCode 서버 시작됨")
        print("  - 호스트: \(configuration.host)")
        print("  - 포트: \(configuration.port)")
        print("  - CLI 경로: \(configuration.cliPath)")
    }

    func stop() async {
        guard isRunning else { return }

        isRunning = false

        // 정리 작업 취소
        cleanupTask?.cancel()
        cleanupTask = nil

        // 모든 세션 종료
        await sessionManager?.terminateAllSessions()

        // 프롬프트 정리
        await promptManager?.cleanupAll()

        print("EndlessCode 서버 종료됨")
    }

    // MARK: - Message Processing

    func handleCLIMessage(sessionId: String, message: ParsedMessage) async {
        // AskUserQuestion 감지
        if let question = message.askUserQuestion {
            if let prompt = await promptManager?.registerPrompt(
                sessionId: sessionId,
                question: question
            ) {
                // 클라이언트에 프롬프트 요청 전송
                let request = PromptRequest(
                    sessionId: sessionId,
                    promptId: prompt.id,
                    question: question,
                    timeout: configuration.promptTimeoutSeconds
                )

                await webSocketHandler?.broadcast(
                    message: .promptRequest(request),
                    to: sessionId
                )
            }
        } else {
            // 일반 메시지 브로드캐스트
            let output = CLIOutput(sessionId: sessionId, message: message)
            await webSocketHandler?.broadcast(message: .cliOutput(output), to: sessionId)
        }
    }

    // MARK: - Event Handlers

    private func handleSessionStateChange(sessionId: String, state: SessionState) async {
        let stateMessage = SessionStateMessage(sessionId: sessionId, state: state)
        await webSocketHandler?.broadcast(message: .sessionState(stateMessage), to: sessionId)

        // 세션 종료 시 프롬프트 정리
        if state == .terminated {
            await promptManager?.cleanup(sessionId: sessionId)
        }
    }

    private func handlePromptStateChange(prompt: PendingPrompt) async {
        switch prompt.state {
        case .timedOut:
            // 타임아웃 에러 전송
            let error = ErrorMessage(
                code: WebSocketErrorCode.cliTimeout.rawValue,
                message: "프롬프트 응답 대기 시간이 초과되었습니다",
                sessionId: prompt.sessionId
            )
            await webSocketHandler?.broadcast(message: .error(error), to: prompt.sessionId)

        case .cancelled:
            // 취소 알림 (필요한 경우)
            break

        case .responded, .pending:
            // 응답됨 또는 대기 중 - 별도 처리 없음
            break
        }
    }

    // MARK: - Cleanup

    private func startCleanupTask() {
        cleanupTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60)) // 1분마다 실행

                guard let self = self, self.isRunning else { break }

                // 유휴 세션 정리
                let timeout = TimeInterval(self.configuration.sessionTimeoutSeconds)
                await self.sessionManager?.cleanupIdleSessions(timeout: timeout)

                // 만료된 프롬프트 정리
                if let expiredPrompts = await self.promptManager?.cleanupExpiredPrompts() {
                    for prompt in expiredPrompts {
                        await self.handlePromptStateChange(prompt: prompt)
                    }
                }

                // 오래된 WebSocket 연결 정리
                await self.webSocketHandler?.checkStaleConnections(timeout: 120) // 2분
            }
        }
    }

    // MARK: - Statistics

    func statistics() async -> ServerStatistics {
        let activeSessions = await sessionManager?.activeSessionCount ?? 0
        let connectionCount = await webSocketHandler?.connectionCount ?? 0
        let pendingPrompts = await promptManager?.getAllPendingPrompts().count ?? 0

        return ServerStatistics(
            isRunning: isRunning,
            activeSessions: activeSessions,
            totalSessions: activeSessions,
            activeConnections: connectionCount,
            pendingPrompts: pendingPrompts
        )
    }

    // MARK: - Accessors

    var activeSessionCount: Int {
        get async {
            await sessionManager?.activeSessionCount ?? 0
        }
    }

    /// Routes.swift에서 사용하는 accessor 메서드들
    func getSessionManager() -> SessionManager? {
        sessionManager
    }

    func getWebSocketHandler() -> WebSocketHandler? {
        webSocketHandler
    }

    func getConfiguration() -> ServerConfiguration {
        configuration
    }
}

// MARK: - ServerStatistics

/// 서버 통계
struct ServerStatistics: Sendable {
    let isRunning: Bool
    let activeSessions: Int
    let totalSessions: Int
    let activeConnections: Int
    let pendingPrompts: Int
}

// MARK: - SessionManager Extensions

extension SessionManager {
    var activeSessionCount: Int {
        get async {
            await getAllSessions().filter { $0.state == .active }.count
        }
    }
}
