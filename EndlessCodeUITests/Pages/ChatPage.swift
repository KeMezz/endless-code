//
//  ChatPage.swift
//  EndlessCodeUITests
//
//  채팅 화면 Page Object
//

import XCTest

/// 채팅 화면 Page Object
struct ChatPage {
    let app: XCUIApplication

    // MARK: - Elements

    /// 채팅 뷰 (특정 세션)
    func chatView(sessionId: String) -> XCUIElement {
        app.descendants(matching: .any)["chatView-\(sessionId)"]
    }

    /// 채팅 헤더
    var chatHeader: XCUIElement {
        app.descendants(matching: .any)["chatHeader"]
    }

    /// 메시지 목록
    var messageList: XCUIElement {
        app.descendants(matching: .any)["messageList"]
    }

    /// 빈 메시지 목록
    var emptyMessageList: XCUIElement {
        app.descendants(matching: .any)["emptyMessageList"]
    }

    /// 메시지 입력 뷰
    var messageInputView: XCUIElement {
        app.descendants(matching: .any)["messageInputView"]
    }

    /// 메시지 입력 필드
    var messageInput: XCUIElement {
        app.descendants(matching: .any)["messageInput"]
    }

    /// 전송 버튼
    var sendButton: XCUIElement {
        app.descendants(matching: .any)["sendButton"]
    }

    /// 첨부 버튼
    var attachmentButton: XCUIElement {
        app.descendants(matching: .any)["attachmentButton"]
    }

    /// 로딩 뷰
    var loadingView: XCUIElement {
        app.descendants(matching: .any)["chatLoadingView"]
    }

    /// 스트리밍 인디케이터
    var streamingIndicator: XCUIElement {
        app.descendants(matching: .any)["streamingIndicator"]
    }

    /// 특정 메시지 버블
    func messageBubble(id: String) -> XCUIElement {
        app.descendants(matching: .any)["messageBubble-\(id)"]
    }

    /// 코드 블록
    var codeBlocks: XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: "codeBlock")
    }

    /// 복사 버튼 (코드 블록 내)
    var copyCodeButton: XCUIElement {
        app.descendants(matching: .any)["copyCodeButton"]
    }

    /// 타이핑 인디케이터
    var typingIndicator: XCUIElement {
        app.descendants(matching: .any)["typingIndicator"]
    }

    /// 날짜 구분선
    var dateSeparators: XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: "dateSeparator")
    }

    // MARK: - Tool Views

    /// 도구 사용 뷰 (특정 ID)
    func toolUseView(toolUseId: String) -> XCUIElement {
        app.descendants(matching: .any)["toolUseView-\(toolUseId)"]
    }

    /// 도구 결과 뷰 (특정 ID)
    func toolResultView(toolUseId: String) -> XCUIElement {
        app.descendants(matching: .any)["toolResultView-\(toolUseId)"]
    }

    // MARK: - Actions

    /// 메시지 입력
    func typeMessage(_ text: String) {
        guard messageInput.waitForExistence(timeout: 5) else { return }
        messageInput.click()
        messageInput.typeText(text)
    }

    /// 메시지 전송
    func sendMessage() {
        guard sendButton.waitForExistence(timeout: 3) else { return }
        sendButton.click()
    }

    /// 메시지 입력 및 전송
    func sendMessage(_ text: String) {
        typeMessage(text)
        sendMessage()
    }

    /// 코드 복사 버튼 클릭
    func copyCode() {
        guard copyCodeButton.waitForExistence(timeout: 3) else { return }
        copyCodeButton.click()
    }

    // MARK: - Assertions

    /// 채팅 뷰가 표시되는지 확인
    func isChatViewVisible(sessionId: String, timeout: TimeInterval = 5) -> Bool {
        chatView(sessionId: sessionId).waitForExistence(timeout: timeout)
    }

    /// 메시지 목록이 표시되는지 확인
    func isMessageListVisible(timeout: TimeInterval = 5) -> Bool {
        messageList.waitForExistence(timeout: timeout)
    }

    /// 메시지 입력 뷰가 표시되는지 확인
    func isMessageInputVisible(timeout: TimeInterval = 5) -> Bool {
        messageInputView.waitForExistence(timeout: timeout)
    }

    /// 로딩 중인지 확인
    func isLoading(timeout: TimeInterval = 3) -> Bool {
        loadingView.waitForExistence(timeout: timeout)
    }

    /// 스트리밍 중인지 확인
    func isStreaming(timeout: TimeInterval = 3) -> Bool {
        streamingIndicator.waitForExistence(timeout: timeout)
    }

    /// 코드 블록 개수
    var codeBlockCount: Int {
        codeBlocks.count
    }
}
