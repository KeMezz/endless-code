//
//  SessionListPage.swift
//  EndlessCodeUITests
//
//  세션 목록 Page Object
//

import XCTest

/// 세션 목록 Page Object
struct SessionListPage {
    let app: XCUIApplication

    // MARK: - Elements

    /// 세션 목록 - 세션 카드가 존재하는지로 확인
    /// (SwiftUI ScrollView의 accessibilityIdentifier 전파 문제 우회)
    var sessionList: XCUIElement {
        // sessionCard가 하나라도 존재하면 목록이 로드된 것
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'sessionCard-'")).firstMatch
    }

    /// 검색 필드 - placeholder 텍스트로 찾기
    var searchField: XCUIElement {
        // identifier가 contentColumn으로 override될 수 있어서 placeholder로 찾기
        let field = app.textFields["sessionSearchField"]
        if field.exists {
            return field
        }
        // fallback: placeholder 텍스트로 찾기
        return app.textFields.matching(
            NSPredicate(format: "placeholderValue == 'Search sessions...'")
        ).firstMatch
    }

    /// 상태 필터 - Menu로 구현됨
    var stateFilter: XCUIElement {
        // identifier가 contentColumn으로 override될 수 있어서 여러 방법 시도
        let filter = app.descendants(matching: .any)["sessionStateFilter"]
        if filter.exists {
            return filter
        }
        // fallback: 메뉴 버튼들 중 필터 아이콘이 있는 것 찾기
        return app.menuButtons.matching(
            NSPredicate(format: "identifier == 'contentColumn'")
        ).element(boundBy: 0)  // 첫 번째 메뉴버튼이 상태 필터
    }

    var sortMenu: XCUIElement {
        app.descendants(matching: .any)["sessionSortMenu"]
    }

    // MARK: - Dynamic Elements

    func sessionCard(id: String) -> XCUIElement {
        app.buttons["sessionCard-\(id)"]
    }

    var allSessionCards: XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'sessionCard-'"))
    }

    // MARK: - Actions

    func searchSessions(_ text: String) {
        searchField.click()
        searchField.typeText(text)
    }

    func clearSearch() {
        searchField.click()
        searchField.typeKey("a", modifierFlags: .command)
        searchField.typeKey(.delete, modifierFlags: [])
    }

    func selectSession(id: String) {
        sessionCard(id: id).click()
    }

    func selectStateFilter(_ state: String) {
        stateFilter.buttons[state].click()
    }

    // MARK: - Assertions

    func sessionExists(id: String, timeout: TimeInterval = 5) -> Bool {
        sessionCard(id: id).waitForExistence(timeout: timeout)
    }

    var sessionCount: Int {
        allSessionCards.count
    }
}
