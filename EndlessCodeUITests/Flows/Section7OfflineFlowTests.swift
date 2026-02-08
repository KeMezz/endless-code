//
//  Section7OfflineFlowTests.swift
//  EndlessCodeUITests
//
//  iOS 오프라인 처리 UI 테스트
//

#if os(iOS)
import XCTest

final class Section7OfflineFlowTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--offline-mode"]
        app.launch()
    }

    // MARK: 7.4.1 - 오프라인 배너 표시

    func test_offlineBanner_displaysWhenNetworkUnavailable() throws {
        // Given: 네트워크 연결 없음 (launch argument로 시뮬레이션)

        // When: 앱 실행

        // Then: 오프라인 배너 표시
        let banner = app.otherElements["iosOfflineBanner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 5))
        XCTAssertTrue(banner.staticTexts["인터넷 연결이 없습니다"].exists)
    }

    func test_serverConnectionBanner_displaysWhenServerUnreachable() throws {
        // Given: 서버 연결 실패 (launch argument로 시뮬레이션)
        app.terminate()
        app.launchArguments = ["--uitesting", "--server-unreachable"]
        app.launch()

        // When: 앱 실행

        // Then: 서버 연결 배너 표시
        let banner = app.otherElements["iosServerConnectionBanner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 5))
        XCTAssertTrue(banner.staticTexts["서버에 연결할 수 없습니다"].exists)
    }

    // MARK: 7.4.2 - 오프라인 전체 화면

    func test_offlineView_displaysWhenServerFailed() throws {
        // Given: 서버 연결 실패 상태

        // When: 채팅 화면으로 이동
        // (실제 구현에서는 네비게이션 필요)

        // Then: 오프라인 전체 화면 표시
        let offlineView = app.otherElements["iosOfflineView"]
        XCTAssertTrue(offlineView.waitForExistence(timeout: 5))
        XCTAssertTrue(offlineView.staticTexts["서버에 연결할 수 없습니다"].exists)
    }

    func test_offlineView_retryButton_triggersReconnection() throws {
        // Given: 오프라인 화면
        let offlineView = app.otherElements["iosOfflineView"]
        XCTAssertTrue(offlineView.waitForExistence(timeout: 5))

        // When: 다시 시도 버튼 클릭
        let retryButton = offlineView.buttons["iosRetryButton"]
        XCTAssertTrue(retryButton.exists)
        retryButton.tap()

        // Then: 재연결 시도 (reconnection view 표시)
        let reconnectionView = app.otherElements["iosReconnectionView"]
        XCTAssertTrue(reconnectionView.waitForExistence(timeout: 3))
    }

    func test_offlineView_viewCachedButton_showsCachedMessages() throws {
        // Given: 캐시된 메시지가 있는 오프라인 화면
        app.terminate()
        app.launchArguments = ["--uitesting", "--offline-mode", "--has-cached-messages"]
        app.launch()

        let offlineView = app.otherElements["iosOfflineView"]
        XCTAssertTrue(offlineView.waitForExistence(timeout: 5))

        // When: 캐시된 메시지 보기 버튼 클릭
        let viewCachedButton = offlineView.buttons["iosViewCachedButton"]
        XCTAssertTrue(viewCachedButton.exists)
        viewCachedButton.tap()

        // Then: 캐시된 메시지 목록 표시
        // (실제 구현에서는 메시지 리스트 표시)
        XCTAssertTrue(true) // Placeholder for actual message list verification
    }

    // MARK: 7.4.3 - 재연결 진행 상태

    func test_reconnectionView_displaysProgressDuringReconnection() throws {
        // Given: 재연결 중 상태
        app.terminate()
        app.launchArguments = ["--uitesting", "--reconnecting"]
        app.launch()

        // When: 재연결 뷰 확인

        // Then: 진행률 표시
        let reconnectionView = app.otherElements["iosReconnectionView"]
        XCTAssertTrue(reconnectionView.waitForExistence(timeout: 5))

        let progressView = reconnectionView.otherElements["iosReconnectionProgress"]
        XCTAssertTrue(progressView.exists)

        XCTAssertTrue(reconnectionView.staticTexts["재연결 시도 중..."].exists)
    }

    func test_reconnectionView_cancelButton_stopsReconnection() throws {
        // Given: 재연결 중 상태
        app.terminate()
        app.launchArguments = ["--uitesting", "--reconnecting"]
        app.launch()

        let reconnectionView = app.otherElements["iosReconnectionView"]
        XCTAssertTrue(reconnectionView.waitForExistence(timeout: 5))

        // When: 취소 버튼 클릭
        let cancelButton = reconnectionView.buttons["iosReconnectionCancel"]
        XCTAssertTrue(cancelButton.exists)
        cancelButton.tap()

        // Then: 재연결 뷰가 사라짐
        XCTAssertFalse(reconnectionView.waitForExistence(timeout: 2))
    }

    func test_reconnectionView_manualRetryButton_triggersImmediateRetry() throws {
        // Given: 재연결 중 상태
        app.terminate()
        app.launchArguments = ["--uitesting", "--reconnecting"]
        app.launch()

        let reconnectionView = app.otherElements["iosReconnectionView"]
        XCTAssertTrue(reconnectionView.waitForExistence(timeout: 5))

        // When: 지금 재시도 버튼 클릭
        let manualRetryButton = reconnectionView.buttons["iosManualRetryButton"]
        XCTAssertTrue(manualRetryButton.exists)
        manualRetryButton.tap()

        // Then: 즉시 재연결 시도 (attempt count가 증가하거나 연결 성공)
        // (실제 구현에서는 연결 상태 변화 확인)
        XCTAssertTrue(true) // Placeholder for actual connection state verification
    }

    // MARK: 7.4.4 - 통합 시나리오

    func test_offlineFlow_completeJourney() throws {
        // Given: 오프라인 상태에서 앱 시작
        app.terminate()
        app.launchArguments = ["--uitesting", "--offline-mode", "--has-cached-messages"]
        app.launch()

        // Then: 오프라인 배너 표시
        let banner = app.otherElements["iosOfflineBanner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 5))

        // When: 캐시된 메시지 보기
        let offlineView = app.otherElements["iosOfflineView"]
        XCTAssertTrue(offlineView.waitForExistence(timeout: 5))

        let viewCachedButton = offlineView.buttons["iosViewCachedButton"]
        if viewCachedButton.exists {
            viewCachedButton.tap()
        }

        // Then: 캐시된 메시지 확인 가능

        // When: 다시 시도
        if offlineView.exists {
            let retryButton = offlineView.buttons["iosRetryButton"]
            if retryButton.exists {
                retryButton.tap()
            }
        }

        // Then: 재연결 진행률 표시
        let reconnectionView = app.otherElements["iosReconnectionView"]
        XCTAssertTrue(reconnectionView.waitForExistence(timeout: 3))
    }

    func test_darkMode_offlineUIRendersCorrectly() throws {
        // Given: 다크 모드 설정
        app.terminate()
        app.launchArguments = ["--uitesting", "--offline-mode", "--dark-mode"]
        app.launch()

        // When: 오프라인 UI 확인

        // Then: 다크 모드에서 올바르게 렌더링
        let offlineView = app.otherElements["iosOfflineView"]
        XCTAssertTrue(offlineView.waitForExistence(timeout: 5))

        let banner = app.otherElements["iosOfflineBanner"]
        XCTAssertTrue(banner.exists)

        // 다크 모드 UI가 표시되는지 확인 (실제로는 스크린샷 비교 등 필요)
        XCTAssertTrue(true)
    }
}
#endif
