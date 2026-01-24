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

## Open Questions
1. Bonjour 서비스 발견 시 보안 고려사항?
2. HTTPS 인증서 관리 방식 (self-signed vs Let's Encrypt)?
3. 세션 데이터 암호화 범위?
