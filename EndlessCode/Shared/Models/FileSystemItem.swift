//
//  FileSystemItem.swift
//  EndlessCode
//
//  파일 시스템 아이템 모델 - 파일/폴더 정보
//

import Foundation

// MARK: - FileSystemItem

/// 파일 시스템 아이템 (파일 또는 폴더)
struct FileSystemItem: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let path: String
    let isDirectory: Bool
    let size: Int64?
    let modificationDate: Date?
    let isSymbolicLink: Bool
    var children: [FileSystemItem]?
    var gitStatus: GitFileStatus?

    // MARK: - Hashable (id 기반으로 최적화)

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: FileSystemItem, rhs: FileSystemItem) -> Bool {
        lhs.id == rhs.id
    }

    /// 파일 확장자
    var fileExtension: String? {
        guard !isDirectory else { return nil }
        let ext = (name as NSString).pathExtension
        return ext.isEmpty ? nil : ext.lowercased()
    }

    /// 파일 타입 (확장자 기반)
    var fileType: FileType {
        guard !isDirectory else { return .folder }
        guard let ext = fileExtension else { return .unknown }
        return FileType.from(extension: ext)
    }

    /// 깊이 계산을 위한 경로 컴포넌트 수
    var depth: Int {
        path.components(separatedBy: "/").filter { !$0.isEmpty }.count
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        path: String,
        isDirectory: Bool,
        size: Int64? = nil,
        modificationDate: Date? = nil,
        isSymbolicLink: Bool = false,
        children: [FileSystemItem]? = nil,
        gitStatus: GitFileStatus? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.size = size
        self.modificationDate = modificationDate
        self.isSymbolicLink = isSymbolicLink
        self.children = children
        self.gitStatus = gitStatus
    }
}

// MARK: - FileType

/// 파일 타입 열거형
enum FileType: String, Sendable {
    case folder
    case swift
    case javascript
    case typescript
    case python
    case rust
    case go
    case java
    case kotlin
    case ruby
    case php
    case html
    case css
    case json
    case yaml
    case markdown
    case text
    case image
    case video
    case audio
    case pdf
    case archive
    case binary
    case unknown

    /// SF Symbols 아이콘 이름
    var iconName: String {
        switch self {
        case .folder:
            return "folder.fill"
        case .swift:
            return "swift"
        case .javascript, .typescript:
            return "doc.text.fill"
        case .python:
            return "doc.text.fill"
        case .rust, .go, .java, .kotlin:
            return "doc.text.fill"
        case .ruby, .php:
            return "doc.text.fill"
        case .html:
            return "chevron.left.forwardslash.chevron.right"
        case .css:
            return "paintbrush.fill"
        case .json, .yaml:
            return "curlybraces"
        case .markdown, .text:
            return "doc.plaintext.fill"
        case .image:
            return "photo.fill"
        case .video:
            return "film.fill"
        case .audio:
            return "waveform"
        case .pdf:
            return "doc.richtext.fill"
        case .archive:
            return "archivebox.fill"
        case .binary:
            return "doc.fill"
        case .unknown:
            return "doc.fill"
        }
    }

    /// 파일 확장자로부터 FileType 결정
    static func from(extension ext: String) -> FileType {
        switch ext {
        // 프로그래밍 언어
        case "swift":
            return .swift
        case "js", "jsx", "mjs", "cjs":
            return .javascript
        case "ts", "tsx":
            return .typescript
        case "py", "pyw", "pyi":
            return .python
        case "rs":
            return .rust
        case "go":
            return .go
        case "java":
            return .java
        case "kt", "kts":
            return .kotlin
        case "rb", "erb":
            return .ruby
        case "php":
            return .php

        // 웹
        case "html", "htm", "xhtml":
            return .html
        case "css", "scss", "sass", "less":
            return .css

        // 데이터
        case "json", "jsonl":
            return .json
        case "yaml", "yml":
            return .yaml

        // 문서
        case "md", "markdown", "mdx":
            return .markdown
        case "txt", "text", "log":
            return .text
        case "pdf":
            return .pdf

        // 미디어
        case "png", "jpg", "jpeg", "gif", "svg", "webp", "ico", "bmp":
            return .image
        case "mp4", "mov", "avi", "mkv", "webm":
            return .video
        case "mp3", "wav", "aac", "flac", "ogg":
            return .audio

        // 압축
        case "zip", "tar", "gz", "rar", "7z":
            return .archive

        // 바이너리
        case "exe", "dll", "so", "dylib", "a", "o":
            return .binary

        default:
            return .unknown
        }
    }
}

// MARK: - GitFileStatus

/// Git 파일 상태
enum GitFileStatus: String, Sendable, Hashable {
    case modified = "M"
    case added = "A"
    case deleted = "D"
    case renamed = "R"
    case copied = "C"
    case untracked = "?"
    case ignored = "!"
    case unmerged = "U"

    /// 상태 색상
    var color: String {
        switch self {
        case .modified:
            return "orange"
        case .added:
            return "green"
        case .deleted:
            return "red"
        case .renamed, .copied:
            return "blue"
        case .untracked:
            return "gray"
        case .ignored:
            return "gray"
        case .unmerged:
            return "purple"
        }
    }

    /// 상태 설명
    var description: String {
        switch self {
        case .modified:
            return "Modified"
        case .added:
            return "Added"
        case .deleted:
            return "Deleted"
        case .renamed:
            return "Renamed"
        case .copied:
            return "Copied"
        case .untracked:
            return "Untracked"
        case .ignored:
            return "Ignored"
        case .unmerged:
            return "Unmerged"
        }
    }
}

// MARK: - FileFilterOption

/// 파일 필터 옵션
enum FileFilterOption: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case modified = "Modified"
    case recent = "Recent"
    case new = "New"

    var id: String { rawValue }

    /// SF Symbols 아이콘 이름
    var iconName: String {
        switch self {
        case .all:
            return "doc.on.doc"
        case .modified:
            return "pencil"
        case .recent:
            return "clock"
        case .new:
            return "plus.circle"
        }
    }
}

// MARK: - FileSystemError

/// 파일 시스템 에러
enum FileSystemError: Error, LocalizedError {
    case pathNotFound(String)
    case accessDenied(String)
    case notADirectory(String)
    case symbolicLinkLoop(String)
    case depthLimitExceeded(Int)
    case readError(String)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .pathNotFound(let path):
            return "Path not found: \(path)"
        case .accessDenied(let path):
            return "Access denied: \(path)"
        case .notADirectory(let path):
            return "Not a directory: \(path)"
        case .symbolicLinkLoop(let path):
            return "Symbolic link loop detected: \(path)"
        case .depthLimitExceeded(let depth):
            return "Directory depth limit exceeded: \(depth) levels"
        case .readError(let message):
            return "Read error: \(message)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
