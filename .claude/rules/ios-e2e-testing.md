# iOS E2E 테스트 실행 가이드

Section 7 iOS E2E 테스트는 다음 파일들에 구현되어 있습니다:

- `EndlessCodeUITests/Flows/Section7ServerConnectionFlowTests.swift` (7.5.1)
- `EndlessCodeUITests/Flows/Section7MobileChatFlowTests.swift` (7.5.2)
- `EndlessCodeUITests/Flows/Section7OfflineFlowTests.swift` (7.5.3)

## 현재 상태

iOS E2E 테스트는 `#if os(iOS)` 가드로 작성되었으나, EndlessCodeUITestHost 타겟에 macOS 전용 코드(`QRCodeGenerator.swift` 등)가 포함되어 있어 iOS 시뮬레이터에서 빌드가 실패합니다.

## 해결 방법 (TODO)

### 옵션 1: Xcode 프로젝트 설정 수정 (권장)

EndlessCodeUITestHost의 membershipExceptions에 macOS 전용 파일 추가:

```
Shared/Utilities/QRCodeGenerator.swift
macOS/ViewModels/SettingsViewModel.swift
macOS/ViewModels/MenuBarViewModel.swift
```

### 옵션 2: 조건부 컴파일 개선

`QRCodeGenerator.swift`를 iOS/macOS 모두 지원하도록 수정:

```swift
#if os(macOS)
import AppKit
typealias PlatformImage = NSImage
#elseif os(iOS)
import UIKit
typealias PlatformImage = UIImage
#endif
```

## 임시 실행 방법 (macOS)

현재는 macOS에서만 실행 가능하지만, `#if os(iOS)` 가드 때문에 0개의 테스트가 실행됩니다:

```bash
xcodebuild test \
  -scheme EndlessCodeUITestHost \
  -destination 'platform=macOS' \
  -only-testing:EndlessCodeUITests/Section7ServerConnectionFlowTests
```

## 정상 실행 명령 (iOS - 수정 후)

프로젝트 설정 수정 후 다음 명령으로 실행:

```bash
# 7.5.1: 서버 연결 테스트
xcodebuild test \
  -scheme EndlessCodeUITestHost \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:EndlessCodeUITests/Section7ServerConnectionFlowTests

# 7.5.2: 모바일 채팅 플로우 테스트
xcodebuild test \
  -scheme EndlessCodeUITestHost \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:EndlessCodeUITests/Section7MobileChatFlowTests

# 7.5.3: 오프라인 처리 테스트
xcodebuild test \
  -scheme EndlessCodeUITestHost \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:EndlessCodeUITests/Section7OfflineFlowTests
```

## 수동 검증 방법 (현재 권장)

1. Xcode에서 iOS 시뮬레이터로 앱 실행
2. 각 테스트 시나리오를 수동으로 확인:
   - 서버 설정 화면 UI 확인
   - 서버 주소 입력 및 연결 테스트
   - 탭 네비게이션 확인
   - 채팅 메시지 입력 및 전송
   - 파일 뷰어 확인
   - 오프라인 상태 UI 확인
