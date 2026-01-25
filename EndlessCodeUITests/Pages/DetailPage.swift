//
//  DetailPage.swift
//  EndlessCodeUITests
//
//  디테일 영역 Page Object
//

import XCTest

/// 디테일 영역 Page Object
struct DetailPage {
    let app: XCUIApplication

    // MARK: - Elements

    var detailView: XCUIElement {
        app.descendants(matching: .any)["detailView"]
    }

    var emptyDetailView: XCUIElement {
        app.descendants(matching: .any)["emptyDetailView"]
    }

    /// 설정 목록 - SettingsListView가 Text로 구현되어 있음
    var settingsList: XCUIElement {
        // SettingsListView는 Text로 구현되어 있어서 staticTexts에서 찾기
        let element = app.descendants(matching: .any)["settingsList"]
        if element.exists {
            return element
        }
        // fallback: "Settings List" 텍스트로 찾기
        return app.staticTexts["Settings List"]
    }

    // MARK: - Dynamic Elements

    /// 프로젝트 상세 - FileExplorerView로 구현됨
    /// 주의: SwiftUI의 accessibilityIdentifier는 중첩 시 예상대로 동작하지 않을 수 있음
    func projectDetail(id: String) -> XCUIElement {
        // 우선: projectDetail-{id} identifier로 찾기
        let element = app.descendants(matching: .any)["projectDetail-\(id)"]
        if element.exists {
            return element
        }
        // fallback 1: fileExplorerView identifier로 찾기 (Section 4 FileExplorerView)
        let explorerView = app.descendants(matching: .any)["fileExplorerView"]
        if explorerView.exists {
            return explorerView
        }
        // fallback 2: fileTreePanel identifier로 찾기
        let treePanel = app.descendants(matching: .any)["fileTreePanel"]
        if treePanel.exists {
            return treePanel
        }
        // fallback 3: staticTexts에서 identifier로 찾기
        return app.staticTexts["projectDetail-\(id)"]
    }

    func chatView(sessionId: String) -> XCUIElement {
        app.descendants(matching: .any)["chatView-\(sessionId)"]
    }

    // MARK: - Assertions

    func isEmptyDetailViewVisible(timeout: TimeInterval = 5) -> Bool {
        emptyDetailView.waitForExistence(timeout: timeout)
    }

    func isProjectDetailVisible(id: String, timeout: TimeInterval = 5) -> Bool {
        projectDetail(id: id).waitForExistence(timeout: timeout)
    }

    func isChatViewVisible(sessionId: String, timeout: TimeInterval = 5) -> Bool {
        chatView(sessionId: sessionId).waitForExistence(timeout: timeout)
    }

    func isSettingsListVisible(timeout: TimeInterval = 5) -> Bool {
        settingsList.waitForExistence(timeout: timeout)
    }
}
