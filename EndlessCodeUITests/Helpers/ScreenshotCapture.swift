//
//  ScreenshotCapture.swift
//  EndlessCodeUITests
//
//  UI 검증용 스크린샷 캡처 헬퍼
//

import XCTest

/// UI 검증용 스크린샷 캡처 테스트
/// verify-ui 커맨드에서 호출하여 특정 화면의 스크린샷을 자동으로 캡처
final class ScreenshotCaptureTests: XCTestCase {
    var app: XCUIApplication!
    var sidebarPage: SidebarPage!
    var fileExplorerPage: FileExplorerPage!

    /// 스크린샷 저장 경로
    private let screenshotDir = "/tmp/verify-ui-screenshots"

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        sidebarPage = SidebarPage(app: app)
        fileExplorerPage = FileExplorerPage(app: app)

        // 스크린샷 디렉토리 생성
        try? FileManager.default.createDirectory(
            atPath: screenshotDir,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        // 스크린샷 검증을 위해 앱을 종료하지 않음
        // 사용자가 직접 확인 후 종료하거나 다음 테스트에서 종료됨
        // app.terminate()
        app = nil
    }

    // MARK: - Screenshot Capture Methods

    /// 스크린샷을 파일로 저장
    private func saveScreenshot(named name: String) -> String {
        let screenshot = XCUIScreen.main.screenshot()
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let filename = "\(name)_\(timestamp).png"
        let filepath = "\(screenshotDir)/\(filename)"

        // 스크린샷을 파일로 저장
        let imageData = screenshot.pngRepresentation
        FileManager.default.createFile(atPath: filepath, contents: imageData)

        print("SCREENSHOT_PATH: \(filepath)")
        return filepath
    }

    /// 프로젝트 선택 후 파일 탐색기로 이동
    private func navigateToFileExplorer() -> Bool {
        sidebarPage.selectProjectsTab()
        sleep(1)

        let projectCards = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'projectCard-'")
        )

        guard projectCards.count > 0 else {
            print("ERROR: 프로젝트가 없습니다")
            return false
        }

        projectCards.firstMatch.click()
        sleep(2)

        return fileExplorerPage.fileTreePanel.waitForExistence(timeout: 5)
    }

    /// 파일 선택
    private func selectFirstFile() -> Bool {
        // 파일 트리가 로드될 때까지 대기
        guard fileExplorerPage.isFileTreeLoaded(timeout: 5) else {
            return false
        }

        // 파일 찾기 (확장자가 있는 것)
        let fileItems = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'fileTreeItem-' AND identifier CONTAINS '.'")
        )

        guard fileItems.count > 0 else {
            return false
        }

        fileItems.firstMatch.click()
        sleep(1)

        return fileExplorerPage.fileContentView.waitForExistence(timeout: 3)
    }

    // MARK: - Capture Tests

    /// 파일 탐색기 - 파일 선택 상태 스크린샷
    func test_capture_fileExplorer_withFileSelected() throws {
        // 파일 탐색기로 이동
        guard navigateToFileExplorer() else {
            _ = saveScreenshot(named: "fileExplorer_error")
            throw XCTSkip("파일 탐색기로 이동 실패")
        }

        // 파일 선택
        guard selectFirstFile() else {
            _ = saveScreenshot(named: "fileExplorer_noFileSelected")
            throw XCTSkip("파일 선택 실패")
        }

        // 스크린샷 저장
        let path = saveScreenshot(named: "fileExplorer_fileSelected")
        print("SUCCESS: \(path)")
    }

    /// 파일 탐색기 - 빈 상태 스크린샷
    func test_capture_fileExplorer_emptyState() throws {
        // 파일 탐색기로 이동
        guard navigateToFileExplorer() else {
            _ = saveScreenshot(named: "fileExplorer_error")
            throw XCTSkip("파일 탐색기로 이동 실패")
        }

        // 파일 선택하지 않은 상태로 스크린샷
        let path = saveScreenshot(named: "fileExplorer_emptyState")
        print("SUCCESS: \(path)")
    }

    /// 프로젝트 목록 스크린샷
    func test_capture_projectList() throws {
        sidebarPage.selectProjectsTab()
        sleep(1)

        let path = saveScreenshot(named: "projectList")
        print("SUCCESS: \(path)")
    }

    /// 세션 목록 스크린샷
    func test_capture_sessionList() throws {
        sidebarPage.selectSessionsTab()
        sleep(1)

        let path = saveScreenshot(named: "sessionList")
        print("SUCCESS: \(path)")
    }

    /// 채팅 화면 스크린샷 (세션이 있는 경우)
    func test_capture_chatView() throws {
        sidebarPage.selectSessionsTab()
        sleep(1)

        // 첫 번째 세션 선택
        let sessionCards = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'sessionCard-'")
        )

        guard sessionCards.count > 0 else {
            _ = saveScreenshot(named: "sessionList_empty")
            throw XCTSkip("세션이 없습니다")
        }

        sessionCards.firstMatch.click()
        sleep(1)

        let path = saveScreenshot(named: "chatView")
        print("SUCCESS: \(path)")
    }

    /// 파일 탐색기 - 검색 결과 스크린샷
    func test_capture_fileExplorer_searchResults() throws {
        guard navigateToFileExplorer() else {
            _ = saveScreenshot(named: "fileExplorer_error")
            throw XCTSkip("파일 탐색기로 이동 실패")
        }

        // 검색어 입력
        fileExplorerPage.search("swift")
        sleep(2)

        let path = saveScreenshot(named: "fileExplorer_searchResults")
        print("SUCCESS: \(path)")
    }

    /// 특정 파일 선택 스크린샷 (파일 이름으로)
    func test_capture_fileExplorer_specificFile() throws {
        // 환경 변수에서 파일 이름 읽기
        let targetFile = ProcessInfo.processInfo.environment["VERIFY_UI_TARGET_FILE"] ?? ""

        guard navigateToFileExplorer() else {
            _ = saveScreenshot(named: "fileExplorer_error")
            throw XCTSkip("파일 탐색기로 이동 실패")
        }

        if !targetFile.isEmpty {
            // 특정 파일 검색 및 선택
            fileExplorerPage.search(targetFile)
            sleep(1)

            let searchResult = app.descendants(matching: .any).matching(
                NSPredicate(format: "identifier CONTAINS %@", targetFile)
            ).firstMatch

            if searchResult.waitForExistence(timeout: 2) {
                searchResult.click()
                sleep(1)
            }
        } else {
            // 기본: 첫 번째 파일 선택
            _ = selectFirstFile()
        }

        let path = saveScreenshot(named: "fileExplorer_\(targetFile.isEmpty ? "default" : targetFile)")
        print("SUCCESS: \(path)")
    }
}
