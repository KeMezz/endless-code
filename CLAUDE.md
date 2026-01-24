# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Always respond in Korean.

## Project Overview

**EndlessCode** - macOS/iOS 네이티브 Claude Code 클라이언트

Claude Code CLI를 subprocess로 실행하여 stdin/stdout/stderr를 직접 제어하고, JSONL 스트리밍으로 메시지를 파싱하여 SwiftUI 기반 GUI로 제공하는 앱.

## Architecture

```
Client Layer (SwiftUI)
    ↓ WebSocket/HTTP
Server Layer (Vapor)
    ↓ stdin/stdout/stderr
Claude Code CLI
```

**모듈 구조**:
- **Shared**: 공통 Models, ViewModels, Utilities
- **ClaudeCodeServer**: CLI 프로세스 관리, 세션 관리, JSONL 파싱, WebSocket API
- **macOS App**: 서버 대시보드, 메뉴바, 내장 Vapor 서버
- **iOS App**: 서버 연결, 네트워크 매니저

## Tech Stack

- **Swift 6.2+** (Strict Concurrency)
- **SwiftUI** (iOS 26+, macOS 26+)
- **Vapor 4** (서버)
- **Tree-sitter** (신택스 하이라이팅)
- **MarkdownUI** (마크다운 렌더링)

## Design Resources

UI 작업 시 반드시 `ui-design/` 디렉토리의 디자인 파일을 먼저 확인할 것.

| 파일 | 설명 |
|------|------|
| `ui-design/chat-interface.png` | 채팅 인터페이스 디자인 |
| `ui-design/file-explorer.png` | 파일 탐색기 디자인 |
| `ui-design/session-management.png` | 세션 관리 UI 디자인 |

## Build & Test Commands

```bash
# 빌드
xcodebuild build -scheme EndlessCode -destination 'platform=macOS'

# 전체 테스트
xcodebuild test -scheme EndlessCode -destination 'platform=macOS'

# 특정 테스트 클래스
xcodebuild test -scheme EndlessCode -destination 'platform=macOS' \
  -only-testing:EndlessCodeTests/JSONLParserTests

# 특정 테스트 메서드
xcodebuild test -scheme EndlessCode -destination 'platform=macOS' \
  -only-testing:EndlessCodeTests/JSONLParserTests/test_parseValidJSONL_returnsMessages

# iOS 테스트
xcodebuild test -scheme EndlessCode -destination 'platform=iOS Simulator,name=iPhone 16'

# 커버리지 리포트
xcodebuild test -scheme EndlessCode -destination 'platform=macOS' \
  -enableCodeCoverage YES -resultBundlePath TestResults.xcresult
xcrun xccov view --report TestResults.xcresult
```

## Code Conventions

- Actor 기반 동시성 처리
- Protocol 기반 의존성 주입 (테스트 용이성)
- 테스트 메서드명: `test_{조건}_{기대결과}`
- Given-When-Then 테스트 구조
- SwiftUI 뷰에 `accessibilityIdentifier` 필수 (UI 테스트용)

## Testing Requirements

- Line Coverage 80%, Branch 75%, Function 85% 이상
- 모든 구현에 테스트 필수
- TDD 권장

## OpenSpec Integration

스펙 기반 개발을 위해 OpenSpec을 사용합니다.

```bash
# 스펙 검증
openspec validate add-mvp-specs --strict --no-interactive
```

Planning, proposal, spec 관련 작업 시 `openspec/AGENTS.md` 참조.

<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->
