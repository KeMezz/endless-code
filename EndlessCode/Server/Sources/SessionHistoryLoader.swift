//
//  SessionHistoryLoader.swift
//  EndlessCode
//
//  세션 히스토리 로더 - JSONL 파일 파싱, 페이지네이션, 손상 파일 복구
//

import Foundation

// MARK: - SessionHistoryLoaderProtocol

/// 세션 히스토리 로더 프로토콜
protocol SessionHistoryLoaderProtocol: Sendable {
    func loadHistory(
        sessionId: String,
        projectId: String,
        limit: Int,
        offset: Int
    ) async throws -> SessionHistory

    func loadRecentMessages(
        sessionId: String,
        projectId: String,
        count: Int
    ) async throws -> [ParsedMessage]
}

// MARK: - SessionHistory

/// 로드된 세션 히스토리
struct SessionHistory: Sendable {
    let sessionId: String
    let messages: [ParsedMessage]
    let totalCount: Int
    let hasMore: Bool
    let corruptedLines: Int
}

// MARK: - SessionHistoryLoader

/// 세션 히스토리를 로드하는 서비스
actor SessionHistoryLoader: SessionHistoryLoaderProtocol {
    private let claudeBasePath: String
    private let parser: JSONLParser
    private let defaultLimit = 1000

    init(claudeBasePath: String? = nil) {
        self.claudeBasePath = claudeBasePath ?? Self.defaultClaudeBasePath()
        self.parser = JSONLParser()
    }

    private static func defaultClaudeBasePath() -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.claude"
    }

    // MARK: - Public API

    func loadHistory(
        sessionId: String,
        projectId: String,
        limit: Int = 1000,
        offset: Int = 0
    ) async throws -> SessionHistory {
        let filePath = sessionFilePath(sessionId: sessionId, projectId: projectId)

        guard FileManager.default.fileExists(atPath: filePath) else {
            throw SessionHistoryError.fileNotFound(path: filePath)
        }

        return try await loadFromFile(
            at: filePath,
            sessionId: sessionId,
            limit: limit,
            offset: offset
        )
    }

    func loadRecentMessages(
        sessionId: String,
        projectId: String,
        count: Int = 100
    ) async throws -> [ParsedMessage] {
        let filePath = sessionFilePath(sessionId: sessionId, projectId: projectId)

        guard FileManager.default.fileExists(atPath: filePath) else {
            throw SessionHistoryError.fileNotFound(path: filePath)
        }

        return try await loadLastMessages(from: filePath, count: count)
    }

    // MARK: - Private Methods

    private func sessionFilePath(sessionId: String, projectId: String) -> String {
        "\(claudeBasePath)/projects/\(projectId)/\(sessionId).jsonl"
    }

    private func loadFromFile(
        at path: String,
        sessionId: String,
        limit: Int,
        offset: Int
    ) async throws -> SessionHistory {
        guard let fileHandle = FileHandle(forReadingAtPath: path) else {
            throw SessionHistoryError.cannotOpenFile(path: path)
        }

        defer {
            try? fileHandle.close()
        }

        var messages: [ParsedMessage] = []
        var totalCount = 0
        var corruptedLines = 0
        var currentOffset = 0

        // 라인 단위로 읽기
        let data = fileHandle.readDataToEndOfFile()
        guard let content = String(data: data, encoding: .utf8) else {
            throw SessionHistoryError.invalidEncoding(path: path)
        }

        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            totalCount += 1

            // offset 이전 라인 스킵
            if currentOffset < offset {
                currentOffset += 1
                continue
            }

            // limit 도달 시 중단
            if messages.count >= limit {
                continue // 총 개수 카운트를 위해 계속 진행
            }

            // 파싱 시도
            do {
                let message = try parser.parse(line: trimmed)
                messages.append(message)
            } catch {
                // 손상된 라인 - 스킵하고 카운트
                corruptedLines += 1
            }
        }

        return SessionHistory(
            sessionId: sessionId,
            messages: messages,
            totalCount: totalCount,
            hasMore: offset + messages.count < totalCount,
            corruptedLines: corruptedLines
        )
    }

    private func loadLastMessages(from path: String, count: Int) async throws -> [ParsedMessage] {
        guard let fileHandle = FileHandle(forReadingAtPath: path) else {
            throw SessionHistoryError.cannotOpenFile(path: path)
        }

        defer {
            try? fileHandle.close()
        }

        // 파일 크기 확인
        let fileSize = try fileHandle.seekToEnd()
        guard fileSize > 0 else {
            return []
        }

        // 역방향 읽기를 위한 청크 크기
        let chunkSize: UInt64 = 65536 // 64KB

        var messages: [ParsedMessage] = []
        var buffer = ""
        var position = fileSize

        while messages.count < count && position > 0 {
            // 읽을 위치 계산
            let readSize = min(chunkSize, position)
            position -= readSize

            try fileHandle.seek(toOffset: position)
            let data = fileHandle.readData(ofLength: Int(readSize))

            guard let chunk = String(data: data, encoding: .utf8) else {
                continue
            }

            // 버퍼 앞에 추가
            buffer = chunk + buffer

            // 완성된 라인 추출
            let lines = buffer.components(separatedBy: .newlines)

            // 첫 번째 라인은 불완전할 수 있으므로 버퍼에 유지
            if position > 0 && lines.count > 1 {
                buffer = lines[0]

                // 나머지 라인 파싱 (역순)
                for line in lines.dropFirst().reversed() {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { continue }

                    if let message = try? parser.parse(line: trimmed) {
                        messages.insert(message, at: 0)
                        if messages.count >= count {
                            break
                        }
                    }
                }
            }
        }

        // 버퍼에 남은 데이터 처리
        if messages.count < count && !buffer.isEmpty {
            let trimmed = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, let message = try? parser.parse(line: trimmed) {
                messages.insert(message, at: 0)
            }
        }

        return messages
    }
}

// MARK: - SessionHistoryError

/// 세션 히스토리 에러
enum SessionHistoryError: Error, Sendable, Equatable {
    case fileNotFound(path: String)
    case cannotOpenFile(path: String)
    case invalidEncoding(path: String)
    case corruptedFile(path: String, validLines: Int, totalLines: Int)
}

extension SessionHistoryError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "히스토리 파일을 찾을 수 없습니다: \(path)"
        case .cannotOpenFile(let path):
            return "파일을 열 수 없습니다: \(path)"
        case .invalidEncoding(let path):
            return "파일 인코딩 오류: \(path)"
        case .corruptedFile(let path, let valid, let total):
            return "손상된 파일: \(path) (\(valid)/\(total) 라인 유효)"
        }
    }
}
