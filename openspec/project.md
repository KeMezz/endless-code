# Project Context

## Purpose

**EndlessCode** - macOS/iOS용 네이티브 Claude Code 클라이언트

Claude Code CLI의 모든 기능을 GUI로 매끄럽게 사용할 수 있는 네이티브 앱 개발. 웹 기반 UI의 한계를 극복하고, CLI의 대화형 기능을 포함한 전체 워크플로우를 직관적인 인터페이스로 제공.

### 핵심 가치
1. **완전한 CLI 기능 지원**: 대화형 기능을 포함한 CLI의 모든 워크플로우를 GUI로 제공
2. **진정한 네이티브**: macOS/iOS 플랫폼 기능 최대 활용
3. **원격 접속**: 모바일에서도 개발 환경 접근
4. **확장성**: Linux 서버 지원으로 다양한 환경 커버

## Tech Stack

### 언어 및 프레임워크
- **Swift 6.2+** (Strict Concurrency 기본)
- **SwiftUI** (iOS 26+, macOS 26+)
- **Vapor 4** (서버)

### 필수 라이브러리
- **Tree-sitter**: 신택스 하이라이팅
- **MarkdownUI**: 마크다운 렌더링
- **ArgumentParser**: CLI (Post-MVP)

### 빌드 도구
- Xcode 16+
- Swift Package Manager
- Git

### 플랫폼 요구사항
- **macOS**: 26.0+ (Tahoe), Apple Silicon (M1+)
- **iOS**: 26.0+, iPhone/iPad
- **Linux** (Post-MVP): Ubuntu 22.04+, Debian 11+, CentOS/RHEL 8+

## Project Conventions

### Code Style
- Swift 6.2 Strict Concurrency 모드 사용
- SwiftUI 선언적 패턴 준수
- Actor 기반 동시성 처리
- 명시적 타입 선언 선호

### Architecture Patterns

**전체 구조**: Server-Client Architecture
```
Client Layer (SwiftUI)
    ↓ WebSocket/HTTP
Server Layer (Vapor)
    ↓ stdin/stdout/stderr
Claude Code CLI
```

**모듈 구조**:
- **Shared**: 공통 Models, ViewModels, Utilities
- **ClaudeCodeServer**: CLI 프로세스 관리, 세션 관리, Git 작업, JSONL 파싱, API 엔드포인트
- **macOS App**: 서버 대시보드, 메뉴바 컨트롤러, 내장 Vapor 서버
- **iOS App**: 서버 연결 설정, 네트워크 매니저

### Testing Strategy
- 단위 테스트: JSONL 파싱, 메시지 처리
- 통합 테스트: WebSocket 통신, CLI 프로세스 관리
- UI 테스트: 주요 사용자 플로우
- 성능 테스트: 메시지 응답 시간, 메모리 사용량

### Git Workflow
- Feature branch 기반 개발
- Conventional Commits 형식 사용
- PR 기반 코드 리뷰
- main 브랜치 보호

## Domain Context

### Claude Code CLI 통합
- CLI를 subprocess로 실행하여 stdin/stdout/stderr 직접 제어
- JSONL 포맷으로 메시지 스트리밍 수신
- 대화형 프롬프트(AskUserQuestion 등) 감지 및 응답 주입

### 메시지 타입
- `message`: 일반 텍스트 메시지
- `tool_use`: 도구 사용 요청
- `tool_result`: 도구 실행 결과

### 세션 관리
- `~/.claude/projects/` 디렉토리 스캔
- 프로젝트별 세션 히스토리 로딩
- JSONL 파일에서 과거 대화 복원

## Important Constraints

### 기술적 제약
- **iOS subprocess 제한**: iOS에서는 Process() 실행 불가, 반드시 외부 서버 필요
- **JSONL 스키마 의존성**: Claude Code 내부 포맷에 의존, 공식 API 아니므로 breaking change 가능
- **Tree-sitter 바이너리**: 언어별 파서 바이너리 필요, 앱 번들 크기 증가

### 성능 요구사항
- 메시지 전송 후 첫 응답: 100ms 이내
- JSONL 파싱 지연: 10ms 이하
- WebSocket 메시지 지연: 50ms 이하
- 메모리: 200MB 이하 (아이들), 500MB 이하 (활성)
- CPU: 평상시 5% 이하, 파싱 시 20% 이하

### 보안 요구사항
- API 토큰 기반 인증 (Keychain 저장)
- 원격 접속: HTTPS 필수
- 민감 정보 로그 금지

## External Dependencies

### 필수
- **Claude Code CLI**: 사용자 설치 필요, `/usr/local/bin/claude` 경로
- **Git**: 시스템 기본

### 선택
- **Tailscale**: 원격 접속용 VPN
- **Ngrok/Cloudflare Tunnel**: 임시 공개 접속

### 네트워크 요구사항
- 기본 포트: 3001 (설정 가능)
- 로컬: HTTP 허용
- 원격: HTTPS 필수 (인증서 검증)
- WebSocket: WSS 권장
