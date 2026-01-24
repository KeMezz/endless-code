# Implementation Rules

구현 명령 시 적용되는 규칙입니다.

## 섹션별 PR 분할 전략

`openspec:apply` 또는 구현 요청 시, `tasks.md`의 섹션 구조를 기반으로 PR을 분리합니다.

### PR 분할 기준

| PR | Section | Capability | 의존성 |
|----|---------|------------|--------|
| #1 | 1.1-1.3 | 프로젝트 기반 + JSONL 파싱 | 없음 |
| #2 | 1.4-1.5 | 세션 관리 + WebSocket API | #1 |
| #3 | 1.6-1.7 | 대화형 프롬프트 + 서버 테스트 | #2 |
| #4 | 2.x | macOS 공통 컴포넌트 | #3 |
| #5 | 3.x | 채팅 인터페이스 | #4 |
| #6 | 4.x | 파일 탐색기 | #4 (병렬 가능) |
| #7 | 5.x | Diff 뷰어 | #4 (병렬 가능) |
| #8 | 6.x | 기타 UI | #4 (병렬 가능) |
| #9 | 7.x | iOS App | #5-8 |
| #10 | 8.x | 테스트 및 문서화 | #9 |

### 브랜치 네이밍 규칙

```
feat/section-1-server-foundation
feat/section-1-session-websocket
feat/section-1-prompts-tests
feat/section-2-macos-common
feat/section-3-chat
feat/section-4-file-explorer
feat/section-5-diff-viewer
feat/section-6-misc-ui
feat/section-7-ios
feat/section-8-docs
```

## 서브에이전트 병렬 처리

### 병렬화 가능한 작업

다음 작업들은 의존성이 없어 **Task tool로 동시에 실행**해야 합니다:

1. **Section 4-8 내부** (macOS 공통 완료 후):
   - 채팅 ↔ 파일 탐색기 ↔ Diff 뷰어 ↔ 기타 UI

2. **각 섹션 내부**:
   - View 구현 ↔ ViewModel 구현 (동일 기능일 경우)

### 병렬 실행 패턴

```yaml
# 단일 메시지에서 여러 Task tool 호출
Task 1: "FileTreeView 구현" (subagent_type: general-purpose)
Task 2: "FileTreeViewModel 구현" (subagent_type: general-purpose)
```

**IMPORTANT**: 병렬 가능한 작업은 반드시 **한 번의 응답에서 여러 Task tool을 동시에 호출**해야 합니다.

## 구현 워크플로우

### 1. 섹션 시작 전

```bash
# 1. 관련 문서 확인
Read: openspec/changes/add-mvp-specs/tasks.md
Read: openspec/changes/add-mvp-specs/specs/{capability}/spec.md

# 2. 브랜치 생성
git checkout -b feat/section-N-name
```

### 2. 구현 중

- **TaskCreate/TaskUpdate**로 진행 상황 추적
- 병렬화 가능한 작업은 **Task tool로 동시 실행**
- 각 태스크 완료 시 `tasks.md` 체크박스 업데이트 (`- [x]`)
- **테스트 먼저 작성** (TDD 권장)

### 3. 섹션 완료 후

```bash
# 테스트 실행
xcodebuild test -scheme EndlessCode -destination 'platform=macOS'

# 검증
openspec validate add-mvp-specs --strict --no-interactive

# 커밋 및 PR
git add .
git commit -m "feat(section-N): ..."
git push -u origin feat/section-N-name
gh pr create
```

### 4. 전체 완료 후

```bash
openspec archive add-mvp-specs --yes
```

## tasks.md 체크박스 동기화 프로세스

### 업데이트 주체

- **구현 중**: Claude가 각 태스크 완료 시 실시간으로 `- [x]` 체크

### 업데이트 타이밍

1. 개별 태스크 완료 직후 (구현 중)
2. PR 생성 시 완료된 태스크 확인
3. PR 머지 후 main 브랜치에서 최종 확인

### 충돌 방지

- 각 섹션 브랜치에서 해당 섹션의 태스크만 업데이트
- 다른 섹션의 체크박스는 수정하지 않음

## 주의사항

- **의존성 그래프 준수**: PR 머지 순서는 반드시 의존성을 따름
- **Spec 일관성**: 구현이 spec의 Scenario와 일치하는지 검증
- **tasks.md 동기화**: PR 완료 시 체크박스 반드시 업데이트
- **단일 archive**: 모든 섹션 완료 후 마지막에 한 번만 archive
- **테스트 필수**: 모든 태스크에 테스트 작성 (testing.md 참조)
