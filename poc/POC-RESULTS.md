# Claude Code CLI PoC 결과

## 검증 환경

- Claude Code CLI: v2.1.19
- 테스트 일자: 2026-01-25

---

## 1. stream-json 출력 형식

### 필수 플래그

```bash
claude -p --output-format=stream-json --verbose
```

`--verbose` 플래그가 없으면 에러 발생.

### 메시지 타입

| type | subtype | 설명 |
|------|---------|------|
| `system` | `init` | 세션 초기화 (tools, mcp_servers, model 등) |
| `assistant` | - | Claude 응답 (content 배열 포함) |
| `user` | - | 사용자 입력 에코 |
| `result` | `success` | 턴 완료 (cost, usage 포함) |
| `stream_event` | - | 스트리밍 중간 이벤트 (--include-partial-messages) |

### system init 예시

```json
{
  "type": "system",
  "subtype": "init",
  "cwd": "/path/to/project",
  "session_id": "uuid",
  "tools": ["Task", "Bash", "Edit", "Read", "AskUserQuestion", ...],
  "mcp_servers": [...],
  "model": "claude-opus-4-5-20251101",
  "claude_code_version": "2.1.19"
}
```

---

## 2. 양방향 통신 (stdin/stdout)

### 입력 플래그

```bash
claude -p --input-format=stream-json --output-format=stream-json --verbose
```

### 사용자 메시지 형식

```json
{
  "type": "user",
  "message": {
    "role": "user",
    "content": "메시지 내용"
  }
}
```

### 응답 흐름

```
사용자 입력 (stdin JSONL)
  → system init
  → assistant (content 배열)
  → user (에코백)
  → result (완료)
```

---

## 3. AskUserQuestion 처리

### 감지 방법

`assistant` 메시지의 `content` 배열에서 `type: "tool_use"`, `name: "AskUserQuestion"` 확인.

### AskUserQuestion 구조

```json
{
  "type": "tool_use",
  "id": "toolu_01...",
  "name": "AskUserQuestion",
  "input": {
    "questions": [
      {
        "question": "질문 내용?",
        "header": "짧은 헤더",
        "options": [
          { "label": "옵션1", "description": "설명1" },
          { "label": "옵션2", "description": "설명2" }
        ],
        "multiSelect": false
      }
    ]
  }
}
```

### 응답 형식

```json
{
  "type": "user",
  "message": {
    "role": "user",
    "content": "{\"answers\":{\"q0\":\"선택한 옵션 label\"}}"
  }
}
```

- `q0`, `q1`, ... 는 questions 배열 인덱스
- `multiSelect: true`인 경우 배열로 응답: `{"q0": ["옵션1", "옵션2"]}`
- 직접 입력(Other)의 경우 label 대신 입력 텍스트

---

## 4. 핵심 발견 사항

### 작동 확인됨 ✅

1. **stream-json 양방향 통신** - stdin/stdout으로 JSONL 송수신 가능
2. **AskUserQuestion 감지** - tool_use 블록으로 감지 가능
3. **AskUserQuestion 응답** - JSON 문자열로 answers 객체 전달
4. **세션 정보** - init 메시지에서 도구 목록, MCP 서버 등 확인 가능

### 주의 사항 ⚠️

1. **--verbose 필수** - stream-json 출력에 필요
2. **content는 문자열** - answers 객체를 JSON.stringify()로 변환해야 함
3. **tool_result 형식 사용 불가** - Claude API의 tool_result 형식이 아닌 일반 user 메시지로 응답
4. **에코백 발생** - 사용자 입력이 stdout으로 다시 출력됨

---

## 5. 구현 권장 사항

### 서버 아키텍처

```
SwiftUI App
    │
    ▼
┌─────────────────────────────┐
│  ClaudeCodeManager (Swift)  │
│  - Process spawn            │
│  - stdin/stdout pipe        │
│  - JSONL parser             │
└─────────────────────────────┘
    │ subprocess
    ▼
┌─────────────────────────────┐
│  claude CLI                 │
│  --input-format=stream-json │
│  --output-format=stream-json│
│  --verbose                  │
└─────────────────────────────┘
```

### Swift 구현 포인트

```swift
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/local/bin/claude")
process.arguments = [
    "-p",
    "--input-format=stream-json",
    "--output-format=stream-json",
    "--verbose"
]

let stdin = Pipe()
let stdout = Pipe()
process.standardInput = stdin
process.standardOutput = stdout

// JSONL 파싱
stdout.fileHandleForReading.readabilityHandler = { handle in
    let data = handle.availableData
    // 라인별 JSON 파싱
}

// 메시지 전송
let message = ["type": "user", "message": ["role": "user", "content": "Hello"]]
let jsonData = try JSONSerialization.data(withJSONObject: message)
stdin.fileHandleForWriting.write(jsonData)
stdin.fileHandleForWriting.write("\n".data(using: .utf8)!)
```

---

## 6. 다음 단계

1. **Swift 프로토타입** - Process + Pipe로 CLI 제어
2. **JSONL 파서** - Codable 모델 정의
3. **AskUserQuestion UI** - SwiftUI 컴포넌트
4. **세션 관리** - 세션 ID 추적, 재개 기능
