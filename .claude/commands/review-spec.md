# OpenSpec 타당성 검증

OpenSpec change의 proposal, design, tasks, specs를 서브에이전트를 활용하여 면밀히 검토합니다.

## 매개변수

- `$ARGUMENTS`: change 이름 (예: `add-mvp-specs`)

## 실행 방법

```
/review-spec add-mvp-specs
```

## 검증 항목

1. **proposal.md**: 제안 내용 일관성, 기술적 실현 가능성, 누락 사항
2. **design.md**: 아키텍처 일관성, 기술 스택 적절성, 인터페이스 명확성
3. **tasks.md**: 태스크 구조 논리성, 의존성 순서, 범위 적절성, 누락 태스크
4. **specs/**: 각 spec 완성도, spec 간 일관성, 시나리오 명확성, 엣지 케이스

---

## 지시사항

### 1단계: 경로 확인

change 이름이 `$ARGUMENTS`입니다.
- 기본 경로: `openspec/changes/$ARGUMENTS/`
- 존재하지 않으면 에러 메시지 출력 후 종료

### 2단계: 병렬 검증 실행

다음 4개의 서브에이전트를 **동시에** 실행하세요 (Task tool 병렬 호출):

#### Agent 1: proposal.md 리뷰
```
openspec/changes/$ARGUMENTS/proposal.md 파일을 읽고 다음을 분석:
1. 제안 내용의 일관성
2. 기술적 실현 가능성
3. 불명확하거나 모순되는 부분
4. 누락된 중요 사항

한국어로 분석 결과를 상세히 제공해줘.
```

#### Agent 2: design.md 리뷰
```
openspec/changes/$ARGUMENTS/design.md 파일을 읽고 다음을 분석:
1. 아키텍처 설계의 일관성
2. 기술 스택 선택의 적절성
3. 컴포넌트 간 의존성 및 인터페이스 정의의 명확성
4. 불명확하거나 모순되는 부분
5. 누락된 설계 요소

한국어로 분석 결과를 상세히 제공해줘.
```

#### Agent 3: tasks.md 리뷰
```
openspec/changes/$ARGUMENTS/tasks.md 파일을 읽고 다음을 분석:
1. 태스크 구조의 논리성
2. 의존성 순서의 적절성
3. 태스크 범위의 적절성 (너무 크거나 작지 않은지)
4. 누락된 태스크
5. 모호하거나 불명확한 태스크 정의

한국어로 분석 결과를 상세히 제공해줘.
```

#### Agent 4: specs 디렉토리 리뷰
```
openspec/changes/$ARGUMENTS/specs/ 디렉토리 구조와 내부 spec 파일들을 모두 읽고 다음을 분석:
1. 각 spec의 완성도
2. spec 간 일관성
3. Given-When-Then 시나리오의 명확성
4. 누락된 시나리오나 엣지 케이스
5. 모순되는 요구사항

한국어로 분석 결과를 상세히 제공해줘.
```

### 3단계: 결과 종합

서브에이전트 결과를 종합하여 다음 형식으로 보고서를 작성하세요:

```markdown
## 📋 OpenSpec 리뷰 종합 보고서: $ARGUMENTS

### 🎯 종합 평가

| 문서 | 점수 | 상태 |
|------|:----:|------|
| proposal.md | X/10 | ✅/⚠️/❌ |
| design.md | X/10 | ✅/⚠️/❌ |
| tasks.md | X/10 | ✅/⚠️/❌ |
| specs/ | X/10 | ✅/⚠️/❌ |

### 🚨 Critical 이슈 (P0)
- 구현 전 반드시 해결해야 하는 문제들

### ⚠️ 중요 이슈 (P1)
- 구현 초기에 해결해야 하는 문제들

### 📝 개선 권장 사항 (P2)
- 향후 개선하면 좋은 사항들

### ✅ 잘 된 점
- 긍정적인 부분들
```

### 4단계: openspec validate 실행

마지막으로 다음 명령어를 실행하여 형식 검증:
```bash
openspec validate $ARGUMENTS --strict --no-interactive
```
