//
//  iOSAppStateTests.swift
//  EndlessCodeTests
//
//  iOSAppState 테스트
//

#if os(iOS)
import Testing
@testable import EndlessCode

@Suite("iOSAppState Tests")
@MainActor
struct iOSAppStateTests {
    // MARK: - Initialization Tests

    @Test("Initial state has correct default values")
    func initialStateHasCorrectDefaults() {
        // Given & When
        let sut = iOSAppState()

        // Then
        #expect(sut.selectedTab == .projects)
        #expect(sut.selectedProject == nil)
        #expect(sut.selectedSession == nil)
        #expect(sut.connectionState == .disconnected)
        #expect(sut.projects.isEmpty)
        #expect(sut.activeSessions.isEmpty)
        #expect(sut.messages.isEmpty)
        #expect(sut.errorMessage == nil)
        #expect(sut.toastMessage == nil)
        #expect(sut.isLoading == false)
    }

    // MARK: - Project Selection Tests

    @Test("Select project updates selectedProject and clears session")
    func selectProjectUpdatesSelectedProjectAndClearsSession() {
        // Given
        let sut = iOSAppState()
        let project = Project(
            id: "proj-1",
            name: "TestProject",
            path: "/test/path"
        )
        sut.selectedSession = Session(id: "sess-1", projectId: "other-proj")
        sut.messages = ChatMessageItem.sampleMessages

        // When
        sut.selectProject(project)

        // Then
        #expect(sut.selectedProject?.id == "proj-1")
        #expect(sut.selectedSession == nil)
        #expect(sut.messages.isEmpty)
    }

    // MARK: - Session Selection Tests

    @Test("Select session updates selectedSession and switches to chat tab")
    func selectSessionUpdatesSessionAndSwitchesTab() {
        // Given
        let sut = iOSAppState()
        let session = Session(id: "sess-1", projectId: "proj-1")
        sut.selectedTab = .projects

        // When
        sut.selectSession(session)

        // Then
        #expect(sut.selectedSession?.id == "sess-1")
        #expect(sut.selectedTab == .chat)
        #expect(!sut.messages.isEmpty) // Sample messages loaded
    }

    // MARK: - Error Handling Tests

    @Test("Show error sets error message")
    func showErrorSetsErrorMessage() {
        // Given
        let sut = iOSAppState()

        // When
        sut.showError("Test error message")

        // Then
        #expect(sut.errorMessage == "Test error message")
    }

    @Test("Clear error removes error message")
    func clearErrorRemovesErrorMessage() {
        // Given
        let sut = iOSAppState()
        sut.showError("Test error")

        // When
        sut.clearError()

        // Then
        #expect(sut.errorMessage == nil)
    }

    // MARK: - Toast Tests

    @Test("Show toast sets toast message")
    func showToastSetsToastMessage() {
        // Given
        let sut = iOSAppState()

        // When
        sut.showToast("Test toast")

        // Then
        #expect(sut.toastMessage == "Test toast")
    }

    @Test("Toast message clears after delay")
    func toastMessageClearsAfterDelay() async {
        // Given
        let sut = iOSAppState()

        // When
        sut.showToast("Test toast")

        // Wait for auto-clear (3 seconds + margin)
        try? await Task.sleep(for: .seconds(3.2))

        // Then
        #expect(sut.toastMessage == nil)
    }

    // MARK: - iOSTab Tests

    @Test("iOSTab has correct icons")
    func iOSTabHasCorrectIcons() {
        // Then
        #expect(iOSTab.projects.icon == "folder.fill")
        #expect(iOSTab.chat.icon == "bubble.left.and.bubble.right.fill")
        #expect(iOSTab.files.icon == "doc.text.fill")
        #expect(iOSTab.settings.icon == "gearshape.fill")
    }

    @Test("iOSTab rawValue equals id")
    func iOSTabRawValueEqualsId() {
        // Then
        for tab in iOSTab.allCases {
            #expect(tab.rawValue == tab.id)
        }
    }

    // MARK: - Preview Data Tests

    @Test("Preview state has sample data")
    func previewStateHasSampleData() {
        // Given & When
        let sut = iOSAppState.preview

        // Then
        #expect(sut.connectionState == .connected)
        #expect(!sut.projects.isEmpty)
        #expect(!sut.activeSessions.isEmpty)
        #expect(sut.projects.count == 3)
        #expect(sut.activeSessions.count == 2)
    }
}
#endif
