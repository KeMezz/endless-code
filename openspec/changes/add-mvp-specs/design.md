# Design: MVP Architecture

## Context
EndlessCode는 macOS/iOS용 네이티브 Claude Code 클라이언트입니다. CLI의 대화형 기능을 포함한 전체 워크플로우를 GUI로 제공하며, Server-Client 아키텍처를 사용합니다.

### Stakeholders
- 개인 개발자 (macOS 사용자)
- 모바일 사용자 (iOS)
- Claude Code CLI 사용자

### Constraints
- iOS에서 subprocess 실행 불가 → 서버 의존 필수
- Claude Code CLI의 JSONL 포맷에 의존 (비공식 API)
- macOS 26.0+, iOS 26.0+ 필요

## Goals / Non-Goals

### Goals
- CLI의 모든 대화형 기능을 GUI에서 지원
- 실시간 양방향 통신 (WebSocket)
- 모바일에서 원격 접속 가능
- 방어적 파싱으로 CLI 버전 변경에 대응

### Non-Goals (MVP 제외)
- Linux CLI 서버 지원
- 다중 사용자 인증
- 코드 편집 기능
- MCP 서버 관리 UI

## Decisions

### Decision 1: Server-Client Architecture
macOS 앱에 Vapor 서버를 내장하고, iOS 앱은 순수 클라이언트로 동작합니다.

**Rationale**: iOS의 subprocess 제한을 우회하면서 macOS에서는 단일 앱으로 모든 기능 제공

**Alternatives considered**:
- 별도 서버 앱: 사용자 경험 복잡
- iOS에서 직접 API 호출: Claude Code CLI 기능 활용 불가

### Decision 2: WebSocket for Real-time Communication
REST API 대신 WebSocket을 주요 통신 채널로 사용합니다.

**Rationale**:
- CLI 출력의 실시간 스트리밍 필요
- 대화형 프롬프트의 즉각적인 전달
- 양방향 통신으로 사용자 응답 전송

**Alternatives considered**:
- Server-Sent Events: 단방향이라 stdin 주입 불가
- Polling: 지연 시간 증가, 리소스 낭비

### Decision 3: JSONL Streaming Parser
Claude CLI 출력을 라인 단위로 실시간 파싱합니다.

**Rationale**:
- CLI가 JSONL 형식으로 출력
- 버퍼링 없이 즉각적인 UI 업데이트 가능
- 부분 실패 시에도 서비스 지속

### Decision 4: Tree-sitter for Syntax Highlighting
WebView 기반 하이라이팅 대신 Tree-sitter 네이티브 파서를 사용합니다.

**Rationale**:
- 네이티브 성능
- 오프라인 동작
- 증분 파싱으로 대용량 파일 처리

**Trade-offs**:
- 앱 번들 크기 증가 (언어당 1-2MB)
- 초기 지원 언어 제한 (10-15개)

## Architecture Overview

```
┌─────────────────────────────────────────┐
│           Client Layer (SwiftUI)        │
│  ┌─────────────┐    ┌─────────────┐    │
│  │  macOS App  │    │   iOS App   │    │
│  └──────┬──────┘    └──────┬──────┘    │
└─────────┼───────────────────┼──────────┘
          │ Local             │ WebSocket
          │                   │
┌─────────▼───────────────────▼──────────┐
│         Server Layer (Vapor)            │
│  ┌────────────────────────────────┐    │
│  │      WebSocket Handler         │    │
│  │  ┌──────────┐ ┌─────────────┐ │    │
│  │  │ Session  │ │ ClaudeCode  │ │    │
│  │  │ Manager  │ │  Manager    │ │    │
│  │  └──────────┘ └──────┬──────┘ │    │
│  └──────────────────────┼────────┘    │
└─────────────────────────┼──────────────┘
                          │ stdin/stdout
                  ┌───────▼───────┐
                  │  claude (CLI) │
                  └───────────────┘
```

## Module Responsibilities

| Module | Responsibility |
|--------|----------------|
| ClaudeCodeManager | CLI 프로세스 생명주기, stdin/stdout 관리 |
| JSONLParser | CLI 출력 파싱, 메시지 타입 분류 |
| SessionManager | 세션 생명주기, 히스토리 관리 |
| WebSocketHandler | 클라이언트 연결, 메시지 라우팅 |
| ChatViewModel | 채팅 UI 상태 관리 |
| FileExplorerViewModel | 파일 트리 상태 관리 |

## Risks / Trade-offs

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| JSONL 포맷 변경 | Medium | High | 방어적 파싱, 버전 감지, 빠른 업데이트 |
| WebSocket 연결 불안정 | Low | Medium | 자동 재연결, 상태 동기화 |
| Tree-sitter 메모리 이슈 | Low | Medium | Lazy loading, 언어 제한 |

## Migration Plan
N/A - 신규 프로젝트

## Security Design

### Decision 5: Authentication Strategy
로컬 네트워크 통신에 토큰 기반 인증을 사용합니다.

**Rationale**:
- 동일 네트워크 내 다른 기기의 무단 접근 방지
- 간단한 구현으로 MVP에 적합

**Implementation**:
- 서버 시작 시 랜덤 256-bit 토큰 생성
- macOS 앱: Keychain에 토큰 저장
- iOS 앱: 수동 입력 또는 QR 코드 스캔으로 토큰 획득
- WebSocket 연결 시 Authorization 헤더로 토큰 전달
- 토큰 불일치 시 401 Unauthorized 응답

### Decision 6: TLS/HTTPS Configuration
MVP에서는 로컬 네트워크 전용으로 self-signed 인증서를 사용합니다.

**Rationale**:
- 로컬 네트워크 통신이므로 공인 인증서 불필요
- Let's Encrypt는 외부 접근 필요하여 부적합

**Implementation**:
- 서버 시작 시 self-signed 인증서 자동 생성
- 인증서를 Keychain에 저장하여 신뢰할 수 있는 인증서로 등록
- iOS 클라이언트는 인증서 핀닝 사용 (SHA-256 해시)
- WebSocket 연결은 wss:// 프로토콜 사용

### Decision 7: Session Data Protection
세션 데이터는 파일 시스템 수준 암호화에 의존합니다.

**Rationale**:
- macOS/iOS FileVault/Data Protection이 기본 제공
- 추가 암호화는 MVP 범위 초과

**Implementation**:
- 세션 파일은 기존 Claude Code CLI 형식 그대로 저장
- 민감 정보(토큰 등)는 Keychain에만 저장
- 앱 종료 시 메모리 내 토큰 정리

### Decision 8: Bonjour Security
Bonjour 서비스 발견은 제한적 신뢰 모델을 사용합니다.

**Rationale**:
- Bonjour는 로컬 네트워크 브로드캐스트로 보안 한계 존재
- 서비스 발견과 인증을 분리하여 보안 유지

**Implementation**:
- Bonjour로 서버 주소만 발견 (토큰 미포함)
- 연결 시 별도 토큰 입력 필수
- 서비스 이름에 민감 정보 미포함 (예: "EndlessCode-{random4chars}")

## Interface Definitions

### Protocol: CLIProcessProtocol
```swift
protocol CLIProcessProtocol: Sendable {
    var processId: UUID { get }
    var state: ProcessState { get }

    func start(projectPath: String) async throws
    func terminate() async
    func write(_ input: String) async throws

    var stdout: AsyncStream<String> { get }
    var stderr: AsyncStream<String> { get }
}

enum ProcessState: Sendable {
    case idle
    case running
    case terminated(exitCode: Int32)
    case failed(Error)
}
```

### Protocol: SessionManagerProtocol
```swift
protocol SessionManagerProtocol: Sendable {
    func listProjects() async throws -> [Project]
    func listSessions(projectId: String) async throws -> [Session]
    func createSession(projectId: String) async throws -> Session
    func resumeSession(sessionId: String) async throws -> Session
    func terminateSession(sessionId: String) async throws
}

struct Project: Codable, Sendable {
    let id: String
    let name: String
    let path: String
    let sessionCount: Int
    let lastUsed: Date?
}

struct Session: Codable, Sendable {
    let id: String
    let projectId: String
    let state: SessionState
    let createdAt: Date
    let lastActiveAt: Date
}

enum SessionState: String, Codable, Sendable {
    case active
    case paused
    case terminated
}
```

### Protocol: JSONLParserProtocol
```swift
protocol JSONLParserProtocol: Sendable {
    func parse(line: String) throws -> ParsedMessage
}

enum ParsedMessage: Sendable {
    case chat(ChatMessage)
    case toolUse(ToolUseMessage)
    case toolResult(ToolResultMessage)
    case askUser(AskUserQuestion)
    case unknown(rawJSON: String)
}

struct ChatMessage: Codable, Sendable {
    let type: String  // "message"
    let role: String  // "user" | "assistant"
    let content: String
    let timestamp: Date?
}

struct ToolUseMessage: Codable, Sendable {
    let type: String  // "tool_use"
    let toolName: String
    let toolInput: [String: AnyCodable]
    let toolUseId: String
}

struct ToolResultMessage: Codable, Sendable {
    let type: String  // "tool_result"
    let toolUseId: String
    let output: String
    let isError: Bool?
}

struct AskUserQuestion: Codable, Sendable {
    let type: String  // "tool_use"
    let toolName: String  // "AskUserQuestion"
    let question: String
    let options: [QuestionOption]?
    let multiSelect: Bool?
}

struct QuestionOption: Codable, Sendable {
    let label: String
    let description: String?
}
```

### WebSocket Message Schema
```json
// Client → Server
{
    "type": "user_message",
    "sessionId": "uuid",
    "content": "string",
    "timestamp": "ISO8601"
}

{
    "type": "prompt_response",
    "sessionId": "uuid",
    "promptId": "uuid",
    "selectedOptions": ["string"],
    "customInput": "string?"
}

{
    "type": "session_control",
    "action": "start" | "pause" | "resume" | "terminate",
    "sessionId": "uuid?",
    "projectId": "uuid?"
}

// Server → Client
{
    "type": "cli_output",
    "sessionId": "uuid",
    "message": ParsedMessage,
    "timestamp": "ISO8601"
}

{
    "type": "session_state",
    "sessionId": "uuid",
    "state": "active" | "paused" | "terminated",
    "error": "string?"
}

{
    "type": "prompt_request",
    "sessionId": "uuid",
    "promptId": "uuid",
    "question": AskUserQuestion,
    "timeout": 1800  // seconds
}

{
    "type": "error",
    "code": "string",
    "message": "string",
    "sessionId": "uuid?"
}

{
    "type": "sync",
    "sessions": [Session],
    "recentMessages": [ParsedMessage]  // max 100
}
```

## Error Handling Strategy

### Retry Policy
모든 재시도는 지수 백오프를 사용합니다.

| 작업 | 최대 재시도 | 초기 지연 | 최대 지연 |
|------|------------|----------|----------|
| WebSocket 재연결 | 10회 | 1초 | 60초 |
| 메시지 전송 | 3회 | 100ms | 1초 |
| CLI 프로세스 재시작 | 3회 | 500ms | 5초 |

### Error Propagation
```
CLI 크래시 → ClaudeCodeManager 감지 → SessionManager 상태 변경
  → WebSocket 브로드캐스트 → 클라이언트 UI 알림
```

### Error Codes
| Code | Description | Recovery |
|------|-------------|----------|
| CLI_NOT_FOUND | CLI 경로에 실행 파일 없음 | 설치 안내 표시 |
| CLI_CRASHED | CLI 프로세스 비정상 종료 | 자동 재시작 시도 |
| CLI_TIMEOUT | CLI 응답 30초 초과 | 세션 종료 옵션 제공 |
| SESSION_LIMIT | 최대 세션 수 초과 | 유휴 세션 종료 안내 |
| AUTH_FAILED | 토큰 인증 실패 | 재입력 요청 |
| NETWORK_ERROR | 네트워크 연결 실패 | 재연결 시도 |
| PARSE_ERROR | JSONL 파싱 실패 | 해당 라인 스킵, 로그 |

## Resolved Questions
~~1. Bonjour 서비스 발견 시 보안 고려사항?~~
→ Decision 8에서 해결: 서비스 발견과 인증 분리

~~2. HTTPS 인증서 관리 방식 (self-signed vs Let's Encrypt)?~~
→ Decision 6에서 해결: Self-signed + 인증서 핀닝

~~3. 세션 데이터 암호화 범위?~~
→ Decision 7에서 해결: OS 수준 암호화 의존, 토큰만 Keychain
