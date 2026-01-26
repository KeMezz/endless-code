# UI 검증 Command

UI 변경 후 스크린샷을 찍어 예상대로 렌더링되었는지 검증합니다.

## 인자

- `$ARGUMENTS`: 검증할 UI 설명 (선택). 없으면 최근 변경 사항 기준으로 검증.

예시:
- `/verify-ui 파일 탐색기에서 파일 선택 시 우측 패널이 꽉 차야 함`
- `/verify-ui`

---

## 워크플로우

### 1. 검증 조건 확인

`$ARGUMENTS`가 있으면 해당 내용을 검증 조건으로 사용.
없으면 최근 git diff를 분석하여 UI 관련 변경 사항을 파악.

```bash
# 최근 변경된 UI 파일 확인
git diff --name-only HEAD~1 | grep -E '\.(swift)$' | grep -E '(View|Component)'
```

### 2. 앱 빌드

```bash
xcodebuild build -scheme EndlessCode -destination 'platform=macOS' -quiet 2>&1 | tail -10
```

빌드 실패 시 에러 메시지 출력 후 종료.

### 3. 기존 앱 종료 (있으면)

```bash
pkill -f "EndlessCode.app" 2>/dev/null || true
sleep 1
```

### 4. 앱 실행

```bash
# DerivedData에서 앱 경로 찾기
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/EndlessCode-*/Build/Products/Debug -name "EndlessCode.app" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
  echo "❌ EndlessCode.app을 찾을 수 없습니다. 빌드를 먼저 실행하세요."
  exit 1
fi

open "$APP_PATH"
sleep 3
```

### 5. 앱 윈도우 활성화

```bash
osascript -e 'tell application "EndlessCode" to activate'
sleep 1
```

### 6. 스크린샷 촬영

```bash
SCREENSHOT_PATH="/tmp/verify-ui-$(date +%Y%m%d-%H%M%S).png"
screencapture -x "$SCREENSHOT_PATH"
echo "📸 스크린샷 저장: $SCREENSHOT_PATH"
```

### 7. 스크린샷 분석

Read tool을 사용하여 스크린샷 분석:

```
Read: {SCREENSHOT_PATH}
```

스크린샷을 보고 다음을 확인:

1. **레이아웃**: 요소들이 올바른 위치에 있는가?
2. **크기**: 패널, 버튼 등이 적절한 크기인가?
3. **콘텐츠**: 텍스트, 아이콘이 올바르게 표시되는가?
4. **상태**: 로딩, 에러 등 상태가 올바른가?

### 8. 검증 결과 판정

검증 조건과 스크린샷을 비교하여 판정:

| 결과 | 조건 |
|------|------|
| ✅ PASS | 모든 검증 조건 충족 |
| ⚠️ PARTIAL | 일부 조건만 충족 |
| ❌ FAIL | 주요 조건 미충족 |

### 9. 결과 출력

```markdown
## UI 검증 결과

**검증 조건**: {$ARGUMENTS 또는 자동 감지된 조건}

**스크린샷**: {SCREENSHOT_PATH}

### 분석

{스크린샷 분석 내용}

### 결과: {✅ PASS | ⚠️ PARTIAL | ❌ FAIL}

{PASS인 경우}
모든 검증 조건이 충족되었습니다.

{PARTIAL인 경우}
#### 충족된 조건
- {조건 1}

#### 미충족 조건
- {조건 2}: {이유}

{FAIL인 경우}
#### 발견된 문제
1. **{문제 1}**: {설명}
   - 예상: {예상 동작}
   - 실제: {실제 동작}
   - 원인 추정: {가능한 원인}

#### 수정 제안
1. {파일명}:{라인번호} - {수정 내용}
```

---

## 대화형 검증 모드

스크린샷만으로 확인이 어려운 경우 (예: 특정 버튼 클릭 후 상태):

### 사용자에게 조작 요청

```markdown
### 수동 조작 필요

다음 단계를 수행해주세요:

1. {조작 1}
2. {조작 2}

완료 후 "확인"이라고 말씀해주세요. 스크린샷을 다시 찍겠습니다.
```

사용자가 "확인" 응답 시 Step 6부터 반복.

---

## 디자인 참조 비교 (선택)

`ui-design/` 디렉토리에 참조 디자인이 있는 경우:

```bash
# 관련 디자인 파일 찾기
ls ui-design/*.png
```

참조 디자인과 현재 스크린샷을 비교하여 일치도 확인.

---

## 예시 실행

### 예시 1: 파일 탐색기 검증

```
/verify-ui 파일 탐색기에서 파일 선택 시 우측 패널에 파일 내용이 꽉 차게 표시되어야 함
```

출력:
```
## UI 검증 결과

**검증 조건**: 파일 탐색기에서 파일 선택 시 우측 패널에 파일 내용이 꽉 차게 표시되어야 함

**스크린샷**: /tmp/verify-ui-20240126-143022.png

### 분석

스크린샷에서 EndlessCode 앱의 파일 탐색기 화면이 보입니다:
- 왼쪽 패널: 파일 트리가 표시됨 (TestProject)
- 오른쪽 패널: config.json 파일이 선택된 상태
- 파일 내용이 우측 패널 전체를 채우고 있음
- 라인 번호가 왼쪽에 표시됨
- 코드가 상단 좌측부터 시작하여 올바르게 정렬됨

### 결과: ✅ PASS

모든 검증 조건이 충족되었습니다.
- 우측 패널이 전체 높이를 사용함
- 파일 내용이 상단부터 올바르게 표시됨
- 스크롤 영역이 패널 전체를 차지함
```

### 예시 2: 문제 발견

```
/verify-ui 채팅 화면에서 메시지 입력창이 하단에 고정되어야 함
```

출력:
```
## UI 검증 결과

**검증 조건**: 채팅 화면에서 메시지 입력창이 하단에 고정되어야 함

**스크린샷**: /tmp/verify-ui-20240126-143522.png

### 분석

스크린샷에서 채팅 화면이 보이지만:
- 메시지 입력창이 화면 중앙에 위치함
- 하단에 불필요한 여백이 있음

### 결과: ❌ FAIL

#### 발견된 문제
1. **입력창 위치 오류**: 하단 고정이 아닌 중앙 배치
   - 예상: 입력창이 화면 하단에 고정
   - 실제: 입력창이 화면 중앙에 위치
   - 원인 추정: VStack에서 Spacer() 누락 또는 frame 설정 오류

#### 수정 제안
1. ChatView.swift:25 - VStack 내부에 메시지 목록과 입력창 사이 Spacer() 확인
2. MessageInputView.swift - frame(maxHeight:) 설정 확인
```

---

## 주의사항

1. **권한 필요**: `screencapture`는 화면 녹화 권한 필요 (시스템 설정 > 개인 정보 보호)
2. **앱 상태**: 앱이 실행 중이어야 함, 다이얼로그가 열려있으면 닫아야 함
3. **해상도**: 스크린샷은 현재 화면 해상도로 촬영됨
4. **멀티 모니터**: 메인 모니터의 스크린샷만 촬영됨

---

## 연속 검증

여러 화면을 연속으로 검증할 때:

```
/verify-ui 프로젝트 목록 → 파일 탐색기 → 파일 선택 순서로 네비게이션 검증
```

이 경우 각 단계마다 스크린샷을 찍고 분석.
