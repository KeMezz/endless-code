//
//  MessageCacheService.swift
//  EndlessCode
//
//  오프라인 메시지 캐시 서비스 - 로컬 파일 시스템 기반
//

#if os(iOS)
import Foundation

// MARK: - MessageCacheServiceProtocol

/// 메시지 캐시 서비스 프로토콜
protocol MessageCacheServiceProtocol: Sendable {
    func cacheMessages(_ messages: [ChatMessageItem], for sessionId: String) async throws
    func loadCachedMessages(for sessionId: String) async throws -> [ChatMessageItem]
    func clearCache(for sessionId: String) async throws
    func clearAllCache() async throws
    var cacheSize: Int { get async }
}

// MARK: - MessageCacheService

/// 메시지 캐시 서비스 구현
actor MessageCacheService: MessageCacheServiceProtocol {

    // MARK: Properties

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let maxCacheSize: Int
    private let maxMessagesPerSession: Int

    private var cacheDirectory: URL {
        get throws {
            let appSupport = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let cacheDir = appSupport.appendingPathComponent("MessageCache", isDirectory: true)

            if !fileManager.fileExists(atPath: cacheDir.path) {
                try fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            }

            return cacheDir
        }
    }

    // MARK: Initialization

    init(
        maxCacheSize: Int = 50 * 1024 * 1024, // 50MB
        maxMessagesPerSession: Int = 100
    ) {
        self.maxCacheSize = maxCacheSize
        self.maxMessagesPerSession = maxMessagesPerSession

        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: Public Methods

    /// 메시지를 캐시에 저장
    func cacheMessages(_ messages: [ChatMessageItem], for sessionId: String) async throws {
        let cacheDir = try cacheDirectory
        let safeSessionId = sessionId.replacingOccurrences(of: "[^a-zA-Z0-9\\-]", with: "_", options: .regularExpression)
        let fileURL = cacheDir.appendingPathComponent("\(safeSessionId).json")

        // 최근 N개 메시지만 저장 (메모리 절약)
        let messagesToCache = Array(messages.suffix(maxMessagesPerSession))

        let wrapper = CachedSession(
            sessionId: sessionId,
            messages: messagesToCache,
            cachedAt: Date()
        )

        let data = try encoder.encode(wrapper)
        try data.write(to: fileURL, options: .atomic)

        // LRU 정책: 캐시 크기 초과 시 오래된 파일 삭제
        try await enforceCacheSizeLimit()
    }

    /// 캐시에서 메시지 로드
    func loadCachedMessages(for sessionId: String) async throws -> [ChatMessageItem] {
        let cacheDir = try cacheDirectory
        let safeSessionId = sessionId.replacingOccurrences(of: "[^a-zA-Z0-9\\-]", with: "_", options: .regularExpression)
        let fileURL = cacheDir.appendingPathComponent("\(safeSessionId).json")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        let wrapper = try decoder.decode(CachedSession.self, from: data)

        // 접근 시간 업데이트 (LRU 구현)
        try fileManager.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: fileURL.path
        )

        return wrapper.messages
    }

    /// 특정 세션의 캐시 삭제
    func clearCache(for sessionId: String) async throws {
        let cacheDir = try cacheDirectory
        let safeSessionId = sessionId.replacingOccurrences(of: "[^a-zA-Z0-9\\-]", with: "_", options: .regularExpression)
        let fileURL = cacheDir.appendingPathComponent("\(safeSessionId).json")

        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }

    /// 모든 캐시 삭제
    func clearAllCache() async throws {
        let cacheDir = try cacheDirectory
        let contents = try fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil)

        for fileURL in contents {
            try fileManager.removeItem(at: fileURL)
        }
    }

    /// 현재 캐시 크기 (바이트)
    var cacheSize: Int {
        get async {
            do {
                let cacheDir = try cacheDirectory
                let contents = try fileManager.contentsOfDirectory(
                    at: cacheDir,
                    includingPropertiesForKeys: [.fileSizeKey]
                )

                return contents.reduce(0) { total, url in
                    let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                    return total + size
                }
            } catch {
                return 0
            }
        }
    }

    // MARK: Private Methods

    /// 캐시 크기 제한 강제 (LRU 정책)
    private func enforceCacheSizeLimit() async throws {
        let cacheDir = try cacheDirectory
        let contents = try fileManager.contentsOfDirectory(
            at: cacheDir,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
        )

        // 현재 캐시 크기 계산
        var currentSize = 0
        var files: [(url: URL, size: Int, modifiedAt: Date)] = []

        for url in contents {
            let values = try url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            let size = values.fileSize ?? 0
            let modifiedAt = values.contentModificationDate ?? Date.distantPast

            currentSize += size
            files.append((url, size, modifiedAt))
        }

        // 캐시 크기가 제한을 초과하면 오래된 파일부터 삭제
        if currentSize > maxCacheSize {
            // 수정 시간 기준 오름차순 정렬 (오래된 것부터)
            files.sort { $0.modifiedAt < $1.modifiedAt }

            for file in files {
                guard currentSize > maxCacheSize else { break }

                try fileManager.removeItem(at: file.url)
                currentSize -= file.size
            }
        }
    }
}

// MARK: - CachedSession

/// 캐시된 세션 래퍼
private struct CachedSession: Codable {
    let sessionId: String
    let messages: [ChatMessageItem]
    let cachedAt: Date
}

// MARK: - MessageCacheError

/// 메시지 캐시 에러
enum MessageCacheError: Error {
    case cacheDirectoryNotAccessible
    case fileReadFailed
    case fileWriteFailed
    case decodingFailed
}
#endif
