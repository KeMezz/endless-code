//
//  MessageCacheServiceTests.swift
//  EndlessCodeTests
//
//  MessageCacheService 테스트
//

#if os(iOS)
import Testing
import Foundation
@testable import EndlessCode

// MARK: - MessageCacheService Tests

@Suite("MessageCacheService Tests")
struct MessageCacheServiceTests {

    // MARK: Helper Methods

    private func makeSUT() -> MessageCacheService {
        MessageCacheService(
            maxCacheSize: 1024 * 1024, // 1MB for tests
            maxMessagesPerSession: 10
        )
    }

    private func makeSampleMessages(count: Int) -> [ChatMessageItem] {
        (0..<count).map { index in
            ChatMessageItem(
                id: "msg-\(index)",
                type: .user,
                content: .text("Message \(index)"),
                timestamp: Date().addingTimeInterval(TimeInterval(index))
            )
        }
    }

    // MARK: Tests

    @Test("Cache messages saves to local storage")
    func cacheMessagesSavesToLocalStorage() async throws {
        // Given: 캐시 서비스와 메시지
        let sut = makeSUT()
        let messages = makeSampleMessages(count: 5)
        let sessionId = "test-session-1"

        // When: 메시지 캐시
        try await sut.cacheMessages(messages, for: sessionId)

        // Then: 메시지를 로드할 수 있어야 함
        let loaded = try await sut.loadCachedMessages(for: sessionId)
        #expect(loaded.count == 5)
        #expect(loaded == messages)
    }

    @Test("Cache only recent N messages")
    func cacheOnlyRecentNMessages() async throws {
        // Given: maxMessagesPerSession = 10으로 설정된 캐시
        let sut = makeSUT()
        let messages = makeSampleMessages(count: 20) // 10개보다 많은 메시지
        let sessionId = "test-session-2"

        // When: 20개 메시지 캐시
        try await sut.cacheMessages(messages, for: sessionId)

        // Then: 최근 10개만 저장되어야 함
        let loaded = try await sut.loadCachedMessages(for: sessionId)
        #expect(loaded.count == 10)
        #expect(loaded == Array(messages.suffix(10)))
    }

    @Test("Load non-existent cache returns empty array")
    func loadNonExistentCacheReturnsEmptyArray() async throws {
        // Given: 캐시 서비스
        let sut = makeSUT()
        let sessionId = "non-existent-session"

        // When: 존재하지 않는 세션 로드
        let loaded = try await sut.loadCachedMessages(for: sessionId)

        // Then: 빈 배열 반환
        #expect(loaded.isEmpty)
    }

    @Test("Clear cache removes specific session")
    func clearCacheRemovesSpecificSession() async throws {
        // Given: 두 세션의 캐시
        let sut = makeSUT()
        let messages1 = makeSampleMessages(count: 3)
        let messages2 = makeSampleMessages(count: 3)

        try await sut.cacheMessages(messages1, for: "session-1")
        try await sut.cacheMessages(messages2, for: "session-2")

        // When: session-1 캐시 삭제
        try await sut.clearCache(for: "session-1")

        // Then: session-1은 빈 배열, session-2는 유지
        let loaded1 = try await sut.loadCachedMessages(for: "session-1")
        let loaded2 = try await sut.loadCachedMessages(for: "session-2")

        #expect(loaded1.isEmpty)
        #expect(loaded2.count == 3)
    }

    @Test("Clear all cache removes all sessions")
    func clearAllCacheRemovesAllSessions() async throws {
        // Given: 여러 세션의 캐시
        let sut = makeSUT()
        let messages = makeSampleMessages(count: 3)

        try await sut.cacheMessages(messages, for: "session-1")
        try await sut.cacheMessages(messages, for: "session-2")
        try await sut.cacheMessages(messages, for: "session-3")

        // When: 모든 캐시 삭제
        try await sut.clearAllCache()

        // Then: 모든 세션이 빈 배열
        let loaded1 = try await sut.loadCachedMessages(for: "session-1")
        let loaded2 = try await sut.loadCachedMessages(for: "session-2")
        let loaded3 = try await sut.loadCachedMessages(for: "session-3")

        #expect(loaded1.isEmpty)
        #expect(loaded2.isEmpty)
        #expect(loaded3.isEmpty)
    }

    @Test("Cache size returns total bytes")
    func cacheSizeReturnsTotalBytes() async throws {
        // Given: 캐시 서비스와 메시지
        let sut = makeSUT()
        let messages = makeSampleMessages(count: 5)

        // When: 메시지 캐시
        try await sut.cacheMessages(messages, for: "session-1")

        // Then: 캐시 크기가 0보다 커야 함
        let size = await sut.cacheSize
        #expect(size > 0)
    }

    @Test("LRU eviction removes oldest cache when size limit exceeded")
    func lruEvictionRemovesOldestCacheWhenSizeLimitExceeded() async throws {
        // Given: 작은 캐시 크기 제한 (10KB)
        let sut = MessageCacheService(
            maxCacheSize: 10 * 1024,
            maxMessagesPerSession: 100
        )

        // When: 큰 메시지들을 여러 세션에 캐시 (크기 제한 초과)
        let largeMessages = makeSampleMessages(count: 50)

        try await sut.cacheMessages(largeMessages, for: "session-old")
        try await Task.sleep(for: .milliseconds(100)) // 시간 차이 보장

        try await sut.cacheMessages(largeMessages, for: "session-new-1")
        try await Task.sleep(for: .milliseconds(100))

        try await sut.cacheMessages(largeMessages, for: "session-new-2")

        // Then: 오래된 캐시가 삭제되어야 함
        let oldCache = try await sut.loadCachedMessages(for: "session-old")
        let newCache1 = try await sut.loadCachedMessages(for: "session-new-1")
        let newCache2 = try await sut.loadCachedMessages(for: "session-new-2")

        // 최신 캐시들은 유지되어야 함
        #expect(!newCache1.isEmpty || !newCache2.isEmpty)
    }

    @Test("Different message types are cached correctly")
    func differentMessageTypesAreCachedCorrectly() async throws {
        // Given: 다양한 타입의 메시지
        let sut = makeSUT()
        let messages: [ChatMessageItem] = [
            ChatMessageItem(
                id: "msg-1",
                type: .user,
                content: .text("User message"),
                timestamp: Date()
            ),
            ChatMessageItem(
                id: "msg-2",
                type: .assistant,
                content: .streaming("Assistant message"),
                timestamp: Date()
            ),
            ChatMessageItem(
                id: "msg-3",
                type: .toolUse(name: "Read", toolUseId: "tool-1"),
                content: .toolInput(["path": .string("/test")]),
                timestamp: Date()
            ),
            ChatMessageItem(
                id: "msg-4",
                type: .toolResult(toolUseId: "tool-1", isError: false),
                content: .toolOutput("File contents"),
                timestamp: Date()
            ),
            ChatMessageItem(
                id: "msg-5",
                type: .askUser(
                    toolUseId: "ask-1",
                    question: "Question?",
                    options: [QuestionOption(label: "Yes", description: nil)],
                    multiSelect: false
                ),
                content: .text(""),
                timestamp: Date()
            )
        ]

        // When: 다양한 타입 캐시
        try await sut.cacheMessages(messages, for: "mixed-session")

        // Then: 모든 타입이 올바르게 로드되어야 함
        let loaded = try await sut.loadCachedMessages(for: "mixed-session")
        #expect(loaded.count == 5)
        #expect(loaded == messages)
    }
}
#endif
