//
//  ClaudeCodeManager.swift
//  EndlessCode
//
//  Claude CLI 프로세스 통합 관리 - 세션별 프로세스 관리, 에러 복구, 리소스 관리
//

import Foundation

// MARK: - ClaudeCodeManagerProtocol

/// Claude Code CLI 관리자 프로토콜
protocol ClaudeCodeManagerProtocol: Sendable {
    /// 새 세션 시작
    func startSession(
        sessionId: String,
        projectPath: String
    ) async throws -> AsyncStream<ParsedMessage>

    /// 기존 세션 재개
    func resumeSession(sessionId: String) async throws -> AsyncStream<ParsedMessage>

    /// 세션에 메시지 전송
    func sendMessage(sessionId: String, message: String) async throws

    /// 세션 종료
    func terminateSession(sessionId: String) async throws

    /// 세션 상태 조회
    func sessionState(sessionId: String) async -> SessionProcessState?

    /// 활성 세션 수
    var activeSessionCount: Int { get async }

    /// 유휴 세션 정리
    func cleanupIdleSessions(olderThan timeout: TimeInterval) async
}

// MARK: - SessionProcessState

/// 세션 프로세스 상태
struct SessionProcessState: Sendable, Equatable {
    let sessionId: String
    let projectPath: String
    var processState: ProcessState
    let startedAt: Date
    var lastActivityAt: Date
    var restartCount: Int
}

// MARK: - ClaudeCodeManager

/// Claude Code CLI 프로세스를 관리하는 Actor
actor ClaudeCodeManager: ClaudeCodeManagerProtocol {
    private let configuration: ServerConfiguration
    private let retryConfig: RetryConfiguration

    private var sessions: [String: ManagedSession] = [:]
    private var sessionStates: [String: SessionProcessState] = [:]

    init(
        configuration: ServerConfiguration = .fromEnvironment(),
        retryConfig: RetryConfiguration = .cliRestart
    ) {
        self.configuration = configuration
        self.retryConfig = retryConfig
    }

    // MARK: - Public API

    var activeSessionCount: Int {
        sessions.count
    }

    func startSession(
        sessionId: String,
        projectPath: String
    ) async throws -> AsyncStream<ParsedMessage> {
        // 세션 수 제한 확인
        guard sessions.count < configuration.maxConcurrentSessions else {
            throw ClaudeCodeError.sessionLimitExceeded(
                current: sessions.count,
                max: configuration.maxConcurrentSessions
            )
        }

        // 기존 세션 확인
        if sessions[sessionId] != nil {
            throw ClaudeCodeError.sessionAlreadyExists(sessionId: sessionId)
        }

        let runner = ProcessRunner.forClaudeCLI(
            cliPath: configuration.cliPath,
            projectPath: projectPath
        )

        let session = ManagedSession(
            sessionId: sessionId,
            projectPath: projectPath,
            runner: runner
        )

        sessions[sessionId] = session
        sessionStates[sessionId] = SessionProcessState(
            sessionId: sessionId,
            projectPath: projectPath,
            processState: .idle,
            startedAt: Date(),
            lastActivityAt: Date(),
            restartCount: 0
        )

        // 프로세스 시작
        try await runner.start()
        sessionStates[sessionId]?.lastActivityAt = Date()

        // 출력 스트림 생성
        return createParsedMessageStream(for: session)
    }

    func resumeSession(sessionId: String) async throws -> AsyncStream<ParsedMessage> {
        guard let session = sessions[sessionId] else {
            throw ClaudeCodeError.sessionNotFound(sessionId: sessionId)
        }

        let currentState = await session.runner.state
        guard case .terminated = currentState else {
            // 이미 실행 중이면 기존 스트림 반환
            return createParsedMessageStream(for: session)
        }

        // 재시작 시도
        try await restartSession(sessionId: sessionId)
        return createParsedMessageStream(for: session)
    }

    func sendMessage(sessionId: String, message: String) async throws {
        guard let session = sessions[sessionId] else {
            throw ClaudeCodeError.sessionNotFound(sessionId: sessionId)
        }

        let currentState = await session.runner.state
        guard case .running = currentState else {
            throw ClaudeCodeError.sessionNotRunning(sessionId: sessionId)
        }

        // 메시지 전송 (재시도 로직 포함)
        try await sendWithRetry(session: session, message: message)
        sessionStates[sessionId]?.lastActivityAt = Date()
    }

    func terminateSession(sessionId: String) async throws {
        guard let session = sessions[sessionId] else {
            throw ClaudeCodeError.sessionNotFound(sessionId: sessionId)
        }

        await session.runner.terminate()
        sessions.removeValue(forKey: sessionId)
        sessionStates.removeValue(forKey: sessionId)
    }

    func sessionState(sessionId: String) async -> SessionProcessState? {
        guard let state = sessionStates[sessionId],
              let session = sessions[sessionId] else {
            return nil
        }

        var updatedState = state
        updatedState.processState = await session.runner.state
        return updatedState
    }

    // MARK: - Private Methods

    private func createParsedMessageStream(for session: ManagedSession) -> AsyncStream<ParsedMessage> {
        AsyncStream { continuation in
            Task {
                let parser = JSONLParser()

                for await line in session.runner.stdout {
                    // 라인 단위로 분리
                    let lines = line.components(separatedBy: .newlines)
                    for singleLine in lines where !singleLine.isEmpty {
                        do {
                            let message = try parser.parse(line: singleLine)
                            continuation.yield(message)
                        } catch {
                            // 파싱 실패 시 unknown으로 처리
                            continuation.yield(.unknown(rawJSON: singleLine))
                        }
                    }
                }

                continuation.finish()
            }
        }
    }

    private func sendWithRetry(session: ManagedSession, message: String) async throws {
        var lastError: Error?

        for attempt in 0..<retryConfig.maxRetries {
            do {
                try await session.runner.writeLine(message)
                return
            } catch {
                lastError = error
                let delay = retryConfig.delay(forAttempt: attempt)
                try await Task.sleep(for: .seconds(delay))
            }
        }

        throw lastError ?? ClaudeCodeError.messageSendFailed(sessionId: session.sessionId)
    }

    private func restartSession(sessionId: String) async throws {
        guard let session = sessions[sessionId],
              var state = sessionStates[sessionId] else {
            throw ClaudeCodeError.sessionNotFound(sessionId: sessionId)
        }

        // 재시작 횟수 확인
        guard state.restartCount < retryConfig.maxRetries else {
            throw ClaudeCodeError.maxRestartsExceeded(
                sessionId: sessionId,
                count: state.restartCount
            )
        }

        // 지수 백오프 적용
        let delay = retryConfig.delay(forAttempt: state.restartCount)
        try await Task.sleep(for: .seconds(delay))

        // 새 ProcessRunner 생성
        let newRunner = ProcessRunner.forClaudeCLI(
            cliPath: configuration.cliPath,
            projectPath: session.projectPath,
            sessionId: sessionId,
            resume: true
        )

        // 세션 업데이트
        let newSession = ManagedSession(
            sessionId: sessionId,
            projectPath: session.projectPath,
            runner: newRunner
        )

        sessions[sessionId] = newSession

        // 프로세스 시작
        try await newRunner.start()

        // 상태 업데이트
        state.restartCount += 1
        state.lastActivityAt = Date()
        sessionStates[sessionId] = state
    }

    // MARK: - Zombie Process Cleanup

    /// 유휴 세션 정리
    func cleanupIdleSessions(olderThan timeout: TimeInterval) async {
        let now = Date()

        for (sessionId, state) in sessionStates {
            let idleTime = now.timeIntervalSince(state.lastActivityAt)
            if idleTime > timeout {
                try? await terminateSession(sessionId: sessionId)
            }
        }
    }

    /// 모든 세션 종료
    func terminateAllSessions() async {
        for sessionId in sessions.keys {
            try? await terminateSession(sessionId: sessionId)
        }
    }
}

// MARK: - ManagedSession

/// 관리되는 세션 정보
private struct ManagedSession: Sendable {
    let sessionId: String
    let projectPath: String
    let runner: ProcessRunner
}

// MARK: - ClaudeCodeError

/// Claude Code 관련 에러
enum ClaudeCodeError: Error, Sendable, Equatable {
    case sessionLimitExceeded(current: Int, max: Int)
    case sessionAlreadyExists(sessionId: String)
    case sessionNotFound(sessionId: String)
    case sessionNotRunning(sessionId: String)
    case messageSendFailed(sessionId: String)
    case maxRestartsExceeded(sessionId: String, count: Int)
    case cliNotFound(path: String)
    case timeout(sessionId: String)
}

extension ClaudeCodeError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .sessionLimitExceeded(let current, let max):
            return "세션 수 제한 초과 (\(current)/\(max))"
        case .sessionAlreadyExists(let sessionId):
            return "이미 존재하는 세션: \(sessionId)"
        case .sessionNotFound(let sessionId):
            return "세션을 찾을 수 없음: \(sessionId)"
        case .sessionNotRunning(let sessionId):
            return "세션이 실행 중이 아님: \(sessionId)"
        case .messageSendFailed(let sessionId):
            return "메시지 전송 실패: \(sessionId)"
        case .maxRestartsExceeded(let sessionId, let count):
            return "최대 재시작 횟수 초과 (\(count)): \(sessionId)"
        case .cliNotFound(let path):
            return "CLI를 찾을 수 없음: \(path)"
        case .timeout(let sessionId):
            return "세션 타임아웃: \(sessionId)"
        }
    }
}
