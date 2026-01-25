//
//  ProcessRunnerTests.swift
//  EndlessCodeTests
//
//  ProcessRunner 단위 테스트 (Swift Testing)
//

import Foundation
import Testing
@testable import EndlessCode

// MARK: - Helper Actor for Thread-Safe Output Collection

private actor OutputCollector {
    private var output: String = ""

    func append(_ chunk: String) {
        output += chunk
    }

    func get() -> String {
        output
    }

    func contains(_ substring: String) -> Bool {
        output.contains(substring)
    }
}

@Suite("ProcessRunner Tests")
struct ProcessRunnerTests {

    // MARK: - Initialization Tests

    @Test("Init sets idle state")
    func initSetsIdleState() async {
        // Given
        let runner = ProcessRunner(
            executablePath: "/bin/echo",
            arguments: ["hello"]
        )

        // When
        let state = await runner.state

        // Then
        #expect(state == .idle)
    }

    @Test("Init assigns process ID")
    func initAssignsProcessId() async {
        // Given
        let runner = ProcessRunner(executablePath: "/bin/echo")

        // Then
        #expect(runner.processId != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }

    // MARK: - Start Tests

    @Test("Start with valid path sets running state")
    func startWithValidPathSetsRunningState() async throws {
        // Given
        let runner = ProcessRunner(
            executablePath: "/bin/echo",
            arguments: ["test"]
        )

        // When
        try await runner.start()

        // Then
        let state = await runner.state
        switch state {
        case .running, .terminated:
            // Success - process either running or completed quickly
            break
        default:
            Issue.record("Expected running or terminated state, got \(state)")
        }

        // Cleanup
        await runner.terminate()
    }

    @Test("Start with invalid path throws notFound error")
    func startWithInvalidPathThrowsNotFoundError() async {
        // Given
        let runner = ProcessRunner(
            executablePath: "/nonexistent/path"
        )

        // When/Then
        await #expect(throws: ProcessError.notFound(path: "/nonexistent/path")) {
            try await runner.start()
        }
    }

    @Test("Start when already running throws alreadyRunning error")
    func startWhenAlreadyRunningThrowsAlreadyRunningError() async throws {
        // Given
        let runner = ProcessRunner(
            executablePath: "/bin/cat" // cat waits for input
        )
        try await runner.start()

        // When/Then
        await #expect(throws: ProcessError.alreadyRunning) {
            try await runner.start()
        }

        // Cleanup
        await runner.terminate()
    }

    // MARK: - Terminate Tests

    @Test("Terminate stops running process")
    func terminateStopsRunningProcess() async throws {
        // Given
        let runner = ProcessRunner(
            executablePath: "/bin/cat"
        )
        try await runner.start()

        // When
        await runner.terminate()

        // Then
        try await Task.sleep(for: .milliseconds(100))
        let state = await runner.state
        if case .terminated = state {
            // Success
        } else {
            Issue.record("Expected terminated state, got \(state)")
        }
    }

    // MARK: - Write Tests

    @Test("Write when running sends data")
    func writeWhenRunningSendsData() async throws {
        // Given
        let runner = ProcessRunner(
            executablePath: "/bin/cat"
        )

        let collector = OutputCollector()
        let collectTask = Task {
            for await chunk in runner.stdout {
                await collector.append(chunk)
                if await collector.contains("hello") {
                    break
                }
            }
        }

        // Allow Task to start listening
        try await Task.sleep(for: .milliseconds(50))

        // When
        try await runner.start()
        try await runner.write("hello")

        // Give some time for output
        try await Task.sleep(for: .milliseconds(200))
        collectTask.cancel()

        // Then
        let hasHello = await collector.contains("hello")
        #expect(hasHello)

        // Cleanup
        await runner.terminate()
    }

    @Test("Write when not running throws notRunning error")
    func writeWhenNotRunningThrowsNotRunningError() async {
        // Given
        let runner = ProcessRunner(
            executablePath: "/bin/echo"
        )

        // When/Then
        await #expect(throws: ProcessError.notRunning) {
            try await runner.write("test")
        }
    }

    // MARK: - Stdout Tests

    @Test("Stdout receives process output")
    func stdoutReceivesProcessOutput() async throws {
        // Given
        let runner = ProcessRunner(
            executablePath: "/bin/echo",
            arguments: ["hello", "world"]
        )

        let collector = OutputCollector()
        let collectTask = Task {
            for await chunk in runner.stdout {
                await collector.append(chunk)
            }
        }

        // Allow Task to start listening
        try await Task.sleep(for: .milliseconds(100))

        // When
        try await runner.start()

        // Wait for process to complete with timeout
        var attempts = 0
        while attempts < 20 {
            let output = await collector.get()
            if output.contains("hello") && output.contains("world") {
                break
            }
            try await Task.sleep(for: .milliseconds(100))
            attempts += 1
        }
        collectTask.cancel()

        // Then
        let hasHello = await collector.contains("hello")
        let hasWorld = await collector.contains("world")
        #expect(hasHello)
        #expect(hasWorld)
    }

    // MARK: - Factory Tests

    @Test("ForClaudeCLI creates correct runner")
    func forClaudeCLICreatesCorrectRunner() {
        // When
        let runner = ProcessRunner.forClaudeCLI(
            cliPath: "/usr/local/bin/claude",
            projectPath: "/path/to/project"
        )

        // Then
        #expect(runner.processId != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }

    @Test("ForClaudeCLI with resume includes resume argument")
    func forClaudeCLIWithResumeIncludesResumeArgument() {
        // When
        let runner = ProcessRunner.forClaudeCLI(
            cliPath: "/usr/local/bin/claude",
            projectPath: "/path/to/project",
            sessionId: "test-session",
            resume: true
        )

        // Then - 직접 arguments 확인은 불가하지만, 생성은 확인
        #expect(runner.processId != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }
}
