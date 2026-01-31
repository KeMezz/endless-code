# Testing Rules

엄격한 테스트 정책입니다. 모든 태스크에 테스트 필수.

## 테스트 프레임워크

**Swift Testing** 사용 (XCTest 사용 금지)

- `import Testing` 사용
- `@Suite`, `@Test` 어트리뷰트 사용
- `#expect`, `#require` 매크로로 검증
- `struct` 기반 테스트 (class 아님)

> **예외**: UI 테스트(E2E)는 XCUITest 사용 (Swift Testing 미지원)

## 필수 요구사항

### 커버리지 기준

| 메트릭 | 최소 기준 |
|--------|----------|
| Line Coverage | 80% |
| Branch Coverage | 75% |
| Function Coverage | 85% |

### 테스트 필수 조건

1. **모든 태스크에 테스트 필수**: 구현 코드 없이 테스트만 있어도 안됨, 반대도 안됨
2. **PR 전 테스트 통과 필수**: 실패하는 테스트가 있으면 PR 생성 불가
3. **TDD 권장**: 가능하면 테스트 먼저 작성
4. **코드 작성 완료 시 전체 테스트 실행 필수**: Unit 테스트와 E2E 테스트 모두 실행

### 코드 작성 완료 시 테스트 실행 (필수)

코드 작성이 완료되면 **반드시** 다음 순서로 테스트를 실행:

```bash
# 1. Unit 테스트 실행
swift test

# 2. E2E 테스트 실행
xcodebuild test \
  -scheme EndlessCodeUITestHost \
  -destination 'platform=macOS' \
  -only-testing:EndlessCodeUITests
```

**예외 상황** (E2E 테스트 생략 가능):
- 내부 구현만 변경하고 외부 동작이 동일한 리팩토링
- UI와 무관한 서버/모델 코드만 수정한 경우
- 단, 이 경우에도 기존 E2E 테스트가 통과하는지 확인 권장

### UI 변경 시 검증 (필수)

**UI 관련 코드 수정 시 반드시 `/verify-ui` 커맨드로 시각적 검증 수행.**

```bash
# UI 검증 실행 (기본: file-selected 시나리오)
/verify-ui

# 특정 시나리오 검증
/verify-ui project-list
/verify-ui file-selected
```

**UI 검증이 필요한 경우**:
- View 파일 수정 (*.swift in Views/, Components/)
- 레이아웃 관련 코드 변경 (frame, padding, alignment 등)
- 새로운 UI 컴포넌트 추가
- 스타일/테마 변경

**UI 검증 시나리오 추가 규칙**:

새로운 화면이나 주요 UI 흐름을 추가할 때, `ScreenshotCaptureTests`에 해당 시나리오 추가:

```swift
// EndlessCodeUITests/Helpers/ScreenshotCapture.swift

/// 새 시나리오 스크린샷 캡처
func test_capture_newScenario() throws {
    // 1. 원하는 화면으로 네비게이션
    // 2. saveScreenshot(named: "scenarioName") 호출
}
```

그리고 `verify-ui.md`의 시나리오 매핑 테이블에 추가.

## Unit Test 규칙

### 파일 구조

```
EndlessCodeTests/
├── Server/
│   ├── CLIProcessManagerTests.swift
│   ├── JSONLParserTests.swift
│   ├── SessionManagerTests.swift
│   └── WebSocketHandlerTests.swift
├── Shared/
│   ├── Models/
│   │   └── MessageTests.swift
│   └── ViewModels/
│       └── ChatViewModelTests.swift
└── Mocks/
    ├── MockCLIProcess.swift
    └── MockWebSocketClient.swift
```

### 네이밍 컨벤션

```swift
import Testing
@testable import EndlessCode

// 테스트 Suite: @Suite("{테스트대상} Tests")
@Suite("JSONLParser Tests")
struct JSONLParserTests {
    let parser = JSONLParser()

    // 테스트 메서드: @Test("{설명}")
    @Test("Parse valid JSONL returns messages")
    func parseValidJSONLReturnsMessages() async throws {
        // ...
    }

    @Test("Parse invalid JSON throws error")
    func parseInvalidJSONThrowsError() async throws {
        // ...
    }

    @Test("Parse empty input returns empty array")
    func parseEmptyInputReturnsEmptyArray() async throws {
        // ...
    }
}
```

### 테스트 구조 (Given-When-Then)

```swift
@Test("Send message updates conversation history")
func sendMessageUpdatesConversationHistory() async throws {
    // Given: 초기 상태 설정
    let sut = ChatViewModel()
    let message = "Hello, Claude"

    // When: 테스트 대상 동작 실행
    await sut.sendMessage(message)

    // Then: 결과 검증
    #expect(sut.messages.count == 1)
    #expect(sut.messages.first?.content == message)
}
```

### 에러 검증

```swift
@Test("Parse empty line throws emptyLine error")
func parseEmptyLineThrowsEmptyLineError() {
    #expect(throws: JSONLParserError.emptyLine) {
        try parser.parse(line: "")
    }
}

@Test("Parse invalid JSON throws invalidJSON error")
func parseInvalidJSONThrowsInvalidJSONError() async {
    await #expect {
        try await parser.parse(line: "not json")
    } throws: { error in
        guard let parserError = error as? JSONLParserError,
              case .invalidJSON = parserError else {
            return false
        }
        return true
    }
}
```

### Mock 사용 규칙

```swift
// Protocol 기반 의존성 주입
protocol CLIProcessProtocol: Sendable {
    func start() async throws
    func send(_ input: String) async throws
    var outputStream: AsyncStream<String> { get }
}

// Production 구현
actor CLIProcess: CLIProcessProtocol {
    // 실제 구현
}

// Test Mock
final class MockCLIProcess: CLIProcessProtocol, @unchecked Sendable {
    var startCalled = false
    var sentInputs: [String] = []
    private let continuation: AsyncStream<String>.Continuation
    let outputStream: AsyncStream<String>

    init() {
        (outputStream, continuation) = AsyncStream.makeStream()
    }

    func start() async throws {
        startCalled = true
    }

    func send(_ input: String) async throws {
        sentInputs.append(input)
    }

    func emit(_ output: String) {
        continuation.yield(output)
    }
}
```

### Async 테스트

```swift
@Test("Stream messages receives all messages")
func streamMessagesReceivesAllMessages() async throws {
    // Given
    let mockProcess = MockCLIProcess()
    let parser = JSONLParser(process: mockProcess)

    // When
    let task = Task {
        var messages: [Message] = []
        for await message in parser.messages {
            messages.append(message)
            if messages.count == 3 { break }
        }
        return messages
    }

    mockProcess.emit(#"{"type":"message","content":"Hello"}"#)
    mockProcess.emit(#"{"type":"message","content":"World"}"#)
    mockProcess.emit(#"{"type":"message","content":"!"}"#)

    // Then
    let messages = await task.value
    #expect(messages.count == 3)
}
```

## E2E Test (UI Test) 규칙

> **주의**: UI 테스트는 XCUITest 사용 (Swift Testing 미지원)
>
> **중요**: Xcode 26.x SPM 빌드 버그로 인해 `EndlessCodeUITestHost` 스킴 사용 필수

### 파일 구조

```
EndlessCodeUITests/
├── Flows/
│   ├── ChatFlowTests.swift
│   ├── SessionFlowTests.swift
│   └── FileExplorerFlowTests.swift
├── Pages/
│   ├── ChatPage.swift
│   ├── SessionListPage.swift
│   └── SettingsPage.swift
└── Helpers/
    └── XCUIElementExtensions.swift
```

### Page Object 패턴

```swift
// Page Object
struct ChatPage {
    let app: XCUIApplication

    var messageInput: XCUIElement {
        app.textFields["messageInput"]
    }

    var sendButton: XCUIElement {
        app.buttons["sendButton"]
    }

    var messageList: XCUIElement {
        app.scrollViews["messageList"]
    }

    func sendMessage(_ text: String) {
        messageInput.tap()
        messageInput.typeText(text)
        sendButton.tap()
    }

    func waitForResponse(timeout: TimeInterval = 10) -> Bool {
        let predicate = NSPredicate(format: "count > 1")
        let expectation = XCTNSPredicateExpectation(
            predicate: predicate,
            object: messageList.staticTexts
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
```

### E2E 테스트 작성 (XCTest)

```swift
import XCTest

final class ChatFlowTests: XCTestCase {
    var app: XCUIApplication!
    var chatPage: ChatPage!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        chatPage = ChatPage(app: app)
    }

    func test_sendMessage_receivesResponse() throws {
        // Given: 채팅 화면

        // When: 메시지 전송
        chatPage.sendMessage("Hello, Claude")

        // Then: 응답 수신
        XCTAssertTrue(chatPage.waitForResponse())
    }
}
```

### Accessibility Identifier 규칙

SwiftUI 뷰에 반드시 `accessibilityIdentifier` 설정:

```swift
struct ChatView: View {
    var body: some View {
        VStack {
            ScrollView {
                // ...
            }
            .accessibilityIdentifier("messageList")

            HStack {
                TextField("메시지 입력", text: $input)
                    .accessibilityIdentifier("messageInput")

                Button("전송") {
                    // ...
                }
                .accessibilityIdentifier("sendButton")
            }
        }
    }
}
```

## 테스트 실행 명령어

### Unit Test (Swift Package Manager 사용 - 필수)

> **⚠️ 중요**: Xcode 26.x의 SPM 빌드 버그로 인해 Unit 테스트는 반드시 `swift test` 사용
>
> `xcodebuild test`는 Vapor 의존성(swift-crypto)의 PackageProduct framework 생성 실패 문제 발생

```bash
# 전체 테스트 (권장)
swift test

# 특정 테스트 Suite
swift test --filter JSONLParserTests

# 특정 테스트 메서드
swift test --filter "JSONLParserTests/parseValidJSONLReturnsMessages"

# 병렬 테스트 비활성화 (디버깅 시)
swift test --parallel=false

# 빌드만 (테스트 실행 없이)
swift build --build-tests

# verbose 출력
swift test -v
```

### UI Test (XCUITest - Xcode 필요)

> UI 테스트는 `xcodebuild` 사용 (Swift Testing이 XCUITest 미지원)
>
> **중요**: `EndlessCodeUITestHost` 스킴 사용 (Xcode 26.x SPM 빌드 버그 우회)

```bash
# macOS UI 테스트 (EndlessCodeUITestHost 스킴 필수)
xcodebuild test \
  -scheme EndlessCodeUITestHost \
  -destination 'platform=macOS' \
  -only-testing:EndlessCodeUITests

# 특정 테스트만 실행
xcodebuild test \
  -scheme EndlessCodeUITestHost \
  -destination 'platform=macOS' \
  -only-testing:EndlessCodeUITests/Section2NavigationFlowTests
```

### 커버리지 리포트

> 커버리지는 `swift test`에서 직접 지원하지 않으므로 별도 도구 사용

```bash
# swift-cov 사용 (설치 필요: brew install swift-cov)
swift test --enable-code-coverage
xcrun llvm-cov report .build/debug/EndlessCodePackageTests.xctest/Contents/MacOS/EndlessCodePackageTests \
  -instr-profile=.build/debug/codecov/default.profdata

# 또는 Xcode에서 UI 테스트와 함께 커버리지 확인
xcodebuild test \
  -scheme EndlessCodeUITestHost \
  -destination 'platform=macOS' \
  -only-testing:EndlessCodeUITests \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult

xcrun xccov view --report TestResults.xcresult
```

## 테스트 체크리스트

### 코드 작성 완료 시 (매번 실행)

- [ ] **`swift test`로 모든 Unit 테스트 통과**
- [ ] **E2E 테스트 통과** (`xcodebuild test -scheme EndlessCodeUITestHost ...`)

### PR 생성 전 (최종 확인)

- [ ] 모든 Unit 테스트 통과 (`swift test`)
- [ ] 모든 E2E 테스트 통과 (`EndlessCodeUITestHost` 스킴 + xcodebuild 사용)
- [ ] Line Coverage 80% 이상
- [ ] 신규 코드에 대한 테스트 작성됨
- [ ] Mock 객체 적절히 사용됨
- [ ] Async 코드 테스트 시 Task 적절히 처리됨
- [ ] Accessibility Identifier 설정됨 (UI 컴포넌트)

## 테스트 제외 항목

다음 항목은 테스트 커버리지에서 제외 가능:

- `@main` 앱 엔트리 포인트
- SwiftUI Preview 코드
- 단순 데이터 모델 (computed property 없는 struct)
- 외부 라이브러리 래퍼 (Tree-sitter 바인딩 등)
