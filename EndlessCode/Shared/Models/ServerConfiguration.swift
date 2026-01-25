//
//  ServerConfiguration.swift
//  EndlessCode
//
//  서버 설정 모델
//

import Foundation

// MARK: - ServerConfiguration

/// 서버 설정
struct ServerConfiguration: Codable, Sendable, Equatable {
    /// 서버 호스트 (기본: localhost)
    var host: String

    /// 서버 포트 (기본: 8080)
    var port: Int

    /// Claude CLI 실행 경로
    var cliPath: String

    /// 최대 동시 세션 수
    var maxConcurrentSessions: Int

    /// 최대 WebSocket 연결 수
    var maxWebSocketConnections: Int

    /// 세션 타임아웃 (초)
    var sessionTimeoutSeconds: Int

    /// 프롬프트 타임아웃 (초)
    var promptTimeoutSeconds: Int

    /// 로그 레벨
    var logLevel: LogLevel

    /// TLS 활성화 여부
    var tlsEnabled: Bool

    /// 인증 토큰 (nil이면 인증 비활성화)
    var authToken: String?

    nonisolated init(
        host: String = "127.0.0.1",
        port: Int = 8080,
        cliPath: String = "/usr/local/bin/claude",
        maxConcurrentSessions: Int = 5,
        maxWebSocketConnections: Int = 100,
        sessionTimeoutSeconds: Int = 30,
        promptTimeoutSeconds: Int = 1800,
        logLevel: LogLevel = .info,
        tlsEnabled: Bool = false,
        authToken: String? = nil
    ) {
        self.host = host
        self.port = port
        self.cliPath = cliPath
        self.maxConcurrentSessions = maxConcurrentSessions
        self.maxWebSocketConnections = maxWebSocketConnections
        self.sessionTimeoutSeconds = sessionTimeoutSeconds
        self.promptTimeoutSeconds = promptTimeoutSeconds
        self.logLevel = logLevel
        self.tlsEnabled = tlsEnabled
        self.authToken = authToken
    }

    /// 환경 변수에서 설정 로드
    nonisolated static func fromEnvironment() -> ServerConfiguration {
        var config = ServerConfiguration()

        if let host = ProcessInfo.processInfo.environment["ENDLESSCODE_HOST"] {
            config.host = host
        }

        if let portStr = ProcessInfo.processInfo.environment["ENDLESSCODE_PORT"],
           let port = Int(portStr) {
            config.port = port
        }

        if let cliPath = ProcessInfo.processInfo.environment["CLAUDE_CLI_PATH"] {
            config.cliPath = cliPath
        }

        if let maxSessions = ProcessInfo.processInfo.environment["ENDLESSCODE_MAX_SESSIONS"],
           let max = Int(maxSessions) {
            config.maxConcurrentSessions = max
        }

        if let logLevelStr = ProcessInfo.processInfo.environment["ENDLESSCODE_LOG_LEVEL"],
           let level = LogLevel(rawValue: logLevelStr.lowercased()) {
            config.logLevel = level
        }

        if let tlsStr = ProcessInfo.processInfo.environment["ENDLESSCODE_TLS_ENABLED"] {
            config.tlsEnabled = tlsStr.lowercased() == "true" || tlsStr == "1"
        }

        if let token = ProcessInfo.processInfo.environment["ENDLESSCODE_AUTH_TOKEN"] {
            config.authToken = token
        }

        return config
    }

    /// WebSocket URL 생성
    var webSocketURL: URL? {
        let scheme = tlsEnabled ? "wss" : "ws"
        return URL(string: "\(scheme)://\(host):\(port)/ws")
    }

    /// HTTP URL 생성
    var httpURL: URL? {
        let scheme = tlsEnabled ? "https" : "http"
        return URL(string: "\(scheme)://\(host):\(port)")
    }
}

// MARK: - LogLevel

/// 로그 레벨
enum LogLevel: String, Codable, Sendable, CaseIterable {
    case trace
    case debug
    case info
    case warning
    case error
    case critical
}

// MARK: - PerformanceLimits

/// 성능 관련 제한 설정
struct PerformanceLimits: Codable, Sendable, Equatable {
    /// 세션당 메시지 버퍼 크기 (바이트)
    let messageBufferSize: Int

    /// Tree-sitter 파서 캐시 크기 (바이트)
    let parserCacheSize: Int

    /// 파일 뷰어 캐시 크기 (바이트)
    let fileViewerCacheSize: Int

    /// WebSocket 버퍼 크기 (바이트)
    let webSocketBufferSize: Int

    /// 최대 앱 메모리 (바이트)
    let maxAppMemory: Int

    /// 동시 파일 로드 수
    let concurrentFileLoads: Int

    /// 백그라운드 작업 수
    let backgroundTaskLimit: Int

    /// 단일 메시지 최대 크기 (바이트)
    let maxMessageSize: Int

    /// 코드 블록 최대 크기 (바이트)
    let maxCodeBlockSize: Int

    /// 파일 미리보기 최대 크기 (바이트)
    let maxFilePreviewSize: Int

    /// Diff 최대 파일 수
    let maxDiffFiles: Int

    /// 디렉토리 최대 깊이
    let maxDirectoryDepth: Int

    /// 디렉토리 최대 항목 수
    let maxDirectoryItems: Int

    static let `default` = PerformanceLimits(
        messageBufferSize: 50 * 1024 * 1024,       // 50MB
        parserCacheSize: 100 * 1024 * 1024,        // 100MB
        fileViewerCacheSize: 20 * 1024 * 1024,     // 20MB
        webSocketBufferSize: 10 * 1024 * 1024,     // 10MB
        maxAppMemory: 500 * 1024 * 1024,           // 500MB
        concurrentFileLoads: 3,
        backgroundTaskLimit: 4,
        maxMessageSize: 1 * 1024 * 1024,           // 1MB
        maxCodeBlockSize: 1 * 1024 * 1024,         // 1MB
        maxFilePreviewSize: 1 * 1024 * 1024,       // 1MB
        maxDiffFiles: 100,
        maxDirectoryDepth: 50,
        maxDirectoryItems: 1000
    )
}

// MARK: - RetryConfiguration

/// 재시도 설정
struct RetryConfiguration: Codable, Sendable, Equatable {
    /// 최대 재시도 횟수
    let maxRetries: Int

    /// 초기 지연 시간 (밀리초)
    let initialDelayMs: Int

    /// 최대 지연 시간 (밀리초)
    let maxDelayMs: Int

    /// 지수 백오프 승수
    let backoffMultiplier: Double

    /// 지정된 시도 횟수에 대한 지연 시간 계산
    nonisolated func delay(forAttempt attempt: Int) -> TimeInterval {
        let delayMs = Double(initialDelayMs) * pow(backoffMultiplier, Double(attempt))
        let clampedDelayMs = min(delayMs, Double(maxDelayMs))
        return clampedDelayMs / 1000.0
    }

    /// WebSocket 재연결용 기본 설정
    nonisolated static let webSocketReconnect = RetryConfiguration(
        maxRetries: 10,
        initialDelayMs: 1000,
        maxDelayMs: 60000,
        backoffMultiplier: 2.0
    )

    /// 메시지 전송용 기본 설정
    nonisolated static let messageSend = RetryConfiguration(
        maxRetries: 3,
        initialDelayMs: 100,
        maxDelayMs: 1000,
        backoffMultiplier: 2.0
    )

    /// CLI 프로세스 재시작용 기본 설정
    nonisolated static let cliRestart = RetryConfiguration(
        maxRetries: 3,
        initialDelayMs: 500,
        maxDelayMs: 5000,
        backoffMultiplier: 2.0
    )
}
