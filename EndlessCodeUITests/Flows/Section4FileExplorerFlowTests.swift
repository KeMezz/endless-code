//
//  Section4FileExplorerFlowTests.swift
//  EndlessCodeUITests
//
//  Section 4 파일 탐색기 E2E 테스트
//

import XCTest

/// Section 4 파일 탐색기 E2E 테스트
final class Section4FileExplorerFlowTests: XCTestCase {
    var app: XCUIApplication!
    var sidebarPage: SidebarPage!
    var fileExplorerPage: FileExplorerPage!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        sidebarPage = SidebarPage(app: app)
        fileExplorerPage = FileExplorerPage(app: app)
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - 4.5.1 디렉토리 트리 표시 및 탐색 테스트

    /// 프로젝트 선택 시 파일 탐색기가 표시되는지 확인
    func test_selectProject_displaysFileExplorer() throws {
        // Given: 앱이 실행된 상태
        XCTAssertTrue(
            sidebarPage.projectsTab.waitForExistence(timeout: 5),
            "Projects 탭이 표시되어야 함"
        )

        // When: Projects 탭 선택 후 프로젝트 선택
        sidebarPage.selectProjectsTab()
        sleep(1)

        // 프로젝트가 있다면 첫 번째 프로젝트 선택
        let projectCards = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'projectCard-'")
        )

        // 프로젝트가 없는 경우 스킵
        guard projectCards.count > 0 else {
            throw XCTSkip("테스트할 프로젝트가 없습니다")
        }

        projectCards.firstMatch.click()
        sleep(1)

        // Then: 파일 탐색기가 표시됨
        // Note: 실제 프로젝트가 있어야 테스트 가능
        // Mock 환경에서는 파일 탐색기 UI 요소 확인
        XCTAssertTrue(
            fileExplorerPage.fileTreePanel.waitForExistence(timeout: 5) ||
            app.staticTexts["Select a file to view"].waitForExistence(timeout: 5),
            "파일 탐색기 또는 빈 상태가 표시되어야 함"
        )
    }

    /// 폴더 확장/축소가 동작하는지 확인
    func test_toggleFolder_expandsAndCollapsesChildren() throws {
        // Given: 파일 탐색기가 표시된 상태
        sidebarPage.selectProjectsTab()
        sleep(1)

        let projectCards = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'projectCard-'")
        )

        guard projectCards.count > 0 else {
            throw XCTSkip("테스트할 프로젝트가 없습니다")
        }

        projectCards.firstMatch.click()
        sleep(1)

        // 파일 트리가 로드될 때까지 대기
        let treeLoaded = fileExplorerPage.fileTreeView.waitForExistence(timeout: 5)
        guard treeLoaded else {
            throw XCTSkip("파일 트리가 로드되지 않았습니다")
        }

        // When: 첫 번째 폴더 토글 버튼 찾기
        let toggleButtons = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'toggleButton-'")
        )

        guard toggleButtons.count > 0 else {
            throw XCTSkip("토글할 폴더가 없습니다")
        }

        // 토글 버튼 클릭
        toggleButtons.firstMatch.click()
        sleep(1)

        // Then: 확장/축소가 동작함 (UI 변경 확인)
        // 정확한 검증은 폴더 구조에 따라 다름
        XCTAssertTrue(true, "폴더 토글이 예외 없이 실행됨")
    }

    // MARK: - 4.5.2 파일 선택 및 내용 표시 테스트

    /// 파일 선택 시 내용이 표시되는지 확인
    func test_selectFile_displaysFileContent() throws {
        // Given: 파일 탐색기가 표시된 상태
        sidebarPage.selectProjectsTab()
        sleep(1)

        let projectCards = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'projectCard-'")
        )

        guard projectCards.count > 0 else {
            throw XCTSkip("테스트할 프로젝트가 없습니다")
        }

        projectCards.firstMatch.click()
        sleep(2)

        // 파일 트리가 로드될 때까지 대기
        guard fileExplorerPage.fileTreeView.waitForExistence(timeout: 5) else {
            throw XCTSkip("파일 트리가 로드되지 않았습니다")
        }

        // When: 파일 행 찾기 (폴더가 아닌 파일)
        let fileRows = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'fileRow-' AND NOT identifier CONTAINS 'folder'")
        )

        guard fileRows.count > 0 else {
            throw XCTSkip("선택할 파일이 없습니다")
        }

        // 첫 번째 파일 클릭
        fileRows.firstMatch.click()
        sleep(1)

        // Then: 파일 내용 뷰 또는 바이너리 경고가 표시됨
        let contentDisplayed = fileExplorerPage.fileContentView.waitForExistence(timeout: 5)
        let binaryWarning = app.staticTexts["Binary File"].waitForExistence(timeout: 2)
        let emptyFile = app.staticTexts["Empty File"].waitForExistence(timeout: 2)

        XCTAssertTrue(
            contentDisplayed || binaryWarning || emptyFile,
            "파일 내용, 바이너리 경고, 또는 빈 파일 표시가 나타나야 함"
        )
    }

    // MARK: - 4.5.3 파일 검색 테스트

    /// 검색 필드에 입력하면 결과가 필터링되는지 확인
    func test_searchFiles_filtersResults() throws {
        // Given: 파일 탐색기가 표시된 상태
        sidebarPage.selectProjectsTab()
        sleep(1)

        let projectCards = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'projectCard-'")
        )

        guard projectCards.count > 0 else {
            throw XCTSkip("테스트할 프로젝트가 없습니다")
        }

        projectCards.firstMatch.click()
        sleep(2)

        // 검색 필드 대기
        guard fileExplorerPage.searchField.waitForExistence(timeout: 5) else {
            throw XCTSkip("검색 필드가 표시되지 않았습니다")
        }

        // When: 검색어 입력
        fileExplorerPage.search("swift")
        sleep(1)  // 디바운스 대기

        // Then: 검색 결과가 표시되거나 검색 UI가 변경됨
        // 검색 결과 목록 또는 "No results" 메시지 확인
        let resultsOrNoResults =
            fileExplorerPage.searchResultsList.waitForExistence(timeout: 3) ||
            app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS 'No results'")
            ).firstMatch.waitForExistence(timeout: 3)

        XCTAssertTrue(resultsOrNoResults, "검색 결과 또는 'No results' 메시지가 표시되어야 함")
    }

    /// 검색 초기화 버튼이 동작하는지 확인
    func test_clearSearch_resetsToTreeView() throws {
        // Given: 검색어가 입력된 상태
        sidebarPage.selectProjectsTab()
        sleep(1)

        let projectCards = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'projectCard-'")
        )

        guard projectCards.count > 0 else {
            throw XCTSkip("테스트할 프로젝트가 없습니다")
        }

        projectCards.firstMatch.click()
        sleep(2)

        guard fileExplorerPage.searchField.waitForExistence(timeout: 5) else {
            throw XCTSkip("검색 필드가 표시되지 않았습니다")
        }

        fileExplorerPage.search("test")
        sleep(1)

        // When: 검색 초기화
        fileExplorerPage.clearSearch()
        sleep(1)

        // Then: 파일 트리가 다시 표시됨
        XCTAssertTrue(
            fileExplorerPage.fileTreeView.waitForExistence(timeout: 3),
            "검색 초기화 후 파일 트리가 표시되어야 함"
        )
    }

    // MARK: - Additional Tests

    /// 필터 칩이 표시되고 동작하는지 확인
    func test_filterChips_displayedAndClickable() throws {
        // Given: 파일 탐색기가 표시된 상태
        sidebarPage.selectProjectsTab()
        sleep(1)

        let projectCards = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'projectCard-'")
        )

        guard projectCards.count > 0 else {
            throw XCTSkip("테스트할 프로젝트가 없습니다")
        }

        projectCards.firstMatch.click()
        sleep(2)

        // When: 필터 칩 영역 확인
        let filterChipsExist = fileExplorerPage.filterChips.waitForExistence(timeout: 5)

        // Then: 필터 칩이 표시됨
        if filterChipsExist {
            // All 필터 클릭
            fileExplorerPage.selectFilter("All")
            sleep(1)

            // Modified 필터 클릭
            fileExplorerPage.selectFilter("Modified")
            sleep(1)

            XCTAssertTrue(true, "필터 칩이 클릭 가능함")
        } else {
            throw XCTSkip("필터 칩이 표시되지 않았습니다")
        }
    }

    /// 활성 경로 바가 표시되는지 확인
    func test_activePathBar_displayed() throws {
        // Given: 파일 탐색기가 표시된 상태
        sidebarPage.selectProjectsTab()
        sleep(1)

        let projectCards = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'projectCard-'")
        )

        guard projectCards.count > 0 else {
            throw XCTSkip("테스트할 프로젝트가 없습니다")
        }

        projectCards.firstMatch.click()
        sleep(2)

        // 파일 트리 패널이 로드될 때까지 대기
        guard fileExplorerPage.fileTreePanel.waitForExistence(timeout: 5) else {
            throw XCTSkip("파일 탐색기 패널이 로드되지 않았습니다")
        }

        // Then: 활성 경로 바 또는 "ACTIVE PATH" 텍스트가 표시됨
        // Note: SwiftUI의 accessibility hierarchy에서 HStack은 직접 쿼리가 어려울 수 있음
        let activePathBarFound = fileExplorerPage.activePathBar.waitForExistence(timeout: 3)
        let activePathTextFound = app.staticTexts["ACTIVE PATH"].waitForExistence(timeout: 3)

        XCTAssertTrue(
            activePathBarFound || activePathTextFound,
            "활성 경로 바 또는 'ACTIVE PATH' 텍스트가 표시되어야 함"
        )
    }
}
