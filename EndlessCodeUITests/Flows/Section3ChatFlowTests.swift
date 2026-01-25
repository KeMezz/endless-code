//
//  Section3ChatFlowTests.swift
//  EndlessCodeUITests
//
//  Section 3: 채팅 인터페이스 E2E 테스트
//

import XCTest

/// Section 3 채팅 인터페이스 E2E 테스트
/// Note: 세션 선택 → ChatView 표시 플로우에 accessibilityIdentifier 전파 문제가 있음
/// TODO: DetailView에서 ChatView identifier가 정상 노출되도록 디버깅 필요
final class Section3ChatFlowTests: XCTestCase {
    var app: XCUIApplication!
    var sidebarPage: SidebarPage!
    var sessionListPage: SessionListPage!
    var chatPage: ChatPage!
    var detailPage: DetailPage!

    // MARK: - Setup

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        sidebarPage = SidebarPage(app: app)
        sessionListPage = SessionListPage(app: app)
        chatPage = ChatPage(app: app)
        detailPage = DetailPage(app: app)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper Methods

    /// 세션을 선택하여 채팅 화면으로 이동
    private func navigateToChat() {
        // Sessions 탭으로 이동
        sidebarPage.selectSessionsTab()

        // 세션 목록이 표시될 때까지 대기
        guard sessionListPage.sessionList.waitForExistence(timeout: 10) else {
            XCTFail("세션 목록이 표시되지 않습니다")
            return
        }

        // 첫 번째 세션 선택
        let firstSession = sessionListPage.sessionCard(id: "session-1")
        guard firstSession.waitForExistence(timeout: 5) else {
            XCTFail("세션 카드를 찾을 수 없습니다")
            return
        }
        firstSession.click()

        // 클릭 후 짧은 대기
        _ = chatPage.chatView(sessionId: "session-1").waitForExistence(timeout: 2)
    }

    // MARK: - 3.1 메시지 표시 테스트

    /// 3.1.1 세션 선택 시 채팅 화면 표시 테스트
    func test_selectSession_showsChatView() throws {
        // Given: 앱이 실행됨
        XCTAssertTrue(sidebarPage.sidebar.waitForExistence(timeout: 10))

        // When: 세션 선택
        navigateToChat()

        // 클릭 후 스크린샷 (디버깅용)
        let debugScreenshot = app.screenshot()
        let debugAttachment = XCTAttachment(screenshot: debugScreenshot)
        debugAttachment.name = "ChatView-AfterSessionClick"
        debugAttachment.lifetime = .keepAlways
        add(debugAttachment)

        // Then: 채팅 화면이 표시되어야 함
        let chatViewVisible = chatPage.isChatViewVisible(sessionId: "session-1", timeout: 10)

        // 실패 시 추가 디버깅 정보
        if !chatViewVisible {
            print("DEBUG: chatView-session-1 not found")
            print("DEBUG: Elements with 'chatView' prefix:")
            for element in app.descendants(matching: .any).allElementsBoundByIndex {
                if element.identifier.hasPrefix("chatView") {
                    print("  - \(element.identifier)")
                }
            }
        }

        XCTAssertTrue(chatViewVisible, "채팅 화면이 표시되어야 합니다")

        // Then: 메시지 입력 뷰가 표시되어야 함
        XCTAssertTrue(chatPage.isMessageInputVisible(timeout: 5),
                      "메시지 입력 뷰가 표시되어야 합니다")

        // 스크린샷 저장
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "ChatView-Initial"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 3.1.2 메시지 목록 표시 테스트
    func test_chatView_showsMessageList() throws {
        // Given: 채팅 화면으로 이동
        navigateToChat()
        XCTAssertTrue(chatPage.isChatViewVisible(sessionId: "session-1", timeout: 10))

        // Then: 메시지 목록 또는 빈 목록이 표시되어야 함
        let hasMessages = chatPage.isMessageListVisible(timeout: 5)
        let isEmpty = chatPage.emptyMessageList.waitForExistence(timeout: 2)

        XCTAssertTrue(hasMessages || isEmpty,
                      "메시지 목록 또는 빈 목록이 표시되어야 합니다")

        // 스크린샷 저장
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "ChatView-MessageList"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - 3.3 메시지 입력 테스트

    /// 3.3.1 메시지 입력 필드 존재 테스트
    func test_chatView_hasMessageInput() throws {
        // Given: 채팅 화면으로 이동
        navigateToChat()
        XCTAssertTrue(chatPage.isChatViewVisible(sessionId: "session-1", timeout: 10))

        // Then: 메시지 입력 필드가 존재해야 함
        XCTAssertTrue(chatPage.messageInput.waitForExistence(timeout: 5),
                      "메시지 입력 필드가 존재해야 합니다")

        // Then: 전송 버튼이 존재해야 함
        XCTAssertTrue(chatPage.sendButton.waitForExistence(timeout: 3),
                      "전송 버튼이 존재해야 합니다")

        // 스크린샷 저장
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "ChatView-InputField"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 3.3.2 메시지 입력 테스트
    func test_chatView_canTypeMessage() throws {
        // Given: 채팅 화면으로 이동
        navigateToChat()
        XCTAssertTrue(chatPage.messageInput.waitForExistence(timeout: 10))

        // When: 메시지 입력
        chatPage.typeMessage("Hello, Claude!")

        // 스크린샷 저장
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "ChatView-TypeMessage"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - 3.2 코드 블록 테스트

    /// 3.2.1 코드 블록이 있는 메시지 표시 테스트
    /// Note: 샘플 메시지에 코드 블록이 포함되어 있어야 함
    func test_chatView_showsCodeBlocks() throws {
        // Given: 채팅 화면으로 이동
        navigateToChat()
        XCTAssertTrue(chatPage.isChatViewVisible(sessionId: "session-1", timeout: 10))

        // When: 메시지 목록 로드 대기
        XCTAssertTrue(chatPage.isMessageListVisible(timeout: 10))

        // 스크린샷 저장
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "ChatView-CodeBlocks"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - 3.5 헤더 및 상태 테스트

    /// 3.5.1 채팅 헤더 표시 테스트
    func test_chatView_showsHeader() throws {
        // Given: 채팅 화면으로 이동
        navigateToChat()
        XCTAssertTrue(chatPage.isChatViewVisible(sessionId: "session-1", timeout: 10))

        // Then: 헤더가 표시되어야 함
        XCTAssertTrue(chatPage.chatHeader.waitForExistence(timeout: 5),
                      "채팅 헤더가 표시되어야 합니다")

        // 스크린샷 저장
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "ChatView-Header"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - 전체 플로우 테스트

    /// 채팅 플로우 전체 테스트
    func test_fullChatFlow() throws {
        // 1. 앱 실행 확인
        XCTAssertTrue(sidebarPage.sidebar.waitForExistence(timeout: 10))

        // 2. Sessions 탭으로 이동
        sidebarPage.selectSessionsTab()
        XCTAssertTrue(sessionListPage.sessionList.waitForExistence(timeout: 10))

        // 3. 세션 선택
        let firstSession = sessionListPage.sessionCard(id: "session-1")
        if firstSession.waitForExistence(timeout: 5) {
            firstSession.click()
        }

        // 4. 채팅 화면 표시 확인
        XCTAssertTrue(chatPage.isChatViewVisible(sessionId: "session-1", timeout: 10))

        // 5. 메시지 입력 필드 확인
        XCTAssertTrue(chatPage.messageInput.waitForExistence(timeout: 5))

        // 6. 메시지 입력
        chatPage.typeMessage("Test message")

        // 최종 스크린샷
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "FullChatFlow-Complete"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
