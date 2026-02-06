//
//  DiffParser.swift
//  EndlessCode
//
//  Unified Diff 파싱 서비스
//

import Foundation

// MARK: - DiffParserProtocol

/// Diff 파서 프로토콜
protocol DiffParserProtocol: Sendable {
    func parse(_ input: String, isStaged: Bool?) throws -> UnifiedDiff
    func containsDiff(_ text: String) -> Bool
}

// MARK: - DiffParser

/// Unified Diff 파서 구현
final class DiffParser: DiffParserProtocol, Sendable {
    // MARK: - Constants

    /// 최대 파일 수 (페이지네이션 적용)
    static let maxFilesPerPage = 100

    /// Diff 감지 패턴
    private static let diffHeaderPattern = #"^diff --git a/.+ b/.+"#
    private static let fileHeaderOldPattern = #"^--- (a/)?(.+)$"#
    private static let fileHeaderNewPattern = #"^\+\+\+ (b/)?(.+)$"#
    private static let hunkHeaderPattern = #"^@@\s*-(\d+)(?:,(\d+))?\s*\+(\d+)(?:,(\d+))?\s*@@(.*)$"#
    private static let binaryFilePattern = #"Binary files .+ and .+ differ"#
    private static let newFilePattern = #"^new file mode"#
    private static let deletedFilePattern = #"^deleted file mode"#
    private static let renameFromPattern = #"^rename from (.+)$"#
    private static let renameToPattern = #"^rename to (.+)$"#

    // 컴파일된 정규표현식 (재사용)
    private let diffHeaderRegex: NSRegularExpression
    private let fileHeaderOldRegex: NSRegularExpression
    private let fileHeaderNewRegex: NSRegularExpression
    private let hunkHeaderRegex: NSRegularExpression
    private let binaryFileRegex: NSRegularExpression
    private let newFileRegex: NSRegularExpression
    private let deletedFileRegex: NSRegularExpression
    private let renameFromRegex: NSRegularExpression
    private let renameToRegex: NSRegularExpression

    // MARK: - Initialization

    init() {
        guard let diffHeader = try? NSRegularExpression(pattern: Self.diffHeaderPattern, options: .anchorsMatchLines),
              let fileHeaderOld = try? NSRegularExpression(pattern: Self.fileHeaderOldPattern, options: .anchorsMatchLines),
              let fileHeaderNew = try? NSRegularExpression(pattern: Self.fileHeaderNewPattern, options: .anchorsMatchLines),
              let hunkHeader = try? NSRegularExpression(pattern: Self.hunkHeaderPattern, options: .anchorsMatchLines),
              let binaryFile = try? NSRegularExpression(pattern: Self.binaryFilePattern),
              let newFile = try? NSRegularExpression(pattern: Self.newFilePattern, options: .anchorsMatchLines),
              let deletedFile = try? NSRegularExpression(pattern: Self.deletedFilePattern, options: .anchorsMatchLines),
              let renameFrom = try? NSRegularExpression(pattern: Self.renameFromPattern, options: .anchorsMatchLines),
              let renameTo = try? NSRegularExpression(pattern: Self.renameToPattern, options: .anchorsMatchLines)
        else {
            fatalError("Failed to compile DiffParser regex patterns")
        }
        self.diffHeaderRegex = diffHeader
        self.fileHeaderOldRegex = fileHeaderOld
        self.fileHeaderNewRegex = fileHeaderNew
        self.hunkHeaderRegex = hunkHeader
        self.binaryFileRegex = binaryFile
        self.newFileRegex = newFile
        self.deletedFileRegex = deletedFile
        self.renameFromRegex = renameFrom
        self.renameToRegex = renameTo
    }

    // MARK: - Public Methods

    /// Diff 문자열 파싱
    func parse(_ input: String, isStaged: Bool? = nil) throws -> UnifiedDiff {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else {
            throw DiffError.emptyDiff
        }

        // Diff 형식 확인
        guard containsDiff(trimmedInput) else {
            throw DiffError.invalidFormat("No valid diff format found")
        }

        let lines = trimmedInput.components(separatedBy: "\n")
        var files: [DiffFile] = []
        var currentFileBuilder: DiffFileBuilder?

        var index = 0
        while index < lines.count {
            let line = lines[index]

            // diff --git 헤더 감지
            if matchesDiffHeader(line) {
                // 이전 파일 저장
                if let builder = currentFileBuilder {
                    files.append(builder.build())
                }

                // 새 파일 시작
                currentFileBuilder = DiffFileBuilder()
                index += 1
                continue
            }

            // 파일 메타데이터 파싱
            if let builder = currentFileBuilder {
                // new file mode
                if matchesNewFile(line) {
                    builder.fileStatus = .added
                    index += 1
                    continue
                }

                // deleted file mode
                if matchesDeletedFile(line) {
                    builder.fileStatus = .deleted
                    index += 1
                    continue
                }

                // rename from
                if let oldPath = extractRenamePath(line, isFrom: true) {
                    builder.oldPath = oldPath
                    builder.fileStatus = .renamed
                    index += 1
                    continue
                }

                // rename to
                if let newPath = extractRenamePath(line, isFrom: false) {
                    builder.newPath = newPath
                    index += 1
                    continue
                }

                // --- 파일 헤더
                if let oldPath = extractOldFilePath(line) {
                    builder.oldPath = oldPath
                    index += 1
                    continue
                }

                // +++ 파일 헤더
                if let newPath = extractNewFilePath(line) {
                    builder.newPath = newPath
                    index += 1
                    continue
                }

                // Binary files
                if matchesBinaryFile(line) {
                    builder.isBinary = true
                    index += 1
                    continue
                }

                // @@ Hunk 헤더
                if let hunkInfo = extractHunkInfo(line) {
                    let (oldStart, oldCount, newStart, newCount, contextText) = hunkInfo
                    let hunkBuilder = DiffHunkBuilder(
                        header: line,
                        oldStart: oldStart,
                        oldCount: oldCount,
                        newStart: newStart,
                        newCount: newCount,
                        contextText: contextText
                    )

                    // Hunk 내용 파싱
                    index += 1
                    var currentOldLine = oldStart
                    var currentNewLine = newStart

                    while index < lines.count {
                        let contentLine = lines[index]

                        // 다음 Hunk 또는 다음 파일 시작 확인
                        if matchesDiffHeader(contentLine) || matchesHunkHeader(contentLine) {
                            break
                        }

                        // 새 파일 헤더 시작 확인
                        if contentLine.hasPrefix("diff ") {
                            break
                        }

                        // 빈 줄이지만 diff 내용일 수 있음 (컨텍스트 라인)
                        let diffLine = parseDiffLine(
                            contentLine,
                            currentOldLine: &currentOldLine,
                            currentNewLine: &currentNewLine
                        )
                        hunkBuilder.lines.append(diffLine)
                        index += 1
                    }

                    builder.hunks.append(hunkBuilder.build())
                    continue
                }
            }

            index += 1
        }

        // 마지막 파일 저장
        if let builder = currentFileBuilder {
            files.append(builder.build())
        }

        // 파일 수 제한 확인
        if files.count > Self.maxFilesPerPage {
            // 첫 페이지만 반환 (페이지네이션 적용)
            let limitedFiles = Array(files.prefix(Self.maxFilesPerPage))
            return UnifiedDiff(
                files: limitedFiles,
                isStaged: isStaged
            )
        }

        return UnifiedDiff(files: files, isStaged: isStaged)
    }

    /// Diff 포함 여부 확인
    func containsDiff(_ text: String) -> Bool {
        // diff --git 또는 --- / +++ 패턴 확인
        let range = NSRange(text.startIndex..., in: text)
        if diffHeaderRegex.firstMatch(in: text, range: range) != nil {
            return true
        }

        // --- / +++ 패턴만 있는 경우
        if text.contains("\n--- ") && text.contains("\n+++ ") {
            return true
        }

        // @@ 패턴 확인
        return hunkHeaderRegex.firstMatch(in: text, range: range) != nil
    }

    // MARK: - Private Methods

    private func matchesDiffHeader(_ line: String) -> Bool {
        guard line.hasPrefix("diff ") else { return false }
        let range = NSRange(line.startIndex..., in: line)
        return diffHeaderRegex.firstMatch(in: line, range: range) != nil
    }

    private func matchesNewFile(_ line: String) -> Bool {
        guard line.hasPrefix("new ") else { return false }
        let range = NSRange(line.startIndex..., in: line)
        return newFileRegex.firstMatch(in: line, range: range) != nil
    }

    private func matchesDeletedFile(_ line: String) -> Bool {
        guard line.hasPrefix("deleted ") else { return false }
        let range = NSRange(line.startIndex..., in: line)
        return deletedFileRegex.firstMatch(in: line, range: range) != nil
    }

    private func matchesBinaryFile(_ line: String) -> Bool {
        guard line.hasPrefix("Binary ") else { return false }
        let range = NSRange(line.startIndex..., in: line)
        return binaryFileRegex.firstMatch(in: line, range: range) != nil
    }

    private func matchesHunkHeader(_ line: String) -> Bool {
        guard line.hasPrefix("@@") else { return false }
        let range = NSRange(line.startIndex..., in: line)
        return hunkHeaderRegex.firstMatch(in: line, range: range) != nil
    }

    private func extractOldFilePath(_ line: String) -> String? {
        guard line.hasPrefix("---") else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        guard let match = fileHeaderOldRegex.firstMatch(in: line, range: range) else { return nil }

        // 그룹 2: 파일 경로
        if match.numberOfRanges > 2 {
            if let pathRange = Range(match.range(at: 2), in: line) {
                let path = String(line[pathRange])
                return path == "/dev/null" ? nil : path
            }
        }

        return nil
    }

    private func extractNewFilePath(_ line: String) -> String? {
        guard line.hasPrefix("+++") else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        guard let match = fileHeaderNewRegex.firstMatch(in: line, range: range) else { return nil }

        // 그룹 2: 파일 경로
        if match.numberOfRanges > 2 {
            if let pathRange = Range(match.range(at: 2), in: line) {
                let path = String(line[pathRange])
                return path == "/dev/null" ? nil : path
            }
        }

        return nil
    }

    private func extractRenamePath(_ line: String, isFrom: Bool) -> String? {
        let prefix = isFrom ? "rename from" : "rename to"
        guard line.hasPrefix(prefix) else { return nil }
        let regex = isFrom ? renameFromRegex : renameToRegex
        let range = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, range: range),
              match.numberOfRanges > 1,
              let pathRange = Range(match.range(at: 1), in: line) else { return nil }
        return String(line[pathRange])
    }

    private func extractHunkInfo(_ line: String) -> (Int, Int, Int, Int, String?)? {
        guard line.hasPrefix("@@") else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        guard let match = hunkHeaderRegex.firstMatch(in: line, range: range) else { return nil }

        // @@ -oldStart,oldCount +newStart,newCount @@ contextText
        var oldStart = 0
        var oldCount = 1
        var newStart = 0
        var newCount = 1
        var contextText: String?

        // 그룹 1: oldStart
        if match.numberOfRanges > 1, let r = Range(match.range(at: 1), in: line) {
            oldStart = Int(line[r]) ?? 0
        }

        // 그룹 2: oldCount (optional)
        if match.numberOfRanges > 2, match.range(at: 2).location != NSNotFound,
           let r = Range(match.range(at: 2), in: line) {
            oldCount = Int(line[r]) ?? 1
        }

        // 그룹 3: newStart
        if match.numberOfRanges > 3, let r = Range(match.range(at: 3), in: line) {
            newStart = Int(line[r]) ?? 0
        }

        // 그룹 4: newCount (optional)
        if match.numberOfRanges > 4, match.range(at: 4).location != NSNotFound,
           let r = Range(match.range(at: 4), in: line) {
            newCount = Int(line[r]) ?? 1
        }

        // 그룹 5: contextText (함수명 등)
        if match.numberOfRanges > 5, match.range(at: 5).location != NSNotFound,
           let r = Range(match.range(at: 5), in: line) {
            let text = String(line[r]).trimmingCharacters(in: .whitespaces)
            if !text.isEmpty {
                contextText = text
            }
        }

        return (oldStart, oldCount, newStart, newCount, contextText)
    }

    private func parseDiffLine(
        _ line: String,
        currentOldLine: inout Int,
        currentNewLine: inout Int
    ) -> DiffLine {
        guard let firstChar = line.first else {
            // 빈 줄은 컨텍스트로 처리
            let diffLine = DiffLine(
                type: .context,
                content: "",
                oldLineNumber: currentOldLine,
                newLineNumber: currentNewLine
            )
            currentOldLine += 1
            currentNewLine += 1
            return diffLine
        }

        let content = String(line.dropFirst())

        switch firstChar {
        case "+":
            let diffLine = DiffLine(
                type: .added,
                content: content,
                oldLineNumber: nil,
                newLineNumber: currentNewLine
            )
            currentNewLine += 1
            return diffLine

        case "-":
            let diffLine = DiffLine(
                type: .deleted,
                content: content,
                oldLineNumber: currentOldLine,
                newLineNumber: nil
            )
            currentOldLine += 1
            return diffLine

        case "\\":
            // "\ No newline at end of file"
            return DiffLine(
                type: .noNewline,
                content: content,
                oldLineNumber: nil,
                newLineNumber: nil
            )

        default:
            // 공백으로 시작하는 컨텍스트 라인
            let diffLine = DiffLine(
                type: .context,
                content: firstChar == " " ? content : line,
                oldLineNumber: currentOldLine,
                newLineNumber: currentNewLine
            )
            currentOldLine += 1
            currentNewLine += 1
            return diffLine
        }
    }
}

// MARK: - DiffFileBuilder

private class DiffFileBuilder {
    var oldPath: String?
    var newPath: String?
    var hunks: [DiffHunk] = []
    var isBinary: Bool = false
    var fileStatus: DiffFileStatus = .modified

    func build() -> DiffFile {
        // 파일 상태 추론
        let status: DiffFileStatus
        if fileStatus != .modified {
            status = fileStatus
        } else if oldPath == nil && newPath != nil {
            status = .added
        } else if oldPath != nil && newPath == nil {
            status = .deleted
        } else {
            status = .modified
        }

        return DiffFile(
            oldPath: oldPath,
            newPath: newPath,
            hunks: hunks,
            isBinary: isBinary,
            fileStatus: status
        )
    }
}

// MARK: - DiffHunkBuilder

private class DiffHunkBuilder {
    let header: String
    let oldStart: Int
    let oldCount: Int
    let newStart: Int
    let newCount: Int
    let contextText: String?
    var lines: [DiffLine] = []

    init(
        header: String,
        oldStart: Int,
        oldCount: Int,
        newStart: Int,
        newCount: Int,
        contextText: String?
    ) {
        self.header = header
        self.oldStart = oldStart
        self.oldCount = oldCount
        self.newStart = newStart
        self.newCount = newCount
        self.contextText = contextText
    }

    func build() -> DiffHunk {
        DiffHunk(
            header: header,
            oldStart: oldStart,
            oldCount: oldCount,
            newStart: newStart,
            newCount: newCount,
            contextText: contextText,
            lines: lines
        )
    }
}

// MARK: - DiffDataSource

/// Diff 데이터 소스 - CLI 출력에서 Diff 추출
final class DiffDataSource: Sendable {
    private let parser: DiffParserProtocol

    init(parser: DiffParserProtocol = DiffParser()) {
        self.parser = parser
    }

    /// tool_result에서 Diff 추출
    func extractFromToolResult(_ output: String) -> UnifiedDiff? {
        guard parser.containsDiff(output) else {
            return nil
        }

        // staged vs unstaged 감지
        let isStaged = detectStagedStatus(output)

        do {
            return try parser.parse(output, isStaged: isStaged)
        } catch {
            return nil
        }
    }

    /// Git diff 출력인지 확인
    func isGitDiffOutput(_ output: String) -> Bool {
        // Bash 도구로 git diff 명령 실행 결과인지 확인
        return parser.containsDiff(output) &&
               (output.contains("diff --git") ||
                (output.contains("---") && output.contains("+++")))
    }

    /// staged 상태 감지
    private func detectStagedStatus(_ output: String) -> Bool? {
        // git diff --staged 또는 --cached 결과인지 확인
        if output.contains("--staged") || output.contains("--cached") {
            return true
        }
        // 단순 git diff 결과
        if output.contains("git diff") && !output.contains("--staged") {
            return false
        }
        return nil
    }
}
