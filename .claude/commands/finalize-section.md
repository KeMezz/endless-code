# 섹션 완료 및 PR 생성

완료된 섹션에 대해 브랜치 생성, 의미 있는 단위로 커밋, PR 템플릿에 맞게 PR을 생성합니다.

## 매개변수

- `$ARGUMENTS`: 섹션 번호 (예: `1`, `2`, `3-chat`)

## 실행 방법

```
/finalize-section 1
/finalize-section 2
/finalize-section 3-chat
```

---

## 지시사항

### 0단계: 사전 확인

1. 현재 브랜치가 `main`인지 확인
2. 작업 디렉토리에 변경사항이 있는지 확인 (`git status`)
3. 변경사항이 없으면 에러 메시지 출력 후 종료

```bash
git status
git branch --show-current
```

### 1단계: 섹션 정보 파싱

`$ARGUMENTS`를 파싱하여 섹션 정보를 추출합니다.

- 섹션 번호: `$ARGUMENTS`에서 숫자 부분 (예: `1`, `2`, `3`)
- 섹션 이름: `$ARGUMENTS`에 추가 이름이 있으면 사용, 없으면 tasks.md에서 추출

**섹션 이름 매핑** (tasks.md 기준):

| 섹션 | 브랜치 이름 |
|------|------------|
| 1 | `feat/section-1-server-foundation` |
| 2 | `feat/section-2-macos-common` |
| 3 | `feat/section-3-chat` |
| 4 | `feat/section-4-file-explorer` |
| 5 | `feat/section-5-diff-viewer` |
| 6 | `feat/section-6-misc-ui` |
| 7 | `feat/section-7-ios` |
| 8 | `feat/section-8-docs` |

### 2단계: tasks.md 완료 상태 확인

`openspec/changes/add-mvp-specs/tasks.md`를 읽고 해당 섹션의 태스크 완료 상태를 확인합니다.

- 모든 태스크가 `[x]`로 체크되어 있는지 확인
- 미완료 태스크가 있으면 경고 메시지 출력 후 사용자에게 확인 요청

### 3단계: 브랜치 생성

```bash
git checkout -b feat/section-{N}-{name}
```

### 4단계: 커밋 그룹 분석

변경된 파일들을 분석하여 의미 있는 커밋 그룹으로 분류합니다.

**커밋 그룹 우선순위**:

1. **모델/타입 정의** - `*/Models/*.swift`, `*Types*.swift`
2. **핵심 로직** - 기능별 그룹핑 (파일 경로와 import 관계 분석)
3. **테스트** - `*Tests/*.swift`
4. **설정/문서** - `*.md`, `*.pbxproj`, `.gitignore`

**커밋 메시지 형식**:

```
{type}({scope}): {description}

- 세부 내용 1
- 세부 내용 2

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

**type 종류**: `feat`, `fix`, `test`, `chore`, `docs`, `refactor`

### 5단계: 순차적 커밋 실행

각 그룹별로 `git add` + `git commit` 실행:

```bash
# 예시
git add EndlessCode/Shared/Models/*.swift
git commit -m "feat(shared): add core models..."

git add EndlessCode/Server/Sources/ProcessRunner.swift ...
git commit -m "feat(server): add CLI process management..."
```

**중요**:
- 커밋 전 `git diff --staged`로 변경사항 확인
- 불필요한 파일(xcuserdata, DerivedData 등)이 포함되지 않도록 주의
- `.gitignore`가 없으면 먼저 생성

### 6단계: 커밋 히스토리 확인

```bash
git log --oneline feat/section-{N}-{name} ^main
```

### 7단계: PR 본문 생성

`.github/PULL_REQUEST_TEMPLATE.md` 템플릿을 기반으로 PR 본문을 생성합니다.

**자동 채워야 할 항목**:

1. **Summary**: 섹션 이름과 주요 구현 내용
2. **Changes > 완료된 태스크**: tasks.md에서 해당 섹션의 `[x]` 항목들
3. **Changes > 주요 변경 파일**: 커밋된 파일 목록 (git diff --stat)
4. **Manual Verification Required**: 섹션별 수동 검증 가이드
5. **Test Results**: 테스트 실행 결과 (가능하면 실행)
6. **Related > Spec**: 해당 섹션 관련 spec 파일 링크
7. **Checklist**: 체크리스트 항목

**섹션별 Manual Verification 가이드**:

| 섹션 | 검증 항목 |
|------|----------|
| 1 (Server) | CLI 프로세스 시작/종료, WebSocket 연결, JSONL 파싱 |
| 2 (공통 컴포넌트) | 프로젝트 목록, 세션 목록, 네비게이션 |
| 3 (채팅) | 메시지 전송/수신, 코드 블록 렌더링, 스트리밍 |
| 4 (파일 탐색기) | 트리 구조, 파일 열기, 검색 |
| 5 (Diff 뷰어) | Diff 파싱, 라인 하이라이팅 |
| 6 (기타 UI) | 마크다운, 프롬프트 다이얼로그, 설정 |
| 7 (iOS) | 서버 연결, 모바일 UI, 오프라인 처리 |
| 8 (테스트/문서) | 테스트 통과, 문서 정확성 |

### 8단계: PR 생성

```bash
git push -u origin feat/section-{N}-{name}
gh pr create --title "feat(section-{N}): {섹션 이름} 구현" --body "{PR 본문}"
```

### 9단계: 결과 보고

다음 형식으로 결과를 출력합니다:

```markdown
## ✅ Section {N} PR 생성 완료

### 브랜치
`feat/section-{N}-{name}`

### 커밋 (X개)
| 해시 | 메시지 |
|------|--------|
| abc1234 | feat(scope): description |
| ... | ... |

### PR
- **URL**: https://github.com/{owner}/{repo}/pull/{number}
- **제목**: feat(section-{N}): {섹션 이름} 구현

### 다음 단계
1. PR 리뷰 요청
2. Manual Verification 항목 확인
3. 머지 후 다음 섹션 진행
```

---

## 주의사항

1. **커밋 전 확인**: 불필요한 파일이 포함되지 않도록 주의
2. **테스트**: 가능하면 커밋 전 테스트 실행
3. **tasks.md 동기화**: 미완료 태스크가 있으면 먼저 완료 체크
4. **의존성**: 이전 섹션 PR이 머지되지 않았다면 base 브랜치 확인

## 에러 처리

| 상황 | 처리 |
|------|------|
| 변경사항 없음 | "커밋할 변경사항이 없습니다" 출력 후 종료 |
| 미완료 태스크 | 경고 후 사용자 확인 요청 |
| 빌드 실패 | 경고 출력, 사용자 판단에 맡김 |
| gh CLI 없음 | "gh CLI 설치 필요" 안내 |
