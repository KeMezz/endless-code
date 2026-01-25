//
//  SidebarPage.swift
//  EndlessCodeUITests
//
//  사이드바 Page Object
//

import XCTest

/// 사이드바 Page Object
struct SidebarPage {
    let app: XCUIApplication

    // MARK: - Elements

    /// 사이드바 - List는 다양한 타입으로 렌더링될 수 있음
    var sidebar: XCUIElement {
        // identifier로 직접 검색
        let element = app.descendants(matching: .any)["sidebar"]
        return element
    }

    /// Projects 탭
    var projectsTab: XCUIElement {
        // NavigationLink는 button으로 렌더링됨
        // AppTab.rawValue가 "Projects" (대문자)
        app.buttons["sidebarTab-Projects"]
    }

    /// Sessions 탭
    var sessionsTab: XCUIElement {
        app.buttons["sidebarTab-Sessions"]
    }

    /// Settings 탭
    var settingsTab: XCUIElement {
        app.buttons["sidebarTab-Settings"]
    }

    /// 연결 상태 인디케이터
    var connectionStatus: XCUIElement {
        app.descendants(matching: .any)["connectionStatus"]
    }

    // MARK: - Actions

    func selectProjectsTab() {
        if projectsTab.waitForExistence(timeout: 3) {
            projectsTab.click()
        }
    }

    func selectSessionsTab() {
        if sessionsTab.waitForExistence(timeout: 3) {
            sessionsTab.click()
        }
    }

    func selectSettingsTab() {
        if settingsTab.waitForExistence(timeout: 3) {
            settingsTab.click()
        }
    }

    // MARK: - Assertions

    func assertProjectsTabSelected() -> Bool {
        projectsTab.isSelected
    }

    func assertSessionsTabSelected() -> Bool {
        sessionsTab.isSelected
    }

    func assertSettingsTabSelected() -> Bool {
        settingsTab.isSelected
    }
}
