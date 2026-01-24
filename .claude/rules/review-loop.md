# Review Loop Rules

PR 리뷰 루프 규칙입니다. 인라인 + 일반 코멘트 모두 지원.

## 사전 요구사항

### GitHub Secrets 설정

```
Repository Settings → Secrets and variables → Actions
→ CLAUDE_CODE_OAUTH_TOKEN 추가
```

OAuth 토큰은 https://console.anthropic.com 에서 발급.

### Workflow 파일

`.github/workflows/claude-review.yml` 이 설정되어 있어야 합니다.

### 모델

Opus 4.5 (`claude-opus-4-5-20251101`) 사용.

## 코멘트 유형

| 유형 | 설명 | 처리 |
|------|------|------|
| **인라인** | 특정 파일/라인 지적 | 해당 라인 직접 수정 |
| **일반** | 전체적인 피드백 (아키텍처, 패턴 등) | 관련 파일들 수정 |

## 심각도

| 이모지 | 레벨 | 의미 | 기본 행동 |
|--------|------|------|----------|
| 🔴 | Critical | 버그/보안/크래시 | 반드시 수정 |
| 🟡 | Warning | 에러핸들링/성능 | 수정 권장 |
| 🟢 | Suggestion | 가독성/네이밍 | 선택적 |

## Suggestion 블록 처리

GitHub의 suggestion 블록은 자동 적용 가능:

```markdown
```suggestion
guard let value = optional else { return }
```
```

→ 해당 라인을 suggestion 내용으로 교체

## 판단 기준

### ACCEPT (수정 반영)

- 🔴 Critical은 무조건 수정
- 🟡 Warning 중:
  - 실제 에러 가능성 있는 경우
  - 성능 병목이 확인되는 경우
- 🟢 Suggestion 중:
  - 명백히 가독성이 개선되는 경우
  - 팀 컨벤션과 일치하는 경우

### REJECT (유지 + 설명)

- 스타일 취향 차이
- 이미 의도된 설계
- PR 범위 외 사항
- 불필요한 최적화

## 답글 형식

### 수정 완료

```
✅ 수정 완료
```

### 유지 (REJECT)

```
현재 구현을 유지합니다.

**이유**: <한 줄 요약>

<필요시 상세 설명>
```

## 커밋 메시지

```
fix: 리뷰 반영

- path/to/file.swift: <수정 내용>
- path/to/other.swift: <수정 내용>

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

## 무한 루프 방지

다음 경우 사용자에게 확인 요청:

1. 동일 파일/라인에 3회 이상 코멘트
2. 한 번에 10개 이상 파일 수정 필요
3. 테스트 실패 발생

## 명령어

```bash
/review-loop        # 현재 브랜치 PR
/review-loop 42     # PR #42 지정
```
