import Foundation

/// Claude Code CLI 이벤트
public enum ClaudeCodeEvent: Sendable {
    case systemInit(SystemInitMessage)
    case assistantMessage(AssistantMessage)
    case askUserQuestion(toolId: String, input: AskUserQuestionInput)
    case textOutput(String)
    case result(ResultMessage)
    case error(any Error)
    case processExited(Int32)
}

/// Claude Code CLI 관리자
@MainActor
public final class ClaudeCodeManager {
    private var process: Process?
    private var stdinPipe: Pipe?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?

    private var outputBuffer = ""
    private let decoder = JSONDecoder()

    public var onEvent: (@MainActor (ClaudeCodeEvent) -> Void)?

    private let claudePath: String
    private let workingDirectory: String

    public init(
        claudePath: String? = nil,
        workingDirectory: String = FileManager.default.currentDirectoryPath
    ) {
        self.claudePath = claudePath ?? Self.findClaudePath() ?? "/usr/local/bin/claude"
        self.workingDirectory = workingDirectory
    }

    /// PATH에서 claude 실행 파일 찾기
    nonisolated private static func findClaudePath() -> String? {
        // 일반적인 설치 경로들을 먼저 확인
        let commonPaths = [
            "\(NSHomeDirectory())/.local/bin/claude",
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude"
        ]

        for path in commonPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        // which 명령어로 찾기
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = ["claude"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !path.isEmpty {
                return path
            }
        } catch {
            // 무시
        }

        return nil
    }

    deinit {
        process?.terminate()
    }

    // MARK: - Process Control

    /// CLI 프로세스 시작
    public func start() throws {
        guard process == nil else {
            throw ClaudeCodeError.alreadyRunning
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: claudePath)
        process.arguments = [
            "-p",
            "--input-format=stream-json",
            "--output-format=stream-json",
            "--verbose"
        ]
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)

        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        // stdout 읽기 핸들러
        stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }

            if let str = String(data: data, encoding: .utf8) {
                Task { @MainActor [weak self] in
                    self?.handleOutput(str)
                }
            }
        }

        // stderr 읽기 핸들러
        stderrPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }

            if let str = String(data: data, encoding: .utf8) {
                Task { @MainActor [weak self] in
                    self?.onEvent?(.error(ClaudeCodeError.stderrOutput(str)))
                }
            }
        }

        // 프로세스 종료 핸들러
        process.terminationHandler = { [weak self] proc in
            let status = proc.terminationStatus
            Task { @MainActor [weak self] in
                self?.onEvent?(.processExited(status))
                self?.cleanup()
            }
        }

        try process.run()

        self.process = process
        self.stdinPipe = stdinPipe
        self.stdoutPipe = stdoutPipe
        self.stderrPipe = stderrPipe
    }

    /// CLI 프로세스 중지
    public func stop() {
        process?.terminate()
        cleanup()
    }

    private func cleanup() {
        stdinPipe?.fileHandleForWriting.closeFile()
        stdoutPipe?.fileHandleForReading.readabilityHandler = nil
        stderrPipe?.fileHandleForReading.readabilityHandler = nil
        process = nil
        stdinPipe = nil
        stdoutPipe = nil
        stderrPipe = nil
        outputBuffer = ""
    }

    // MARK: - Message Handling

    /// stdout 출력 처리
    private func handleOutput(_ output: String) {
        outputBuffer += output

        // 라인별로 분리
        var lines = outputBuffer.components(separatedBy: "\n")
        outputBuffer = lines.removeLast() // 마지막 불완전한 라인 보관

        for line in lines where !line.isEmpty {
            parseJSONLine(line)
        }
    }

    /// JSONL 파싱
    private func parseJSONLine(_ line: String) {
        guard let data = line.data(using: .utf8) else { return }

        // 먼저 기본 타입 확인
        guard let baseMessage = try? decoder.decode(CLIMessage.self, from: data) else {
            return
        }

        switch baseMessage.type {
        case .system:
            if let msg = try? decoder.decode(SystemInitMessage.self, from: data) {
                onEvent?(.systemInit(msg))
            }

        case .assistant:
            if let msg = try? decoder.decode(AssistantMessage.self, from: data) {
                onEvent?(.assistantMessage(msg))
                processAssistantContent(msg)
            }

        case .result:
            if let msg = try? decoder.decode(ResultMessage.self, from: data) {
                onEvent?(.result(msg))
            }

        case .user, .streamEvent:
            // 에코백이나 스트림 이벤트는 무시
            break
        }
    }

    /// assistant 메시지에서 tool_use 감지
    private func processAssistantContent(_ msg: AssistantMessage) {
        for block in msg.message.content {
            switch block {
            case .text(let textBlock):
                onEvent?(.textOutput(textBlock.text))

            case .toolUse(let toolBlock):
                if toolBlock.name == "AskUserQuestion" {
                    handleAskUserQuestion(toolBlock)
                }

            case .unknown:
                break
            }
        }
    }

    /// AskUserQuestion 처리
    private func handleAskUserQuestion(_ toolBlock: ContentBlock.ToolUseBlock) {
        // input을 AskUserQuestionInput으로 변환
        do {
            let inputData = try JSONSerialization.data(withJSONObject: toolBlock.input.mapValues { $0.value })
            let input = try decoder.decode(AskUserQuestionInput.self, from: inputData)
            onEvent?(.askUserQuestion(toolId: toolBlock.id, input: input))
        } catch {
            onEvent?(.error(error))
        }
    }

    // MARK: - Send Messages

    /// 사용자 메시지 전송
    public func sendMessage(_ content: String) throws {
        let message = UserInputMessage(content: content)
        try sendJSON(message)
    }

    /// AskUserQuestion 응답 전송
    public func sendAskUserQuestionResponse(answers: [String: String]) throws {
        let response = AskUserQuestionResponse(answers: answers)
        let jsonString = try encodeToString(response)

        // answers를 JSON 문자열로 content에 담아서 전송
        let message = UserInputMessage(content: jsonString)
        try sendJSON(message)
    }

    /// AskUserQuestion 응답 전송 (멀티셀렉트)
    public func sendAskUserQuestionResponse(answersArray: [String: [String]]) throws {
        let response = AskUserQuestionResponse(answersArray: answersArray)
        let jsonString = try encodeToString(response)

        let message = UserInputMessage(content: jsonString)
        try sendJSON(message)
    }

    /// JSON 인코딩 후 전송
    private func sendJSON<T: Encodable>(_ value: T) throws {
        guard let stdinPipe = stdinPipe else {
            throw ClaudeCodeError.notRunning
        }

        let jsonString = try encodeToString(value)
        guard let data = (jsonString + "\n").data(using: .utf8) else {
            throw ClaudeCodeError.encodingFailed
        }

        stdinPipe.fileHandleForWriting.write(data)
    }

    nonisolated private func encodeToString<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            throw ClaudeCodeError.encodingFailed
        }
        return string
    }

    // MARK: - Status

    public var isRunning: Bool {
        process?.isRunning ?? false
    }
}

// MARK: - Errors

public enum ClaudeCodeError: Error, LocalizedError, Sendable {
    case alreadyRunning
    case notRunning
    case encodingFailed
    case stderrOutput(String)

    public var errorDescription: String? {
        switch self {
        case .alreadyRunning:
            return "Claude Code is already running"
        case .notRunning:
            return "Claude Code is not running"
        case .encodingFailed:
            return "Failed to encode message"
        case .stderrOutput(let output):
            return "stderr: \(output)"
        }
    }
}
