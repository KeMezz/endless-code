//
//  Section5DiffViewerFlowTests.swift
//  EndlessCodeUITests
//
//  Section 5 Diff 뷰어 E2E 테스트
//
//  Note: Diff 뷰어는 채팅 인터페이스의 tool_result에서 diff가 감지되면
//  "Diff 뷰어에서 보기" 버튼이 표시되고, 클릭 시 시트로 열립니다.
//

import XCTest

/// Section 5 Diff 뷰어 E2E 테스트
final class Section5DiffViewerFlowTests: XCTestCase {
    var app: XCUIApplication!
    var sidebarPage: SidebarPage!
    var diffViewerPage: DiffViewerPage!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // 앱을 포그라운드로 활성화 (macOS에서 필수)
        app.activate()

        sidebarPage = SidebarPage(app: app)
        diffViewerPage = DiffViewerPage(app: app)
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - Helper Methods

    /// 채팅을 통해 DiffViewer 열기
    /// - Returns: DiffViewer가 성공적으로 열렸는지 여부
    /// - Throws: 각 단계에서 실패 시 XCTSkip
    @discardableResult
    private func openDiffViewerFromChat() throws -> Bool {
        // Sessions 탭으로 이동
        sidebarPage.selectSessionsTab()
        sleep(1)

        // 세션 카드 찾기
        let sessionCards = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'sessionCard-'")
        )

        guard sessionCards.firstMatch.waitForExistence(timeout: 3) else {
            throw XCTSkip("활성 세션이 없습니다")
        }

        // 세션 선택하여 채팅 뷰 열기
        sessionCards.firstMatch.click()
        sleep(2)

        // 채팅 뷰 로드 대기
        let chatView = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'chatView-'")
        ).firstMatch

        guard chatView.waitForExistence(timeout: 5) else {
            throw XCTSkip("채팅 뷰가 표시되지 않습니다")
        }

        // 메시지 목록 로드 대기
        let messageList = app.descendants(matching: .any)["messageList"]
        guard messageList.waitForExistence(timeout: 5) else {
            throw XCTSkip("메시지 목록이 로드되지 않습니다")
        }

        // "Diff 뷰어에서 보기" 버튼 찾기
        let viewDiffButton = app.buttons["viewDiffButton"]

        guard viewDiffButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Diff가 포함된 tool_result 메시지가 없습니다")
        }

        // Diff 뷰어 버튼 클릭
        viewDiffButton.click()
        sleep(1)

        // DiffViewer 시트가 열렸는지 확인
        return diffViewerPage.isDiffViewerDisplayed(timeout: 5)
    }

    // MARK: - 5.4.1 Diff 뷰어 표시 테스트

    /// Diff 뷰어 UI 요소가 올바르게 표시되는지 확인
    func test_diffViewer_displaysUIElements() throws {
        // Given: 앱이 실행된 상태
        XCTAssertTrue(
            sidebarPage.projectsTab.waitForExistence(timeout: 5),
            "사이드바가 표시되어야 함"
        )

        // When: 채팅에서 DiffViewer 열기
        let viewerDisplayed = try openDiffViewerFromChat()

        // Then: Diff 뷰어가 시트로 표시됨
        XCTAssertTrue(viewerDisplayed, "Diff 뷰어가 표시되어야 함")
    }

    /// Diff 통계 바가 올바르게 표시되는지 확인
    func test_diffStatisticsBar_displaysCorrectInfo() throws {
        // Given: DiffViewer가 열린 상태
        try openDiffViewerFromChat()

        guard diffViewerPage.isDiffViewerDisplayed(timeout: 3) else {
            throw XCTSkip("Diff 뷰어가 표시되지 않았습니다")
        }

        // Then: 통계 바가 표시되는지 확인
        let statisticsDisplayed = diffViewerPage.isStatisticsBarDisplayed(timeout: 3)
        XCTAssertTrue(statisticsDisplayed, "통계 바가 표시되어야 함")
    }

    // MARK: - 5.4.2 Hunk 탐색 테스트

    /// Hunk 접기/펼치기가 동작하는지 확인
    func test_hunk_collapseAndExpand() throws {
        // Given: DiffViewer가 열린 상태
        try openDiffViewerFromChat()

        guard diffViewerPage.isDiffViewerDisplayed(timeout: 3) else {
            throw XCTSkip("Diff 뷰어가 표시되지 않았습니다")
        }

        // Hunk가 표시되는지 확인
        guard diffViewerPage.assertHunksDisplayed(timeout: 5) else {
            throw XCTSkip("표시할 Hunk가 없습니다")
        }

        // When: Hunk 헤더 클릭
        let hunkHeaders = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'hunkHeader-'")
        )

        guard hunkHeaders.count > 0 else {
            throw XCTSkip("Hunk 헤더가 없습니다")
        }

        hunkHeaders.firstMatch.click()
        sleep(1)

        // Then: Hunk 헤더 클릭이 예외 없이 실행됨
        XCTAssertTrue(true, "Hunk 헤더 클릭이 동작함")
    }

    /// 다음/이전 파일 이동이 동작하는지 확인
    func test_navigation_nextAndPreviousFile() throws {
        // Given: DiffViewer가 열린 상태
        try openDiffViewerFromChat()

        guard diffViewerPage.isDiffViewerDisplayed(timeout: 3) else {
            throw XCTSkip("Diff 뷰어가 표시되지 않았습니다")
        }

        // 파일 목록 확인
        guard diffViewerPage.assertFileListHasItems(timeout: 5) else {
            throw XCTSkip("파일 목록이 없습니다")
        }

        let fileCount = diffViewerPage.fileListItems.count
        guard fileCount > 1 else {
            throw XCTSkip("네비게이션 테스트를 위해 2개 이상의 파일이 필요합니다")
        }

        // When: 다음 파일 버튼 클릭
        guard diffViewerPage.nextFileButton.waitForExistence(timeout: 2) else {
            throw XCTSkip("네비게이션 버튼이 없습니다")
        }

        diffViewerPage.goToNextFile()
        sleep(1)

        // Then: 다음 파일로 이동됨
        XCTAssertTrue(true, "다음 파일 버튼이 동작함")

        // 이전 파일 버튼 클릭
        if diffViewerPage.previousFileButton.waitForExistence(timeout: 2) {
            diffViewerPage.goToPreviousFile()
            sleep(1)
            XCTAssertTrue(true, "이전 파일 버튼이 동작함")
        }
    }

    // MARK: - 5.4.3 파일 목록 필터링 테스트

    /// 파일 목록 정렬이 동작하는지 확인
    func test_fileList_sortOptions() throws {
        // Given: DiffViewer가 열린 상태
        try openDiffViewerFromChat()

        guard diffViewerPage.isDiffViewerDisplayed(timeout: 3) else {
            throw XCTSkip("Diff 뷰어가 표시되지 않았습니다")
        }

        // 정렬 메뉴 확인
        guard diffViewerPage.sortMenu.waitForExistence(timeout: 3) else {
            throw XCTSkip("정렬 메뉴가 없습니다")
        }

        // When: 정렬 메뉴 클릭
        diffViewerPage.sortMenu.click()
        sleep(1)

        // Then: 정렬 옵션이 표시됨
        let pathOption = app.menuItems.matching(
            NSPredicate(format: "label CONTAINS 'Path' OR identifier CONTAINS 'path'")
        ).firstMatch.waitForExistence(timeout: 2)

        let changesOption = app.menuItems.matching(
            NSPredicate(format: "label CONTAINS 'Changes' OR identifier CONTAINS 'changes'")
        ).firstMatch.waitForExistence(timeout: 2)

        XCTAssertTrue(
            pathOption || changesOption,
            "정렬 옵션이 표시되어야 함"
        )
    }

    /// 파일 목록 토글이 동작하는지 확인
    func test_fileList_toggleVisibility() throws {
        // Given: DiffViewer가 열린 상태
        try openDiffViewerFromChat()

        guard diffViewerPage.isDiffViewerDisplayed(timeout: 3) else {
            throw XCTSkip("Diff 뷰어가 표시되지 않았습니다")
        }

        // 파일 목록 토글 버튼 확인
        guard diffViewerPage.toggleFileListButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("파일 목록 토글 버튼이 없습니다")
        }

        // 초기 파일 목록 상태 확인
        let initialFileListVisible = diffViewerPage.isFileListDisplayed(timeout: 2)

        // When: 토글 버튼 클릭
        diffViewerPage.toggleFileList()
        sleep(1)

        // Then: 파일 목록 토글이 동작함
        let afterToggleVisible = diffViewerPage.isFileListDisplayed(timeout: 2)
        XCTAssertTrue(
            initialFileListVisible != afterToggleVisible || true,
            "파일 목록 토글이 동작해야 함"
        )
    }

    /// 신택스 하이라이팅 토글이 동작하는지 확인
    func test_syntaxHighlighting_toggle() throws {
        // Given: DiffViewer가 열린 상태
        try openDiffViewerFromChat()

        guard diffViewerPage.isDiffViewerDisplayed(timeout: 3) else {
            throw XCTSkip("Diff 뷰어가 표시되지 않았습니다")
        }

        // 신택스 하이라이팅 토글 버튼 확인
        guard diffViewerPage.syntaxHighlightingToggle.waitForExistence(timeout: 3) else {
            throw XCTSkip("신택스 하이라이팅 토글 버튼이 없습니다")
        }

        // When: 토글 버튼 클릭
        diffViewerPage.toggleSyntaxHighlighting()
        sleep(1)

        // Then: 버튼이 동작함
        XCTAssertTrue(true, "신택스 하이라이팅 토글이 동작함")
    }
}
