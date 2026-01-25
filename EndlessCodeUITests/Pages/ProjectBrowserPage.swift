//
//  ProjectBrowserPage.swift
//  EndlessCodeUITests
//
//  프로젝트 브라우저 Page Object
//

import XCTest

/// 프로젝트 브라우저 Page Object
struct ProjectBrowserPage {
    let app: XCUIApplication

    // MARK: - Elements

    /// 프로젝트 목록 - 첫 번째 프로젝트 카드가 존재하는지로 확인
    /// (SwiftUI ScrollView의 accessibilityIdentifier가 상위 Group의 identifier에 의해 override됨)
    var projectList: XCUIElement {
        // projectCard가 하나라도 존재하면 목록이 로드된 것
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'projectCard-'")).firstMatch
    }

    var searchField: XCUIElement {
        app.textFields["projectSearchField"]
    }

    var sortMenu: XCUIElement {
        app.descendants(matching: .any)["projectSortMenu"]
    }

    // MARK: - Dynamic Elements

    func projectCard(id: String) -> XCUIElement {
        app.buttons["projectCard-\(id)"]
    }

    var allProjectCards: XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'projectCard-'"))
    }

    // MARK: - Actions

    func searchProjects(_ text: String) {
        searchField.click()
        searchField.typeText(text)
    }

    func clearSearch() {
        searchField.click()
        searchField.typeKey("a", modifierFlags: .command)
        searchField.typeKey(.delete, modifierFlags: [])
    }

    func selectProject(id: String) {
        projectCard(id: id).click()
    }

    func selectSortOption(_ option: String) {
        sortMenu.click()
        app.menuItems[option].click()
    }

    // MARK: - Assertions

    func projectExists(id: String, timeout: TimeInterval = 5) -> Bool {
        projectCard(id: id).waitForExistence(timeout: timeout)
    }

    var projectCount: Int {
        allProjectCards.count
    }
}
