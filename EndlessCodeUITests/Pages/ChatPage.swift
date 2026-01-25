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
    // Note: SwiftUI의 accessibilityIdentifier는 XCUITest에서 항상 예상대로 노출되지 않을 수 있음
    // 따라서 staticTexts, buttons 등 실제 내용을 기반으로 요소를 찾음

    /// 채팅 뷰 확인 - 헤더의 "Session" 텍스트로 확인
    func chatView(sessionId: String) -> XCUIElement {
        // ChatView 헤더의 "Session" 텍스트로 확인
        app.staticTexts["Session"]
    }

    /// 채팅 헤더 - "Session" 텍스트로 확인
    var chatHeader: XCUIElement {
        app.staticTexts["Session"]
    }

    /// 메시지 목록 - identifier로 검색 (ScrollView 또는 Group)
    var messageList: XCUIElement {
        app.descendants(matching: .any)["messageList"]
    }

    /// 빈 메시지 목록 - "Start a conversation" 텍스트로 확인
    var emptyMessageList: XCUIElement {
        app.staticTexts["Start a conversation"]
    }

    /// 메시지 입력 뷰 - placeholder 텍스트로 확인
    var messageInputView: XCUIElement {
        app.staticTexts["Ask Claude to write code..."]
    }

    /// 메시지 입력 필드 - TextEditor
    /// Note: accessibilityIdentifier "messageTextEditor"를 사용
    var messageInput: XCUIElement {
        // TextEditor는 textViews로 탐색, 명시적 identifier 우선
        let textEditor = app.textViews["messageTextEditor"]
        if textEditor.exists {
            return textEditor
        }
        return app.textViews.firstMatch
    }

    /// 전송 버튼 - image로 찾기 (arrow.up 아이콘)
    var sendButton: XCUIElement {
        // Button 내부의 이미지나 identifier로 찾기
        app.descendants(matching: .any)["sendButton"]
    }

    /// 첨부 버튼
    var attachmentButton: XCUIElement {
        app.descendants(matching: .any)["attachmentButton"]
    }

    /// 로딩 뷰 - "Loading messages..." 텍스트로 확인
    var loadingView: XCUIElement {
        app.staticTexts["Loading messages..."]
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
    /// Note: SwiftUI TextEditor는 XCUITest에서 직접 타이핑이 어려울 수 있음
    /// 클릭 후 짧은 대기가 필요할 수 있음
    func typeMessage(_ text: String) {
        guard messageInput.waitForExistence(timeout: 5) else { return }

        // TextEditor에 포커스 시도 - 여러 번 클릭
        for _ in 0..<3 {
            messageInput.click()
            usleep(100_000) // 0.1초 대기
        }

        // 타이핑 가능 상태 대기
        usleep(300_000) // 0.3초 대기

        // 타이핑 시도
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
