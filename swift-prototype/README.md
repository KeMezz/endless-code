# Claude Code Wrapper - Swift Prototype

Claude Code CLI를 Swift에서 제어하는 프로토타입입니다.

## 요구사항

- Swift 6.2+
- macOS 26.0 (Tahoe) / iOS 26.0
- Claude Code CLI 설치

## 빌드

```bash
cd swift-prototype
swift build
```

## 실행

### 대화형 모드

```bash
./.build/debug/cc-wrapper
```

### 테스트 모드

```bash
# 기본 테스트 (메시지 송수신)
./.build/debug/cc-wrapper --test

# AskUserQuestion 테스트
./.build/debug/cc-wrapper --test-ask
```

## 구조

```
swift-prototype/
├── Package.swift
└── Sources/
    ├── ClaudeCodeKit/          # 라이브러리
    │   ├── Models.swift        # JSONL 메시지 모델 (Sendable)
    │   └── ClaudeCodeManager.swift  # CLI 프로세스 관리 (@MainActor)
    └── ClaudeCodeWrapper/      # CLI 실행 파일
        ├── ClaudeCodeWrapper.swift  # 메인 (대화형)
        └── TestRunner.swift    # 비대화형 테스트
```

## 검증된 기능

| 기능 | 상태 |
|------|------|
| CLI 프로세스 spawn | ✅ |
| stdin/stdout JSONL 통신 | ✅ |
| system init 파싱 | ✅ |
| assistant 메시지 파싱 | ✅ |
| result 메시지 파싱 | ✅ |
| AskUserQuestion 감지 | ✅ |
| AskUserQuestion 응답 | ✅ |
| Swift 6 Strict Concurrency | ✅ |

## 사용 예시

```swift
import ClaudeCodeKit

@MainActor
func example() async {
    let manager = ClaudeCodeManager()

    manager.onEvent = { event in
        switch event {
        case .systemInit(let msg):
            print("Connected: \(msg.claudeCodeVersion)")

        case .textOutput(let text):
            print("Claude: \(text)")

        case .askUserQuestion(let toolId, let input):
            // UI에서 질문 표시 후 응답
            try? manager.sendAskUserQuestionResponse(answers: ["q0": "선택값"])

        case .result(let msg):
            print("Cost: $\(msg.totalCostUsd ?? 0)")

        default: break
        }
    }

    try? manager.start()
    try? manager.sendMessage("Hello!")
}
```

## Swift 6 Concurrency

- `ClaudeCodeManager`는 `@MainActor`로 격리됨
- 모든 모델 타입은 `Sendable` 준수
- `AnyCodable`은 `@unchecked Sendable` (동적 타입 처리)

## 다음 단계

1. **SwiftUI 앱** - macOS용 GUI 구현
2. **세션 관리** - 세션 재개/히스토리
3. **Vapor 서버** - iOS 원격 접속용
