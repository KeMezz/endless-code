//
//  DiffViewerPage.swift
//  EndlessCodeUITests
//
//  Diff 뷰어 Page Object
//

import XCTest

/// Diff 뷰어 Page Object
struct DiffViewerPage {
    let app: XCUIApplication

    // MARK: - Main Elements

    /// Diff 뷰어 메인 뷰
    var diffViewerView: XCUIElement {
        app.descendants(matching: .any)["diffViewerView"]
    }

    /// 통계 바
    var statisticsBar: XCUIElement {
        app.descendants(matching: .any)["diffStatisticsBar"]
    }

    /// 파일 목록 (사이드바)
    var fileList: XCUIElement {
        app.descendants(matching: .any)["diffFileList"]
    }

    // MARK: - Toolbar Elements

    /// 파일 목록 토글 버튼
    var toggleFileListButton: XCUIElement {
        app.buttons["toggleFileListButton"]
    }

    /// 이전 파일 버튼
    var previousFileButton: XCUIElement {
        app.buttons["previousFileButton"]
    }

    /// 다음 파일 버튼
    var nextFileButton: XCUIElement {
        app.buttons["nextFileButton"]
    }

    /// 정렬 메뉴
    var sortMenu: XCUIElement {
        app.descendants(matching: .any)["sortMenu"]
    }

    /// 신택스 하이라이팅 토글
    var syntaxHighlightingToggle: XCUIElement {
        app.buttons["syntaxHighlightingToggle"]
    }

    // MARK: - File List Elements

    /// 특정 파일 목록 아이템
    func fileListItem(id: String) -> XCUIElement {
        app.descendants(matching: .any)["diffFileListItem-\(id)"]
    }

    /// 파일 목록 아이템들
    var fileListItems: XCUIElementQuery {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'diffFileListItem-'")
        )
    }

    // MARK: - Diff Content Elements

    /// 특정 파일의 Diff 뷰
    func diffFileView(id: String) -> XCUIElement {
        app.descendants(matching: .any)["diffFile-\(id)"]
    }

    /// 특정 파일의 헤더
    func diffFileHeader(id: String) -> XCUIElement {
        app.descendants(matching: .any)["diffFileHeader-\(id)"]
    }

    /// 특정 Hunk 뷰
    func diffHunk(id: String) -> XCUIElement {
        app.descendants(matching: .any)["diffHunk-\(id)"]
    }

    /// Hunk 헤더
    func hunkHeader(id: String) -> XCUIElement {
        app.descendants(matching: .any)["hunkHeader-\(id)"]
    }

    /// Diff 파일들
    var diffFiles: XCUIElementQuery {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'diffFile-'")
        )
    }

    /// Diff Hunks
    var diffHunks: XCUIElementQuery {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'diffHunk-'")
        )
    }

    // MARK: - State Indicators

    /// 로딩 상태인지 확인
    func isLoading() -> Bool {
        app.activityIndicators.firstMatch.exists
    }

    /// Diff 뷰어가 표시되는지 확인
    func isDiffViewerDisplayed(timeout: TimeInterval = 5) -> Bool {
        diffViewerView.waitForExistence(timeout: timeout)
    }

    /// 파일 목록이 표시되는지 확인
    func isFileListDisplayed(timeout: TimeInterval = 5) -> Bool {
        fileList.waitForExistence(timeout: timeout)
    }

    /// 통계 바가 표시되는지 확인
    func isStatisticsBarDisplayed(timeout: TimeInterval = 3) -> Bool {
        statisticsBar.waitForExistence(timeout: timeout)
    }

    // MARK: - Actions

    /// 파일 목록 토글
    func toggleFileList() {
        if toggleFileListButton.waitForExistence(timeout: 2) {
            toggleFileListButton.click()
        }
    }

    /// 다음 파일로 이동
    func goToNextFile() {
        if nextFileButton.waitForExistence(timeout: 2) {
            nextFileButton.click()
        }
    }

    /// 이전 파일로 이동
    func goToPreviousFile() {
        if previousFileButton.waitForExistence(timeout: 2) {
            previousFileButton.click()
        }
    }

    /// 신택스 하이라이팅 토글
    func toggleSyntaxHighlighting() {
        if syntaxHighlightingToggle.waitForExistence(timeout: 2) {
            syntaxHighlightingToggle.click()
        }
    }

    /// Hunk 헤더 클릭 (접기/펼치기)
    func clickHunkHeader(id: String) {
        let header = hunkHeader(id: id)
        if header.waitForExistence(timeout: 2) {
            header.click()
        }
    }

    /// 파일 헤더 클릭 (접기/펼치기)
    func clickFileHeader(id: String) {
        let header = diffFileHeader(id: id)
        if header.waitForExistence(timeout: 2) {
            header.click()
        }
    }

    // MARK: - Assertions

    /// Diff 콘텐츠가 있는지 확인 (파일이 1개 이상)
    func assertDiffContentDisplayed(timeout: TimeInterval = 5) -> Bool {
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            if diffFiles.count > 0 {
                return true
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        return false
    }

    /// Hunk가 있는지 확인
    func assertHunksDisplayed(timeout: TimeInterval = 5) -> Bool {
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            if diffHunks.count > 0 {
                return true
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        return false
    }

    /// 파일 목록에 파일이 있는지 확인
    func assertFileListHasItems(timeout: TimeInterval = 5) -> Bool {
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            if fileListItems.count > 0 {
                return true
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        return false
    }
}
