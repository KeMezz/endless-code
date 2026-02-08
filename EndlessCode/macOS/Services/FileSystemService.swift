//
//  FileSystemService.swift
//  EndlessCode
//
//  파일 시스템 접근 서비스
//

import Foundation

// MARK: - FileSystemServiceProtocol

/// 파일 시스템 서비스 프로토콜
protocol FileSystemServiceProtocol: Sendable {
    func loadDirectory(at path: String, maxDepth: Int) async throws -> FileSystemItem
    func readFileContent(at path: String, maxSize: Int) async throws -> String
}

// MARK: - FileSystemService

/// 파일 시스템 서비스 구현
/// 상태를 가지지 않으므로 Sendable 준수 가능
final class FileSystemService: FileSystemServiceProtocol, Sendable {
    /// 디렉토리당 최대 항목 수 (가상화 임계값)
    static let maxItemsPerDirectory = 1000

    /// 디렉토리 로드
    func loadDirectory(at path: String, maxDepth: Int) async throws -> FileSystemItem {
        let fileManager = FileManager.default
        let url = URL(fileURLWithPath: path)

        guard fileManager.fileExists(atPath: path) else {
            throw FileSystemError.pathNotFound(path)
        }

        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: path, isDirectory: &isDirectory)

        guard isDirectory.boolValue else {
            throw FileSystemError.notADirectory(path)
        }

        return try await loadItem(at: url, currentDepth: 0, maxDepth: maxDepth, visitedPaths: Set())
    }

    /// 파일 내용 읽기
    func readFileContent(at path: String, maxSize: Int) async throws -> String {
        let url = URL(fileURLWithPath: path)
        let attributes = try FileManager.default.attributesOfItem(atPath: path)
        let fileSize = attributes[.size] as? Int64 ?? 0

        if fileSize > maxSize {
            // 부분 읽기
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            let data = handle.readData(ofLength: maxSize)
            guard let content = String(data: data, encoding: .utf8) else {
                throw FileSystemError.readError("Unable to decode file content")
            }
            return content + "\n\n[... truncated, file size: \(fileSize) bytes ...]"
        }

        return try String(contentsOf: url, encoding: .utf8)
    }

    /// 아이템 로드 (재귀)
    private func loadItem(
        at url: URL,
        currentDepth: Int,
        maxDepth: Int,
        visitedPaths: Set<String>
    ) async throws -> FileSystemItem {
        let fileManager = FileManager.default
        let path = url.path
        let attributes = try fileManager.attributesOfItem(atPath: path)

        // 심볼릭 링크 확인
        let isSymlink = attributes[.type] as? FileAttributeType == .typeSymbolicLink
        var resolvedPath = path

        if isSymlink {
            resolvedPath = try fileManager.destinationOfSymbolicLink(atPath: path)
            // 절대 경로로 변환
            if !resolvedPath.hasPrefix("/") {
                resolvedPath = url.deletingLastPathComponent().appendingPathComponent(resolvedPath).path
            }

            // 순환 참조 감지
            if visitedPaths.contains(resolvedPath) {
                throw FileSystemError.symbolicLinkLoop(path)
            }
        }

        let isDirectory = (attributes[.type] as? FileAttributeType == .typeDirectory) ||
                          (isSymlink && FileManager.default.fileExists(atPath: resolvedPath, isDirectory: nil))

        var children: [FileSystemItem]? = nil

        // 디렉토리인 경우 자식 로드
        if isDirectory && currentDepth < maxDepth {
            var newVisitedPaths = visitedPaths
            newVisitedPaths.insert(resolvedPath)

            let contents = try fileManager.contentsOfDirectory(
                at: URL(fileURLWithPath: resolvedPath),
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )

            // 항목 수 제한 확인
            let limitedContents = Array(contents.prefix(Self.maxItemsPerDirectory))

            children = try await withThrowingTaskGroup(of: FileSystemItem.self) { group in
                for childUrl in limitedContents {
                    group.addTask {
                        try await self.loadItem(
                            at: childUrl,
                            currentDepth: currentDepth + 1,
                            maxDepth: maxDepth,
                            visitedPaths: newVisitedPaths
                        )
                    }
                }

                var results: [FileSystemItem] = []
                for try await item in group {
                    results.append(item)
                }
                return results.sorted { a, b in
                    // 폴더 먼저, 그 다음 이름 순
                    if a.isDirectory != b.isDirectory {
                        return a.isDirectory
                    }
                    return a.name.localizedStandardCompare(b.name) == .orderedAscending
                }
            }
        }

        return FileSystemItem(
            id: path,  // 경로를 ID로 사용
            name: url.lastPathComponent,
            path: path,
            isDirectory: isDirectory,
            size: attributes[.size] as? Int64,
            modificationDate: attributes[.modificationDate] as? Date,
            isSymbolicLink: isSymlink,
            children: children
        )
    }
}
