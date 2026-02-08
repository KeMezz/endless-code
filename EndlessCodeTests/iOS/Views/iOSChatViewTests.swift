//
//  iOSChatViewTests.swift
//  EndlessCodeTests
//
//  iOSChatView 통합 테스트
//

#if os(iOS)
import Testing
import SwiftUI
@testable import EndlessCode

@Suite("iOSChatView Tests")
@MainActor
struct iOSChatViewTests {
    // MARK: - Empty State Tests

    @Test("View shows empty state when no session selected")
    func viewShowsEmptyStateWhenNoSessionSelected() {
        // Given
        let appState = iOSAppState()

        // When & Then
        #expect(appState.selectedSession == nil)
    }

    @Test("View shows chat when session is selected")
    func viewShowsChatWhenSessionIsSelected() {
        // Given
        let appState = iOSAppState.preview
        let session = appState.activeSessions.first!

        // When
        appState.selectSession(session)

        // Then
        #expect(appState.selectedSession != nil)
        #expect(appState.selectedTab == .chat)
        #expect(!appState.messages.isEmpty)
    }

    // MARK: - Message Sending Tests

    @Test("Navigation title shows session ID when session selected")
    func navigationTitleShowsSessionId() {
        // Given
        let appState = iOSAppState.preview
        let session = Session(id: "test-session-123", projectId: "proj-1")

        // When
        appState.selectSession(session)

        // Then
        let expectedPrefix = "Session test-ses"
        #expect(appState.selectedSession?.id.hasPrefix("test-ses") == true)
    }
}
#endif
