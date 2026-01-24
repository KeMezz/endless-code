# PR Workflow Rules

섹션별 PR 생성 및 리뷰 워크플로우입니다.

## ⚠️ 필수: PR 템플릿 사용

**모든 PR은 반드시 `.github/PULL_REQUEST_TEMPLATE.md` 템플릿을 기반으로 작성해야 합니다.**

GitHub에서 PR 생성 시 자동으로 템플릿이 로드됩니다. CLI로 생성 시에도 템플릿 내용을 준수하세요.

### 템플릿 핵심 섹션

| 섹션 | 필수 | 설명 |
|------|:----:|------|
| Summary | ✅ | 구현 내용 요약 |
| Changes | ✅ | 완료된 태스크 및 변경 파일 |
| **Manual Verification Required** | ✅ | 사람이 직접 확인해야 하는 항목 |
| Test Results | ✅ | 자동화 테스트 결과 |
| Screenshots | UI 변경 시 | 화면 캡처 |
| Checklist | ✅ | 최종 확인 사항 |

### Manual Verification 섹션 작성 가이드

**이 섹션이 가장 중요합니다.** 리뷰어가 직접 테스트해야 하는 항목을 명확히 작성:

```markdown
### 🔍 필수 확인 사항

- [ ] **메시지 전송**: 채팅창에서 메시지 입력 후 전송 버튼 클릭 → 메시지가 목록에 추가되어야 함
- [ ] **스크롤 동작**: 새 메시지 수신 시 자동으로 하단 스크롤되어야 함
- [ ] **에러 처리**: 서버 연결 끊김 시 에러 토스트 표시되어야 함

### 🎯 테스트 시나리오

1. 앱 실행 (`Cmd+R`)
2. 채팅 화면으로 이동
3. "Hello" 입력 후 전송
4. 응답이 표시되는지 확인
```

## PR 생성 규칙

### 커밋 메시지 형식

```
feat(section-N): 간단한 설명

- 세부 변경 사항 1
- 세부 변경 사항 2

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

### PR 제목 형식

```
feat(section-N): 섹션 이름 구현
```

예시:
- `feat(section-1): Server Core 기반 구현`
- `feat(section-3): 채팅 인터페이스 구현`
- `feat(section-7): iOS 앱 구현`

## PR 생성 명령어

```bash
# GitHub 웹에서 생성 (권장) - 템플릿 자동 로드
gh pr create --web

# CLI에서 생성 - 템플릿 내용 직접 작성
gh pr create \
  --title "feat(section-N): 섹션 이름 구현" \
  --body "$(cat .github/PULL_REQUEST_TEMPLATE.md)"
# 이후 에디터에서 템플릿 내용 채우기
```

## 리뷰 대기 안내

PR 생성 후 사용자에게 다음을 안내:

1. PR URL 제공
2. 주요 변경 사항 요약
3. 테스트 결과 요약
4. 다음 단계 (리뷰 후 머지 → 다음 섹션 진행)

## 머지 후 작업

PR이 머지된 후:

1. `main` 브랜치로 전환
2. 최신 변경 사항 pull
3. `tasks.md` 체크박스 상태 확인
4. 다음 섹션 브랜치 생성

## PR 체크리스트

PR 생성 전 반드시 확인:

- [ ] 모든 테스트 통과
- [ ] 테스트 커버리지 80% 이상
- [ ] Lint/Format 오류 없음
- [ ] 빌드 성공
- [ ] Spec Scenario와 구현 일치
- [ ] tasks.md 체크박스 업데이트
