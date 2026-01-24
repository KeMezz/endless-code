# Change: Add MVP Specifications

## Why
EndlessCode 프로젝트의 MVP 기능을 정의하는 초기 스펙이 필요합니다. initial-spec.md에 정의된 요구사항을 정형화된 OpenSpec 형식으로 변환하여 구현 기준을 명확히 합니다.

## What Changes
- **ADDED** CLI 프로세스 관리 스펙 (cli-process-management)
- **ADDED** JSONL 파싱 스펙 (jsonl-parsing)
- **ADDED** WebSocket API 스펙 (websocket-api)
- **ADDED** 대화형 프롬프트 처리 스펙 (interactive-prompts)
- **ADDED** 세션 관리 스펙 (session-management)
- **ADDED** 채팅 인터페이스 스펙 (chat-interface)
- **ADDED** 파일 탐색기 스펙 (file-explorer)
- **ADDED** Diff 뷰어 스펙 (diff-viewer)
- **ADDED** iOS 클라이언트 스펙 (ios-client)

## Impact
- Affected specs: 신규 9개 capability 추가
- Affected code: 전체 프로젝트 (신규 구현)

## Scope
이 제안은 MVP (Phase 1) 기능만 포함합니다:
- macOS 앱의 서버 기능 (F-001 ~ F-006)
- macOS 앱의 클라이언트 기능 (F-007 ~ F-013)
- iOS 앱 기본 기능 (F-014 ~ F-017)

Post-MVP 기능 (F-018 ~ F-024)은 별도 제안에서 다룹니다.
