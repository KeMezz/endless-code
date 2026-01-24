# Review Loop Command

PR 인라인 리뷰 루프를 실행합니다.

## 인자

- `$ARGUMENTS`: PR 번호 (선택). 없으면 현재 브랜치의 PR 자동 감지

---

## 실행 지침

### 1. PR 및 Repo 정보 확인

```bash
gh pr view --json number,url,title,state,headRefName
gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"'
```

- PR이 없거나 closed면 종료
- `OWNER/REPO`와 `PR_NUMBER` 기록

### 2. 리뷰 요청

```bash
gh pr comment <PR_NUMBER> --body "@claude 리뷰"
```

### 3. 사용자 대기

AskUserQuestion으로 선택지 제공:
- **계속**: 리뷰 완료됨, 처리 시작
- **중단**: 루프 종료

### 4. 리뷰 코멘트 수집

#### 4.1 인라인 코멘트 (파일/라인 지정)

```bash
gh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/comments \
  --jq '[.[] | select(.user.type == "Bot" or .user.login == "github-actions[bot]") | {
    type: "inline",
    id: .id,
    path: .path,
    line: (.line // .original_line),
    body: .body,
    diff_hunk: .diff_hunk,
    created_at: .created_at
  }] | sort_by(.created_at) | reverse'
```

#### 4.2 일반 코멘트 (PR 전체 대상)

```bash
gh api repos/<OWNER>/<REPO>/issues/<PR_NUMBER>/comments \
  --jq '[.[] | select(.user.type == "Bot" or .user.login == "github-actions[bot]") | {
    type: "general",
    id: .id,
    body: .body,
    created_at: .created_at
  }] | sort_by(.created_at) | reverse'
```

두 종류 모두 새 코멘트 없으면 → "✅ 리뷰 루프 완료!" 출력 후 종료

### 5. 각 코멘트 처리

코멘트 type에 따라 처리 방식이 다름:
- **inline**: `path`(파일), `line`(라인), `body`(내용) 확인
- **general**: `body`(내용)만 확인, 전체적인 피드백

#### 5.1 심각도 파악

코멘트 body에서 심각도 이모지 확인:
- 🔴 **Critical**: 반드시 수정
- 🟡 **Warning**: 수정 권장
- 🟢 **Suggestion**: 선택적

#### 5.2 Suggestion 블록 확인

코멘트에 suggestion 블록이 있는지 확인:

```markdown
```suggestion
수정된 코드
```
```

있으면 해당 코드를 그대로 적용 가능.

#### 5.3 수정 결정

| 심각도 | 기본 행동 |
|--------|----------|
| 🔴 Critical | ACCEPT (수정) |
| 🟡 Warning | 검토 후 결정 |
| 🟢 Suggestion | 타당하면 ACCEPT, 아니면 REJECT |

#### 5.4 ACCEPT: 코드 수정

**인라인 코멘트 (type: inline)**:
1. 파일 읽기: `path`의 파일을 Read
2. 수정: `line` 위치의 코드 수정 (suggestion 블록 있으면 그대로 적용)
3. 스테이징: `git add <path>`
4. 답글:
   ```bash
   gh api repos/<OWNER>/<REPO>/pulls/comments/<COMMENT_ID>/replies \
     -f body="✅ 수정 완료"
   ```

**일반 코멘트 (type: general)**:
1. 코멘트에서 언급된 파일/패턴 파악
2. 해당 파일들 수정
3. 스테이징 및 답글:
   ```bash
   gh api repos/<OWNER>/<REPO>/issues/comments/<COMMENT_ID>/reactions \
     -f content="+1"
   gh pr comment <PR_NUMBER> --body "✅ 반영 완료: <요약>"
   ```

#### 5.5 REJECT: 이유 설명

**인라인 코멘트**:
```bash
gh api repos/<OWNER>/<REPO>/pulls/comments/<COMMENT_ID>/replies \
  -f body="현재 구현을 유지합니다.

**이유**: <구체적 이유>"
```

**일반 코멘트**:
```bash
gh pr comment <PR_NUMBER> --body "다음 피드백에 대해 현재 구현을 유지합니다:

> <원본 코멘트 요약>

**이유**: <구체적 이유>"
```

### 6. 커밋 및 푸시

수정된 파일이 있으면:

```bash
git commit -m "$(cat <<'EOF'
fix: 리뷰 반영

- <파일1>: <수정 내용>
- <파일2>: <수정 내용>

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"

git push
```

### 7. 루프 반복

Step 2로 돌아가 "@claude 리뷰" 재요청.

---

## 종료 조건

1. ✅ 새 인라인 코멘트 없음
2. 🛑 사용자 "중단" 선택
3. ⚠️ 동일 파일/라인 코멘트 3회 반복

---

## 처리 예시

### 인라인 코멘트 예시

```json
{
  "id": 123456,
  "path": "Sources/Server/CLIProcess.swift",
  "line": 42,
  "body": "🔴 **Critical**: nil 체크 누락\n\n**문제**: force unwrap 사용\n**해결**: guard let 사용\n\n```suggestion\nguard let process = self.process else { return }\n```",
  "diff_hunk": "@@ -40,3 +40,5 @@\n let process = self.process!"
}
```

### 처리 결과

1. `Sources/Server/CLIProcess.swift:42` 읽기
2. suggestion 블록의 코드로 교체
3. `git add Sources/Server/CLIProcess.swift`
4. 답글: "✅ 수정 완료"

---

## 최종 출력

```
## 리뷰 루프 완료

| 항목 | 수 |
|------|---|
| 처리된 코멘트 | N |
| 수정 반영 (ACCEPT) | M |
| 유지 (REJECT) | K |
| 커밋 | X |

PR: <URL>
```
