# Review Loop Command

PR 리뷰 코멘트를 분석하고 Claude와 대화하며 반복적으로 처리합니다.

## 인자

- `$ARGUMENTS`: PR 번호 (선택). 없으면 현재 브랜치의 PR 자동 감지. `--max-iterations N` 옵션 지원.

---

## 초기화

### 1. 인자 파싱

```bash
# 기본값
MAX_ITERATIONS=10
PR_NUMBER=""

# 인자 파싱
for arg in $ARGUMENTS; do
  if [[ "$prev_arg" == "--max-iterations" ]]; then
    MAX_ITERATIONS="$arg"
    prev_arg=""
  elif [[ "$arg" == "--max-iterations" ]]; then
    prev_arg="$arg"
  elif [[ "$arg" =~ ^[0-9]+$ ]]; then
    PR_NUMBER="$arg"
  fi
done
```

### 2. PR 정보 확인

```bash
# PR 정보
gh pr view ${PR_NUMBER} --json number,url,title,state,headRefName

# Repo 정보
gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"'
```

- PR이 없거나 closed면 종료
- `OWNER/REPO`와 `PR_NUMBER` 기록

### 3. 상태 파일 생성

`.claude/review-loop.local.md` 파일 생성:

```markdown
---
active: true
iteration: 1
max_iterations: {MAX_ITERATIONS}
pr_number: {PR_NUMBER}
owner_repo: {OWNER/REPO}
started_at: {ISO_TIMESTAMP}
---

PR #{PR_NUMBER} 리뷰 루프 진행 중
```

### 4. 초기화 메시지 출력

```
🔄 Review Loop 활성화!

PR: #{PR_NUMBER}
Iteration: 1 / {MAX_ITERATIONS}
Completion: Claude가 더 이상 수정 필요 없다고 할 때까지 반복

⚠️  이 루프는 Claude 승인 또는 max-iterations에 도달할 때까지 계속됩니다.
```

---

## 실행 지침

### 1. 상태 파일 읽기

`.claude/review-loop.local.md`에서 현재 iteration, PR 정보 확인.

### 2. 리뷰 요청 및 응답 대기 (첫 iteration만)

첫 iteration에서만 리뷰 요청 후 자동 대기:

```bash
# 요청 전 마지막 Claude 코멘트 시간 기록
LAST_COMMENT_TIME=$(gh pr view <PR_NUMBER> --json comments \
  --jq '.comments | map(select(.author.login == "claude")) | last.createdAt // empty')

# 요청 코멘트 작성
gh pr comment <PR_NUMBER> --body "@claude 리뷰"

# Polling 설정
TIMEOUT=600   # 10분
INTERVAL=30   # 30초
ELAPSED=0

echo "⏳ Claude 리뷰 대기 중..."

while [ $ELAPSED -lt $TIMEOUT ]; do
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))

  NEW_COMMENT_TIME=$(gh pr view <PR_NUMBER> --json comments \
    --jq '.comments | map(select(.author.login == "claude")) | last.createdAt // empty')

  if [ -n "$NEW_COMMENT_TIME" ] && [ "$NEW_COMMENT_TIME" != "$LAST_COMMENT_TIME" ]; then
    echo "✅ Claude 응답 완료!"
    break
  fi

  echo "   대기 중... ($ELAPSED초 / $TIMEOUT초)"
done

if [ $ELAPSED -ge $TIMEOUT ]; then
  echo "⚠️ 타임아웃 - Claude 응답 없음"
  # 사용자에게 계속 대기할지 질문
fi
```

### 3. 리뷰 코멘트 수집

```bash
gh pr view <PR_NUMBER> --json comments --jq '.comments | map(select(.author.login == "claude")) | last'
```

Claude의 최신 리뷰 코멘트 가져오기.

### 5. 코멘트 타당성 분석

**각 지적 사항에 대해:**

1. **실제 코드 확인**: 지적된 파일/라인을 Read tool로 직접 확인
2. **타당성 평가**:
   - 지적이 정확한가?
   - 현재 아키텍처/환경에서 실제 문제인가?
   - 수정의 비용/효과는?

3. **분류**:
   | 분류 | 기준 | 행동 |
   |------|------|------|
   | ✅ 타당 | 지적이 정확하고 수정 필요 | 수정 |
   | ⚠️ 부분 타당 | 일부만 맞거나 개선 권장 수준 | 선택적 수정 |
   | ❌ 부당 | 지적이 잘못됨 또는 현 환경에서 불필요 | Skip |

### 6. 코드 수정

타당한 지적에 대해서만 수정:

1. 파일 읽기 (Read)
2. 수정 (Edit)
3. 테스트 실행:
   ```bash
   # Unit 테스트 (필수)
   swift test

   # E2E 테스트 (UI 변경 시 필수, 그 외 선택)
   xcodebuild test -scheme EndlessCodeUITestHost -destination 'platform=macOS' \
     -only-testing:EndlessCodeUITests 2>&1 | tail -50
   ```
4. 스테이징 (`git add`)

### 7. 커밋 및 푸시

수정된 파일이 있으면:

```bash
git commit -m "$(cat <<'EOF'
refactor: 리뷰 피드백 반영

- <파일1>: <수정 내용>
- <파일2>: <수정 내용>

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"

git push
```

### 8. 대응 댓글 작성

PR에 @claude 멘션하여 대응 내용 작성:

```bash
gh pr comment <PR_NUMBER> --body "$(cat <<'EOF'
@claude 리뷰 피드백을 분석했습니다. 아래 판단이 적절한지 검토해주세요.

---

## ❌ 수정하지 않은 항목

### 1. {이슈 제목} ({리뷰어 평가} → Skip)

**리뷰어 주장**: {요약}

**실제 분석**:
- {코드 확인 결과}
- {Skip 이유}

**결론**: {Skip 근거}

---

## ✅ 수정한 항목

### 1. {이슈 제목}

**변경 전:**
```swift
{원본 코드}
```

**변경 후:**
```swift
{수정된 코드}
```

**이유**: {수정 이유}

---

## 질문

1. Skip한 판단이 적절한가요?
2. 수정한 항목의 구현이 적절한가요?
3. 추가로 수정이 필요한 부분이 있나요?
EOF
)"
```

### 9. Claude 응답 대기 (자동 Polling)

```bash
# 대응 댓글 작성 직후 시간 기록
REQUEST_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Polling 설정
TIMEOUT=600   # 10분
INTERVAL=30   # 30초
ELAPSED=0

echo "⏳ Claude 검토 응답 대기 중..."

while [ $ELAPSED -lt $TIMEOUT ]; do
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))

  # REQUEST_TIME 이후의 Claude 코멘트 확인
  NEW_RESPONSE=$(gh pr view <PR_NUMBER> --json comments \
    --jq --arg after "$REQUEST_TIME" \
    '.comments | map(select(.author.login == "claude" and .createdAt > $after)) | last // empty')

  if [ -n "$NEW_RESPONSE" ]; then
    echo "✅ Claude 응답 완료!"
    break
  fi

  echo "   대기 중... ($ELAPSED초 / $TIMEOUT초)"
done

if [ $ELAPSED -ge $TIMEOUT ]; then
  echo "⚠️ 타임아웃"
  # AskUserQuestion으로 계속/중단 선택
fi
```

### 10. Claude 응답 분석

```bash
gh pr view <PR_NUMBER> --json comments --jq '.comments | map(select(.author.login == "claude")) | last'
```

응답 내용 확인:

| Claude 응답 | 행동 |
|-------------|------|
| "머지 승인", "타당합니다", "수정 불필요" 등 | **루프 종료** |
| 추가 수정 요청 | **Step 5로 돌아가 반복** |

### 11. Iteration 업데이트

상태 파일의 iteration 증가:

```markdown
---
active: true
iteration: {N+1}
...
---

- Iteration N: {처리 요약}
```

### 12. 루프 반복

Claude가 추가 수정을 요청하면 Step 5로 돌아가 반복.

---

## 종료 조건

다음 중 하나 충족 시 `<promise>리뷰 완료</promise>` 출력:

1. ✅ Claude가 "머지 승인" 또는 "추가 수정 불필요" 응답
2. ⚠️ max-iterations 도달
3. 🛑 사용자 "중단" 선택
4. ⚠️ 동일 이슈 3회 반복 (무한 루프 방지)

---

## 상태 파일 구조

`.claude/review-loop.local.md`:

```yaml
---
active: true
iteration: 3
max_iterations: 10
pr_number: 42
owner_repo: "user/repo"
started_at: "2024-01-15T10:30:00Z"
---

PR #42 리뷰 루프 진행 중
- Iteration 1: 초기 리뷰 요청, 8개 코멘트 수신
- Iteration 2: 2개 수정, 6개 Skip, Claude 승인 대기
- Iteration 3: Claude 승인 완료
```

---

## 처리 흐름 요약

```
┌─────────────────────────────────────────────────────────┐
│  1. 상태 파일 확인/생성                                    │
└─────────────────┬───────────────────────────────────────┘
                  ▼
┌─────────────────────────────────────────────────────────┐
│  2. "@claude 리뷰" 코멘트 작성 (첫 iteration만)            │
└─────────────────┬───────────────────────────────────────┘
                  ▼
┌─────────────────────────────────────────────────────────┐
│  3. 자동 Polling (30초 간격, 최대 10분)                    │
│     → Claude 코멘트 감지 시 다음 단계                      │
└─────────────────┬───────────────────────────────────────┘
                  ▼
┌─────────────────────────────────────────────────────────┐
│  4. Claude 리뷰 코멘트 수집                               │
└─────────────────┬───────────────────────────────────────┘
                  ▼
┌─────────────────────────────────────────────────────────┐
│  5. 각 지적 사항 타당성 분석 (실제 코드 확인)               │
│     - ✅ 타당: 수정                                       │
│     - ❌ 부당: Skip + 이유 기록                           │
└─────────────────┬───────────────────────────────────────┘
                  ▼
┌─────────────────────────────────────────────────────────┐
│  6. 코드 수정 + 테스트 (Unit + E2E)                       │
└─────────────────┬───────────────────────────────────────┘
                  ▼
┌─────────────────────────────────────────────────────────┐
│  7. 커밋 & 푸시                                           │
└─────────────────┬───────────────────────────────────────┘
                  ▼
┌─────────────────────────────────────────────────────────┐
│  8. @claude 멘션하여 대응 댓글 작성                        │
│     - 수정한 항목 설명                                    │
│     - Skip한 항목 + 이유 설명                             │
│     - 판단이 적절한지 질문                                 │
└─────────────────┬───────────────────────────────────────┘
                  ▼
┌─────────────────────────────────────────────────────────┐
│  9. 자동 Polling (30초 간격, 최대 10분)                    │
│     → Claude 응답 감지 시 분석                            │
└─────────────────┬───────────────────────────────────────┘
                  ▼
          ┌───────┴───────┐
          │ Claude 응답    │
          └───────┬───────┘
     승인         │        추가 수정 요청
          ▼       │         ▼
┌─────────────┐   │  ┌─────────────────────────────────────┐
│ <promise>   │   │  │  10. Iteration++ → Step 5로 반복    │
│ 리뷰 완료   │   │  └─────────────────────────────────────┘
│ </promise>  │   │                    │
└─────────────┘   └────────────────────┘
```

---

## 최종 출력

```
## 리뷰 루프 완료

| 항목 | 수 |
|------|---|
| 총 Iteration | N |
| 수정 반영 | A |
| Skip (판단 유지) | S |
| 커밋 | C |

PR: <URL>
Claude 최종 응답: "머지 승인 가능"

<promise>리뷰 완료</promise>
```
