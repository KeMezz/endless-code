//
//  ProcessRunner.swift
//  EndlessCode
//
//  기본 Process 래퍼 - CLI 프로세스 시작/종료/stdin/stdout 관리
//

import Foundation

// MARK: - ProcessRunnerProtocol

/// 프로세스 실행기 프로토콜
protocol ProcessRunnerProtocol: Sendable {
    var processId: UUID { get }
    var state: ProcessState { get async }

    func start() async throws
    func terminate() async
    func write(_ input: String) async throws

    var stdout: AsyncStream<String> { get }
    var stderr: AsyncStream<String> { get }
}

// MARK: - ProcessState

/// 프로세스 상태
enum ProcessState: Sendable {
    case idle
    case running
    case terminated(exitCode: Int32)
    case failed(ProcessError)
}

extension ProcessState: Equatable {
    nonisolated static func == (lhs: ProcessState, rhs: ProcessState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.running, .running):
            return true
        case (.terminated(let l), .terminated(let r)):
            return l == r
        case (.failed(let l), .failed(let r)):
            return l == r
        default:
            return false
        }
    }
}

// MARK: - ProcessError

/// 프로세스 관련 에러
enum ProcessError: Error, Sendable, Equatable {
    case notFound(path: String)
    case alreadyRunning
    case notRunning
    case startFailed(String)
    case writeFailed(String)
    case terminated(exitCode: Int32)
    case timeout
}

extension ProcessError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notFound(let path):
            return "CLI를 찾을 수 없습니다: \(path)"
        case .alreadyRunning:
            return "프로세스가 이미 실행 중입니다"
        case .notRunning:
            return "프로세스가 실행 중이 아닙니다"
        case .startFailed(let reason):
            return "프로세스 시작 실패: \(reason)"
        case .writeFailed(let reason):
            return "입력 쓰기 실패: \(reason)"
        case .terminated(let exitCode):
            return "프로세스가 종료되었습니다 (exit code: \(exitCode))"
        case .timeout:
            return "프로세스 타임아웃"
        }
    }
}

// MARK: - ProcessRunner

/// CLI 프로세스를 관리하는 Actor
actor ProcessRunner: ProcessRunnerProtocol {
    nonisolated let processId: UUID
    private let executablePath: String
    private let arguments: [String]
    private let environment: [String: String]?
    private let workingDirectory: String?

    private var process: Process?
    private var stdinPipe: Pipe?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?

    private var _state: ProcessState = .idle
    var state: ProcessState { _state }

    private var stdoutContinuation: AsyncStream<String>.Continuation?
    private var stderrContinuation: AsyncStream<String>.Continuation?

    private let _stdout: AsyncStream<String>
    private let _stderr: AsyncStream<String>

    nonisolated var stdout: AsyncStream<String> { _stdout }
    nonisolated var stderr: AsyncStream<String> { _stderr }

    init(
        processId: UUID = UUID(),
        executablePath: String,
        arguments: [String] = [],
        environment: [String: String]? = nil,
        workingDirectory: String? = nil
    ) {
        self.processId = processId
        self.executablePath = executablePath
        self.arguments = arguments
        self.environment = environment
        self.workingDirectory = workingDirectory

        // AsyncStream.makeStream을 사용하여 즉시 continuation 설정
        let (stdoutStream, stdoutCont) = AsyncStream.makeStream(of: String.self)
        let (stderrStream, stderrCont) = AsyncStream.makeStream(of: String.self)

        self._stdout = stdoutStream
        self._stderr = stderrStream
        self.stdoutContinuation = stdoutCont
        self.stderrContinuation = stderrCont
    }

    func start() async throws {
        guard _state == .idle else {
            throw ProcessError.alreadyRunning
        }

        // CLI 경로 확인
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: executablePath) else {
            throw ProcessError.notFound(path: executablePath)
        }

        let newProcess = Process()
        newProcess.executableURL = URL(fileURLWithPath: executablePath)
        newProcess.arguments = arguments

        // 환경 변수 설정
        if let env = environment {
            var processEnv = ProcessInfo.processInfo.environment
            for (key, value) in env {
                processEnv[key] = value
            }
            newProcess.environment = processEnv
        }

        // 작업 디렉토리 설정
        if let workDir = workingDirectory {
            newProcess.currentDirectoryURL = URL(fileURLWithPath: workDir)
        }

        // Pipe 설정
        let stdin = Pipe()
        let stdout = Pipe()
        let stderr = Pipe()

        newProcess.standardInput = stdin
        newProcess.standardOutput = stdout
        newProcess.standardError = stderr

        self.stdinPipe = stdin
        self.stdoutPipe = stdout
        self.stderrPipe = stderr

        // stdout 읽기 설정
        setupOutputReading(pipe: stdout, continuation: stdoutContinuation)
        setupOutputReading(pipe: stderr, continuation: stderrContinuation)

        // 종료 핸들러 설정
        newProcess.terminationHandler = { [weak self] proc in
            Task {
                await self?.handleTermination(exitCode: proc.terminationStatus)
            }
        }

        do {
            try newProcess.run()
            self.process = newProcess
            self._state = .running
        } catch {
            throw ProcessError.startFailed(error.localizedDescription)
        }
    }

    private func setupOutputReading(
        pipe: Pipe,
        continuation: AsyncStream<String>.Continuation?
    ) {
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                continuation?.finish()
                return
            }

            if let string = String(data: data, encoding: .utf8) {
                continuation?.yield(string)
            }
        }
    }

    private func handleTermination(exitCode: Int32) {
        _state = .terminated(exitCode: exitCode)

        stdoutContinuation?.finish()
        stderrContinuation?.finish()

        // Pipe cleanup
        stdoutPipe?.fileHandleForReading.readabilityHandler = nil
        stderrPipe?.fileHandleForReading.readabilityHandler = nil

        process = nil
        stdinPipe = nil
        stdoutPipe = nil
        stderrPipe = nil
    }

    func terminate() async {
        guard let proc = process, proc.isRunning else {
            return
        }

        proc.terminate()

        // 종료 대기 (최대 5초)
        for _ in 0..<50 {
            if !proc.isRunning {
                return
            }
            try? await Task.sleep(for: .milliseconds(100))
        }

        // 강제 종료
        if proc.isRunning {
            proc.interrupt()
        }
    }

    func write(_ input: String) async throws {
        guard case .running = _state else {
            throw ProcessError.notRunning
        }

        guard let pipe = stdinPipe else {
            throw ProcessError.writeFailed("stdin pipe not available")
        }

        guard let data = input.data(using: .utf8) else {
            throw ProcessError.writeFailed("Failed to encode input as UTF-8")
        }

        do {
            try pipe.fileHandleForWriting.write(contentsOf: data)
        } catch {
            throw ProcessError.writeFailed(error.localizedDescription)
        }
    }

    /// stdin에 줄바꿈과 함께 입력 쓰기
    func writeLine(_ input: String) async throws {
        try await write(input + "\n")
    }
}

// MARK: - ProcessRunner Factory

extension ProcessRunner {
    /// Claude CLI 실행용 ProcessRunner 생성
    nonisolated static func forClaudeCLI(
        cliPath: String,
        projectPath: String,
        sessionId: String? = nil,
        resume: Bool = false
    ) -> ProcessRunner {
        var arguments = ["--print", "--output-format", "stream-json"]

        if let sessionId = sessionId, resume {
            arguments.append(contentsOf: ["--resume", sessionId])
        }

        return ProcessRunner(
            executablePath: cliPath,
            arguments: arguments,
            workingDirectory: projectPath
        )
    }
}
