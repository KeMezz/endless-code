//
//  Section2NavigationFlowTests.swift
//  EndlessCodeUITests
//
//  Section 2: macOS 공통 컴포넌트 E2E 테스트
//

import XCTest

final class Section2NavigationFlowTests: XCTestCase {
    var app: XCUIApplication!
    var sidebarPage: SidebarPage!
    var projectBrowserPage: ProjectBrowserPage!
    var sessionListPage: SessionListPage!
    var detailPage: DetailPage!

    // MARK: - Setup

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // 앱을 포그라운드로 활성화 (macOS에서 필수)
        app.activate()

        sidebarPage = SidebarPage(app: app)
        projectBrowserPage = ProjectBrowserPage(app: app)
        sessionListPage = SessionListPage(app: app)
        detailPage = DetailPage(app: app)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - 2.1 앱 구조 테스트

    /// 2.1.1 앱 실행 시 메인 뷰가 표시되는지 확인
    func test_appLaunch_showsMainView() throws {
        // Given: 앱이 실행됨

        // Then: 사이드바가 표시되어야 함
        XCTAssertTrue(sidebarPage.sidebar.waitForExistence(timeout: 10),
                      "사이드바가 표시되어야 합니다")

        // Then: 연결 상태 인디케이터가 표시되어야 함
        XCTAssertTrue(sidebarPage.connectionStatus.waitForExistence(timeout: 5),
                      "연결 상태 인디케이터가 표시되어야 합니다")

        // 스크린샷 저장
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "AppLaunch-MainView"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 2.1.2 사이드바 탭 전환 테스트 - Projects → Sessions
    func test_sidebarNavigation_projectsToSessions() throws {
        // Given: 앱이 실행되고 Projects 탭이 기본 선택됨
        XCTAssertTrue(sidebarPage.projectsTab.waitForExistence(timeout: 5))

        // When: Sessions 탭 클릭
        sidebarPage.selectSessionsTab()

        // Then: Sessions 목록이 표시되어야 함
        XCTAssertTrue(sessionListPage.sessionList.waitForExistence(timeout: 10),
                      "세션 목록이 표시되어야 합니다")

        // 스크린샷 저장
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Navigation-SessionsList"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 2.1.3 사이드바 탭 전환 테스트 - Sessions → Settings
    func test_sidebarNavigation_sessionsToSettings() throws {
        // Given: Sessions 탭으로 이동
        sidebarPage.selectSessionsTab()
        XCTAssertTrue(sessionListPage.sessionList.waitForExistence(timeout: 10))

        // When: Settings 탭 클릭
        sidebarPage.selectSettingsTab()

        // Then: Settings 뷰가 표시되어야 함
        XCTAssertTrue(detailPage.isSettingsListVisible(timeout: 5),
                      "설정 목록이 표시되어야 합니다")

        // 스크린샷 저장
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Navigation-SettingsList"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 2.1.4 사이드바 탭 전환 테스트 - Settings → Projects
    func test_sidebarNavigation_settingsToProjects() throws {
        // Given: Settings 탭으로 이동
        sidebarPage.selectSettingsTab()
        XCTAssertTrue(detailPage.isSettingsListVisible(timeout: 5))

        // When: Projects 탭 클릭
        sidebarPage.selectProjectsTab()

        // Then: Projects 목록이 표시되어야 함
        XCTAssertTrue(projectBrowserPage.projectList.waitForExistence(timeout: 10),
                      "프로젝트 목록이 표시되어야 합니다")

        // 스크린샷 저장
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Navigation-ProjectsList"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - 2.2 프로젝트 브라우저 테스트

    /// 2.2.1 프로젝트 목록 표시 테스트
    func test_projectBrowser_showsProjectList() throws {
        // Given: Projects 탭이 선택됨 (기본값)
        // Then: 프로젝트 목록이 표시되어야 함
        XCTAssertTrue(projectBrowserPage.projectList.waitForExistence(timeout: 10),
                      "프로젝트 목록이 표시되어야 합니다")

        // Then: 샘플 프로젝트가 표시되어야 함 (최소 1개)
        XCTAssertGreaterThanOrEqual(projectBrowserPage.projectCount, 1,
                                    "최소 1개 이상의 프로젝트가 표시되어야 합니다")

        // 스크린샷 저장
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "ProjectBrowser-List"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 2.2.2 프로젝트 검색 테스트
    func test_projectBrowser_searchFiltersProjects() throws {
        // Given: 프로젝트 목록이 표시됨
        XCTAssertTrue(projectBrowserPage.projectList.waitForExistence(timeout: 10))

        // When: 검색어 입력
        if projectBrowserPage.searchField.waitForExistence(timeout: 5) {
            projectBrowserPage.searchProjects("Endless")

            // 스크린샷 저장
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "ProjectBrowser-Search"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    /// 2.2.3 프로젝트 선택 시 상세 뷰 표시 테스트
    func test_projectBrowser_selectProject_showsDetail() throws {
        // Given: 프로젝트 목록이 표시됨
        XCTAssertTrue(projectBrowserPage.projectList.waitForExistence(timeout: 10))

        // When: 첫 번째 프로젝트 선택
        let firstProject = projectBrowserPage.projectCard(id: "project-1")
        if firstProject.waitForExistence(timeout: 5) {
            firstProject.click()

            // Then: 프로젝트 상세 뷰가 표시되어야 함
            XCTAssertTrue(detailPage.isProjectDetailVisible(id: "project-1", timeout: 5),
                          "프로젝트 상세 뷰가 표시되어야 합니다")

            // 스크린샷 저장
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "ProjectBrowser-Detail"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    // MARK: - 2.3 세션 목록 테스트

    /// 2.3.1 세션 목록 표시 테스트
    func test_sessionList_showsSessionList() throws {
        // Given: Sessions 탭으로 이동
        sidebarPage.selectSessionsTab()

        // Then: 세션 목록이 표시되어야 함
        XCTAssertTrue(sessionListPage.sessionList.waitForExistence(timeout: 10),
                      "세션 목록이 표시되어야 합니다")

        // 스크린샷 저장
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "SessionList-View"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 2.3.2 세션 검색 필드 존재 테스트
    func test_sessionList_hasSearchField() throws {
        // Given: Sessions 탭으로 이동
        sidebarPage.selectSessionsTab()
        XCTAssertTrue(sessionListPage.sessionList.waitForExistence(timeout: 10))

        // Then: 검색 필드가 존재해야 함
        XCTAssertTrue(sessionListPage.searchField.waitForExistence(timeout: 5),
                      "세션 검색 필드가 존재해야 합니다")
    }

    /// 2.3.3 세션 상태 필터 존재 테스트
    func test_sessionList_hasStateFilter() throws {
        // Given: Sessions 탭으로 이동
        sidebarPage.selectSessionsTab()
        XCTAssertTrue(sessionListPage.sessionList.waitForExistence(timeout: 10))

        // Then: 상태 필터가 존재해야 함
        XCTAssertTrue(sessionListPage.stateFilter.waitForExistence(timeout: 5),
                      "세션 상태 필터가 존재해야 합니다")
    }

    // MARK: - 전체 플로우 테스트

    /// 전체 네비게이션 플로우 테스트
    func test_fullNavigationFlow() throws {
        // 1. 앱 실행 확인
        XCTAssertTrue(sidebarPage.sidebar.waitForExistence(timeout: 10))

        // 2. Projects 탭 확인
        XCTAssertTrue(projectBrowserPage.projectList.waitForExistence(timeout: 10))

        // 3. Sessions 탭으로 이동
        sidebarPage.selectSessionsTab()
        XCTAssertTrue(sessionListPage.sessionList.waitForExistence(timeout: 10))

        // 4. Settings 탭으로 이동
        sidebarPage.selectSettingsTab()
        XCTAssertTrue(detailPage.isSettingsListVisible(timeout: 5))

        // 5. Projects 탭으로 복귀
        sidebarPage.selectProjectsTab()
        XCTAssertTrue(projectBrowserPage.projectList.waitForExistence(timeout: 10))

        // 최종 스크린샷
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "FullNavigationFlow-Complete"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
