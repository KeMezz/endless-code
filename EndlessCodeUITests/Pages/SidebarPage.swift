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

    /// 사이드바 - accessibilityIdentifier로 직접 찾음
    var sidebar: XCUIElement {
        // SwiftUI List의 렌더링 타입이 시스템에 따라 다를 수 있으므로
        // descendants로 타입에 관계없이 identifier로 찾음
        app.descendants(matching: .any)["sidebar"]
    }

    /// Projects 탭
    var projectsTab: XCUIElement {
        // SwiftUI NavigationLink의 렌더링 타입이 시스템에 따라 다를 수 있음
        // descendants로 타입에 관계없이 identifier로 찾음
        app.descendants(matching: .any)["sidebarTab-Projects"]
    }

    /// Sessions 탭
    var sessionsTab: XCUIElement {
        app.descendants(matching: .any)["sidebarTab-Sessions"]
    }

    /// Settings 탭
    var settingsTab: XCUIElement {
        app.descendants(matching: .any)["sidebarTab-Settings"]
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
