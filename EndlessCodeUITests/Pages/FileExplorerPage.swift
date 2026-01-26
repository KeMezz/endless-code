//
//  FileExplorerPage.swift
//  EndlessCodeUITests
//
//  파일 탐색기 Page Object
//

import XCTest

/// 파일 탐색기 Page Object
struct FileExplorerPage {
    let app: XCUIApplication

    // MARK: - Main Elements

    /// 파일 탐색기 뷰
    var fileExplorerView: XCUIElement {
        app.descendants(matching: .any)["fileExplorerView"]
    }

    /// 파일 트리 패널
    var fileTreePanel: XCUIElement {
        app.descendants(matching: .any)["fileTreePanel"]
    }

    /// 파일 뷰어 패널
    var fileViewerPanel: XCUIElement {
        app.descendants(matching: .any)["fileViewerPanel"]
    }

    // MARK: - Search Elements

    /// 검색 필드
    var searchField: XCUIElement {
        app.descendants(matching: .any)["fileSearchField"]
    }

    /// 검색 입력 필드
    var searchInput: XCUIElement {
        searchField.textFields.firstMatch
    }

    /// 검색 결과 목록
    var searchResultsList: XCUIElement {
        app.descendants(matching: .any)["searchResultsList"]
    }

    /// 검색 결과 초기화 버튼
    var clearSearchButton: XCUIElement {
        app.buttons["clearSearchButton"]
    }

    // MARK: - Filter Elements

    /// 필터 칩 영역
    var filterChips: XCUIElement {
        app.descendants(matching: .any)["fileFilterChips"]
    }

    /// 브랜치 칩 (동적 이름)
    func branchChip(named branchName: String) -> XCUIElement {
        app.descendants(matching: .any)["branchChip-\(branchName)"]
    }

    /// 필터 칩 (All, Modified, Recent, New)
    func filterChip(_ filter: String) -> XCUIElement {
        app.buttons["filterChip-\(filter)"]
    }

    // MARK: - File Tree Elements

    /// 파일 트리 뷰
    var fileTreeView: XCUIElement {
        app.descendants(matching: .any)["fileTreeView"]
    }

    /// 파일 트리 아이템들 (fileTreeItem-* identifier를 가진 요소들)
    var fileTreeItems: XCUIElementQuery {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'fileTreeItem-'")
        )
    }

    /// 파일 트리가 로드되었는지 확인 (아이템이 존재하는지로 판단)
    func isFileTreeLoaded(timeout: TimeInterval = 5) -> Bool {
        // 먼저 fileTreeView identifier로 시도
        if fileTreeView.waitForExistence(timeout: 1) {
            return true
        }
        // fallback: fileTreeItem-* 요소가 있는지 확인
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            if fileTreeItems.count > 0 {
                return true
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        return false
    }

    /// 파일/폴더 행
    func fileRow(named name: String) -> XCUIElement {
        app.descendants(matching: .any)["fileRow-\(name)"]
    }

    /// 폴더 토글 버튼
    func toggleButton(for folderName: String) -> XCUIElement {
        app.buttons["toggleButton-\(folderName)"]
    }

    /// Git 상태 뱃지
    func gitBadge(_ status: String) -> XCUIElement {
        app.descendants(matching: .any)["gitBadge-\(status)"]
    }

    // MARK: - File Viewer Elements

    /// 파일 콘텐츠 뷰
    var fileContentView: XCUIElement {
        app.descendants(matching: .any)["fileContentView"]
    }

    /// 코드 스크롤 뷰
    var codeScrollView: XCUIElement {
        app.descendants(matching: .any)["codeScrollView"]
    }

    /// 라인 번호 영역
    var lineNumbers: XCUIElement {
        app.descendants(matching: .any)["lineNumbers"]
    }

    // MARK: - Bottom Bar Elements

    /// 활성 경로 바
    var activePathBar: XCUIElement {
        app.descendants(matching: .any)["activePathBar"]
    }

    /// 즐겨찾기 버튼
    var favoriteButton: XCUIElement {
        app.buttons["favoriteButton"]
    }

    /// 새 파일 버튼
    var newFileButton: XCUIElement {
        app.buttons["newFileButton"]
    }

    // MARK: - Toolbar Elements

    /// 새로고침 버튼
    var refreshButton: XCUIElement {
        app.buttons["refreshButton"]
    }

    /// Git 새로고침 버튼
    var refreshGitButton: XCUIElement {
        app.buttons["refreshGitButton"]
    }

    // MARK: - Actions

    /// 검색어 입력
    func search(_ text: String) {
        if searchInput.waitForExistence(timeout: 3) {
            searchInput.click()
            searchInput.typeText(text)
        }
    }

    /// 검색 초기화
    func clearSearch() {
        if clearSearchButton.waitForExistence(timeout: 2) {
            clearSearchButton.click()
        }
    }

    /// 필터 선택
    func selectFilter(_ filter: String) {
        let chip = filterChip(filter)
        if chip.waitForExistence(timeout: 2) {
            chip.click()
        }
    }

    /// 파일/폴더 클릭
    func clickItem(named name: String) {
        let row = fileRow(named: name)
        if row.waitForExistence(timeout: 2) {
            row.click()
        }
    }

    /// 폴더 확장/축소
    func toggleFolder(named name: String) {
        let button = toggleButton(for: name)
        if button.waitForExistence(timeout: 2) {
            button.click()
        }
    }

    /// 검색 결과 항목 클릭
    func clickSearchResult(named name: String) -> Bool {
        let result = app.descendants(matching: .any)["searchResult-\(name)"]
        if result.waitForExistence(timeout: 2) {
            result.click()
            return true
        }
        return false
    }

    /// 새로고침 실행
    func refresh() {
        if refreshButton.waitForExistence(timeout: 2) {
            refreshButton.click()
        }
    }

    // MARK: - Assertions

    /// 파일 탐색기가 표시되는지 확인
    func assertFileExplorerDisplayed() -> Bool {
        fileExplorerView.waitForExistence(timeout: 5)
    }

    /// 파일 트리가 표시되는지 확인
    func assertFileTreeDisplayed() -> Bool {
        fileTreeView.waitForExistence(timeout: 5)
    }

    /// 파일 콘텐츠가 표시되는지 확인
    func assertFileContentDisplayed() -> Bool {
        fileContentView.waitForExistence(timeout: 5)
    }

    /// 특정 파일이 트리에 표시되는지 확인
    func assertFileExists(named name: String) -> Bool {
        fileRow(named: name).waitForExistence(timeout: 3)
    }

    /// 검색 결과가 표시되는지 확인
    func assertSearchResultsDisplayed() -> Bool {
        searchResultsList.waitForExistence(timeout: 3)
    }

    /// 브랜치 칩이 표시되는지 확인
    func assertBranchChipDisplayed(_ branchName: String) -> Bool {
        branchChip(named: branchName).waitForExistence(timeout: 3)
    }

    /// Git 뱃지가 표시되는지 확인
    func assertGitBadgeDisplayed(_ status: String) -> Bool {
        gitBadge(status).waitForExistence(timeout: 3)
    }
}
