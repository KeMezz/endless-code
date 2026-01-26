# UI 검증 Command

UI 변경 후 E2E 테스트를 통해 자동으로 화면을 조작하고 스크린샷을 찍어 검증합니다.

## 인자

- `$ARGUMENTS`: 검증할 시나리오 (선택)

**지원 시나리오**:
| 시나리오 | 설명 |
|---------|------|
| `file-selected` | 파일 탐색기에서 파일 선택 상태 (기본값) |
| `file-empty` | 파일 탐색기 빈 상태 |
| `project-list` | 프로젝트 목록 |
| `session-list` | 세션 목록 |
| `chat` | 채팅 화면 |
| `search` | 파일 검색 결과 |

예시:
- `/verify-ui` (기본: file-selected)
- `/verify-ui file-selected`
- `/verify-ui project-list`

---

## 워크플로우

### 1. 시나리오 매핑

`$ARGUMENTS`를 테스트 메서드에 매핑:

| 인자 | 테스트 메서드 |
|------|-------------|
| `file-selected` (기본) | `test_capture_fileExplorer_withFileSelected` |
| `file-empty` | `test_capture_fileExplorer_emptyState` |
| `project-list` | `test_capture_projectList` |
| `session-list` | `test_capture_sessionList` |
| `chat` | `test_capture_chatView` |
| `search` | `test_capture_fileExplorer_searchResults` |

### 2. E2E 테스트 실행 (화면 자동 조작)

```bash
# 시나리오에 맞는 테스트 실행
# 테스트가 앱을 실행하고 원하는 화면으로 자동 네비게이션
TEST_METHOD="test_capture_fileExplorer_withFileSelected"  # $ARGUMENTS에 따라 변경

xcodebuild test \
  -scheme EndlessCodeUITestHost \
  -destination 'platform=macOS' \
  -only-testing:EndlessCodeUITests/ScreenshotCaptureTests/${TEST_METHOD} \
  2>&1 | tee /tmp/verify-ui-output.log | tail -30
```

### 3. 스크린샷 캡처 (테스트 완료 후)

> **중요**: XCUITest 샌드박스 제한으로 테스트 내부에서 /tmp에 직접 저장 불가.
> 테스트가 앱을 원하는 상태로 만든 후, `screencapture`로 직접 캡처.

```bash
# 앱 활성화 (테스트 완료 후에도 앱이 실행 중)
osascript -e 'tell application "EndlessCode" to activate'
sleep 1

# 스크린샷 캡처
SCREENSHOT_PATH="/tmp/verify-ui-$(date +%Y%m%d-%H%M%S).png"
screencapture -x "$SCREENSHOT_PATH"
echo "Screenshot: $SCREENSHOT_PATH"
```

### 4. 스크린샷 분석

스크린샷 파일을 Read tool로 분석:

```
Read: {SCREENSHOT_PATH}
```

### 4. 검증 결과 판정

스크린샷을 보고 다음을 확인:

1. **레이아웃**: 요소들이 올바른 위치에 있는가?
2. **크기**: 패널이 전체 영역을 사용하는가?
3. **콘텐츠**: 텍스트, 코드가 올바르게 표시되는가?
4. **정렬**: 콘텐츠가 상단 좌측부터 시작하는가?

### 5. 결과 출력

```markdown
## UI 검증 결과

**시나리오**: {$ARGUMENTS 또는 file-selected}
**스크린샷**: {SCREENSHOT_PATH}

### 분석

{스크린샷 분석 내용}

### 결과: {✅ PASS | ⚠️ PARTIAL | ❌ FAIL}

{결과에 따른 상세 내용}
```

---

## 테스트 실패 시

테스트가 실패하면 에러 로그 확인:

```bash
# 에러 메시지 확인
grep -E "(error|Error|ERROR|failed|FAILED)" /tmp/verify-ui-output.log
```

가능한 원인:
1. **프로젝트 없음**: TestProject가 샌드박스에 없음
2. **빌드 실패**: EndlessCodeUITestHost 빌드 오류
3. **타임아웃**: UI 요소 로딩 지연

---

## 커스텀 검증

특정 조건을 검증하고 싶을 때:

```
/verify-ui file-selected

검증 조건:
- 파일 내용이 상단 좌측부터 표시되어야 함
- 라인 번호가 왼쪽에 표시되어야 함
- 패널 전체를 채워야 함
```

스크린샷 분석 시 위 조건들을 기준으로 판정.

---

## 디자인 참조 비교

`ui-design/` 디렉토리의 참조 디자인과 비교:

```bash
# 관련 디자인 파일
ls ui-design/*.png
```

참조 디자인을 함께 읽어서 일치도 확인.

---

## 전체 실행 예시

### 성공 케이스

```
/verify-ui file-selected
```

출력:
```
## UI 검증 결과

**시나리오**: file-selected
**스크린샷**: /tmp/verify-ui-screenshots/fileExplorer_fileSelected_2024-01-26T12-00-00Z.png

### 분석

스크린샷에서 파일 탐색기 화면이 보입니다:
- 왼쪽 패널: 파일 트리 (src 폴더 확장, utils.swift 선택됨)
- 오른쪽 패널: utils.swift 파일 내용
  - 헤더에 파일명과 크기 표시
  - 라인 번호가 왼쪽에 표시됨 (1-9)
  - 코드가 **상단 좌측**부터 시작하여 패널 전체를 채움
  - import Foundation, struct Utils 등 코드가 올바르게 표시됨

### 결과: ✅ PASS

모든 검증 조건이 충족되었습니다.
- 파일 내용이 상단 좌측부터 올바르게 표시됨
- 패널 전체 영역을 사용함
- 라인 번호와 코드가 정렬됨
```

### 실패 케이스

```
/verify-ui file-selected
```

출력:
```
## UI 검증 결과

**시나리오**: file-selected
**스크린샷**: /tmp/verify-ui-screenshots/fileExplorer_fileSelected_2024-01-26T12-00-00Z.png

### 분석

스크린샷에서 문제가 발견되었습니다:
- 파일 내용이 패널의 **가운데 하단**에 작게 표시됨
- 상단과 좌측에 불필요한 여백이 있음

### 결과: ❌ FAIL

#### 발견된 문제
1. **레이아웃 오류**: 콘텐츠가 상단 좌측이 아닌 가운데에 표시
   - 예상: 코드가 패널 상단 좌측부터 시작
   - 실제: 코드가 가운데 하단에 위치
   - 원인 추정: ScrollView 내부 콘텐츠 정렬 문제

#### 수정 제안
1. FileContentView.swift - GeometryReader로 콘텐츠 크기 강제
```

---

## 주의사항

1. **EndlessCodeUITestHost 스킴 사용**: Vapor 의존성 문제 우회
2. **샌드박스 데이터 필요**: TestProject가 있어야 테스트 가능
3. **실행 시간**: E2E 테스트 실행으로 약 30초 소요
4. **권한**: 화면 녹화 권한 필요 (XCUITest)
