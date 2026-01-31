//
//  DiffModels.swift
//  EndlessCode
//
//  Git Diff 관련 모델 정의
//

import Foundation

// MARK: - UnifiedDiff

/// 파싱된 Unified Diff 전체
struct UnifiedDiff: Identifiable, Hashable, Sendable {
    let id: String
    let files: [DiffFile]
    let isStaged: Bool?
    let generatedAt: Date

    var totalFilesCount: Int { files.count }
    var totalAdditions: Int { files.reduce(0) { $0 + $1.additions } }
    var totalDeletions: Int { files.reduce(0) { $0 + $1.deletions } }

    init(
        id: String = UUID().uuidString,
        files: [DiffFile],
        isStaged: Bool? = nil,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.files = files
        self.isStaged = isStaged
        self.generatedAt = generatedAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: UnifiedDiff, rhs: UnifiedDiff) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - DiffFile

/// 단일 파일의 Diff
struct DiffFile: Identifiable, Hashable, Sendable {
    let id: String
    let oldPath: String?
    let newPath: String?
    let hunks: [DiffHunk]
    let isBinary: Bool
    let fileStatus: DiffFileStatus

    var additions: Int { hunks.reduce(0) { $0 + $1.additions } }
    var deletions: Int { hunks.reduce(0) { $0 + $1.deletions } }

    /// 표시용 파일 경로 (new > old)
    var displayPath: String {
        newPath ?? oldPath ?? "Unknown"
    }

    /// 파일 확장자
    var fileExtension: String? {
        let path = displayPath
        let ext = (path as NSString).pathExtension
        return ext.isEmpty ? nil : ext.lowercased()
    }

    init(
        id: String = UUID().uuidString,
        oldPath: String?,
        newPath: String?,
        hunks: [DiffHunk] = [],
        isBinary: Bool = false,
        fileStatus: DiffFileStatus = .modified
    ) {
        self.id = id
        self.oldPath = oldPath
        self.newPath = newPath
        self.hunks = hunks
        self.isBinary = isBinary
        self.fileStatus = fileStatus
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DiffFile, rhs: DiffFile) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - DiffFileStatus

/// Diff 파일 상태
enum DiffFileStatus: String, Sendable, Hashable {
    case added = "added"
    case deleted = "deleted"
    case modified = "modified"
    case renamed = "renamed"
    case copied = "copied"

    var displayName: String {
        switch self {
        case .added: return "Added"
        case .deleted: return "Deleted"
        case .modified: return "Modified"
        case .renamed: return "Renamed"
        case .copied: return "Copied"
        }
    }

    var iconName: String {
        switch self {
        case .added: return "plus.circle.fill"
        case .deleted: return "minus.circle.fill"
        case .modified: return "pencil.circle.fill"
        case .renamed: return "arrow.right.circle.fill"
        case .copied: return "doc.on.doc.fill"
        }
    }
}

// MARK: - DiffHunk

/// Diff의 단일 변경 영역 (Hunk)
struct DiffHunk: Identifiable, Hashable, Sendable {
    let id: String
    let header: String  // @@ -10,5 +10,7 @@ optional context
    let oldStart: Int
    let oldCount: Int
    let newStart: Int
    let newCount: Int
    let contextText: String?  // @@ 라인의 함수명 등
    let lines: [DiffLine]

    var additions: Int { lines.filter { $0.type == .added }.count }
    var deletions: Int { lines.filter { $0.type == .deleted }.count }

    init(
        id: String = UUID().uuidString,
        header: String,
        oldStart: Int,
        oldCount: Int,
        newStart: Int,
        newCount: Int,
        contextText: String? = nil,
        lines: [DiffLine] = []
    ) {
        self.id = id
        self.header = header
        self.oldStart = oldStart
        self.oldCount = oldCount
        self.newStart = newStart
        self.newCount = newCount
        self.contextText = contextText
        self.lines = lines
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DiffHunk, rhs: DiffHunk) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - DiffLine

/// Diff의 단일 라인
struct DiffLine: Identifiable, Hashable, Sendable {
    let id: String
    let type: DiffLineType
    let content: String
    let oldLineNumber: Int?
    let newLineNumber: Int?

    init(
        id: String = UUID().uuidString,
        type: DiffLineType,
        content: String,
        oldLineNumber: Int? = nil,
        newLineNumber: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.oldLineNumber = oldLineNumber
        self.newLineNumber = newLineNumber
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DiffLine, rhs: DiffLine) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - DiffLineType

/// Diff 라인 타입
enum DiffLineType: String, Sendable, Hashable {
    case context = " "   // 변경 없음
    case added = "+"     // 추가
    case deleted = "-"   // 삭제
    case header = "@"    // Hunk 헤더
    case noNewline = "\\" // No newline at end of file

    var prefix: String {
        switch self {
        case .context: return " "
        case .added: return "+"
        case .deleted: return "-"
        case .header: return "@@"
        case .noNewline: return "\\"
        }
    }
}

// MARK: - DiffStatistics

/// Diff 통계 정보
struct DiffStatistics: Sendable {
    let totalFiles: Int
    let totalAdditions: Int
    let totalDeletions: Int
    let filesByStatus: [DiffFileStatus: Int]

    var totalChanges: Int { totalAdditions + totalDeletions }

    init(from diff: UnifiedDiff) {
        self.totalFiles = diff.files.count
        self.totalAdditions = diff.totalAdditions
        self.totalDeletions = diff.totalDeletions

        var statusCounts: [DiffFileStatus: Int] = [:]
        for file in diff.files {
            statusCounts[file.fileStatus, default: 0] += 1
        }
        self.filesByStatus = statusCounts
    }
}

// MARK: - DiffSortOption

/// Diff 파일 정렬 옵션
enum DiffSortOption: String, CaseIterable, Identifiable, Sendable {
    case path = "path"
    case changes = "changes"
    case status = "status"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .path: return "Path"
        case .changes: return "Changes"
        case .status: return "Status"
        }
    }

    var iconName: String {
        switch self {
        case .path: return "folder"
        case .changes: return "number"
        case .status: return "circle.grid.2x2"
        }
    }
}

// MARK: - DiffError

/// Diff 파싱 에러
enum DiffError: Error, LocalizedError, Equatable {
    case invalidFormat(String)
    case parsingFailed(String)
    case emptyDiff
    case tooManyFiles(Int)

    var errorDescription: String? {
        switch self {
        case .invalidFormat(let detail):
            return "Invalid diff format: \(detail)"
        case .parsingFailed(let detail):
            return "Diff parsing failed: \(detail)"
        case .emptyDiff:
            return "Empty diff content"
        case .tooManyFiles(let count):
            return "Too many files in diff: \(count)"
        }
    }
}
