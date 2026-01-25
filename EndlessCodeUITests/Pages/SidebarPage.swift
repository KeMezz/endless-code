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

    /// 사이드바 - SwiftUI List는 macOS에서 Outline으로 렌더링됨
    var sidebar: XCUIElement {
        // macOS에서 SwiftUI List(.sidebar 스타일)는 Outline으로 렌더링됨
        app.outlines["sidebar"]
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
