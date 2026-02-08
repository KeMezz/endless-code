//
//  GitService.swift
//  EndlessCode
//
//  Git 상태 조회 서비스
//

import Foundation

// MARK: - GitServiceProtocol

/// Git 서비스 프로토콜
protocol GitServiceProtocol: Sendable {
    func getStatus(at path: String) async throws -> (branch: String, statuses: [String: GitFileStatus])
}

// MARK: - GitService

/// Git 서비스 구현
/// 상태를 가지지 않으므로 Sendable 준수 가능
final class GitService: GitServiceProtocol, Sendable {
    /// Git 상태 조회
    func getStatus(at path: String) async throws -> (branch: String, statuses: [String: GitFileStatus]) {
        // 브랜치 이름 가져오기
        let branch = try await getBranch(at: path)

        // 상태 가져오기
        let statuses = try await getFileStatuses(at: path)

        return (branch, statuses)
    }

    /// 현재 브랜치 이름
    private func getBranch(at path: String) async throws -> String {
        let output = try await runGitCommand(["rev-parse", "--abbrev-ref", "HEAD"], at: path)
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 파일 상태 목록
    /// Git porcelain 출력 형식: XY filename
    /// X = index 상태 (staged), Y = work tree 상태
    /// 둘 중 하나라도 변경되었으면 해당 상태를 표시
    private func getFileStatuses(at path: String) async throws -> [String: GitFileStatus] {
        let output = try await runGitCommand(["status", "--porcelain"], at: path)
        var statuses: [String: GitFileStatus] = [:]

        for line in output.components(separatedBy: "\n") where !line.isEmpty {
            guard line.count >= 3 else { continue }

            let indexStatus = line[line.startIndex]  // Staged 상태
            let workTreeStatus = line[line.index(line.startIndex, offsetBy: 1)]  // 워킹트리 상태
            let filePath = String(line.dropFirst(3))
            let fullPath = (path as NSString).appendingPathComponent(filePath)

            // 워킹트리 상태 우선, 없으면 인덱스 상태 사용
            let effectiveStatus = workTreeStatus != " " ? workTreeStatus : indexStatus
            if let status = parseGitStatus(String(effectiveStatus)) {
                statuses[fullPath] = status
            }
        }

        return statuses
    }

    /// Git 상태 문자 파싱
    private func parseGitStatus(_ char: String) -> GitFileStatus? {
        switch char {
        case "M":
            return .modified
        case "A":
            return .added
        case "D":
            return .deleted
        case "R":
            return .renamed
        case "C":
            return .copied
        case "?":
            return .untracked
        case "!":
            return .ignored
        case "U":
            return .unmerged
        default:
            return nil
        }
    }

    /// Git 명령 실행
    private func runGitCommand(_ arguments: [String], at path: String) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = URL(fileURLWithPath: path)

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            throw error
        }

        // waitUntilExit 사용 - terminationHandler보다 안정적
        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        // 종료 코드 확인 - 0이 아니면 에러
        if process.terminationStatus != 0 {
            let errorMessage = String(data: stderrData, encoding: .utf8) ?? "Unknown error"
            throw GitError.commandFailed(errorMessage)
        }

        return String(data: stdoutData, encoding: .utf8) ?? ""
    }
}

// MARK: - GitError

enum GitError: Error, LocalizedError {
    case commandFailed(String)
    case notAGitRepository

    var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            return "Git command failed: \(message)"
        case .notAGitRepository:
            return "Not a git repository"
        }
    }
}
