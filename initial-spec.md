# Claude Code Native - 개발 사양서

## 1. 프로젝트 개요

### 1.1 프로젝트 이름
**Claude Code Native** - macOS/iOS용 네이티브 Claude Code 클라이언트

### 1.2 목적
Claude Code CLI의 모든 기능을 GUI로 매끄럽게 사용할 수 있는 네이티브 앱 개발. 웹 기반 UI의 한계를 극복하고, CLI의 대화형 기능을 포함한 전체 워크플로우를 직관적인 인터페이스로 제공.

### 1.3 배경 및 문제점

**기존 솔루션의 한계:**
- **Claude Code UI (웹 기반)**
  - CLI stdin 제어 불가로 대화형 기능 제한
  - 웹 기반이라 macOS/iOS 네이티브 기능 활용 불가
  - 개인 서버 구축 필요 (Node.js 의존성)
  - 플랫폼별 최적화 어려움

**해결 방안:**
- 네이티브 프로세스 관리로 CLI stdin/stdout 직접 제어
- SwiftUI 기반 크로스 플랫폼 UI
- macOS 서버 + iOS 클라이언트 구조
- 추후 Linux CLI 서버 지원

### 1.4 핵심 가치

1. **완전한 CLI 기능 지원**: 대화형 기능을 포함한 CLI의 모든 워크플로우를 GUI로 제공
2. **진정한 네이티브**: macOS/iOS 플랫폼 기능 최대 활용
3. **원격 접속**: 모바일에서도 개발 환경 접근
4. **확장성**: Linux 서버 지원으로 다양한 환경 커버

---

## 2. 사용자 시나리오

### 2.1 Primary User Stories

**US-1: 개인 개발자가 macOS에서 사용**
```
As a: 맥북을 사용하는 개발자
I want to: 네이티브 앱으로 Claude Code를 사용하고
So that: 터미널 없이도 편하게 AI 코딩 어시스턴트를 활용할 수 있다

Acceptance Criteria:
- macOS 앱 다운로드 및 설치 가능
- 앱 실행 시 자동으로 서버 시작
- Claude Code CLI가 설치되어 있으면 바로 프로젝트 선택 가능
- 메뉴바에서 서버 상태 확인 및 제어
```

**US-2: 모바일에서 원격 접속**
```
As a: 이동 중인 개발자
I want to: iPhone에서 맥의 Claude Code 세션에 접속하고
So that: 외출 중에도 코드 리뷰나 간단한 작업 지시를 할 수 있다

Acceptance Criteria:
- iOS 앱에서 맥 서버 주소 입력 가능
- Tailscale/VPN 등 다양한 연결 방식 지원
- 채팅, 파일 탐색, diff 확인 가능
- 모바일 최적화된 UI
```

**US-3: 대화형 인터랙션 처리**
```
As a: Claude Code 사용자
I want to: Claude가 확인이나 선택을 요청할 때 UI에서 응답하고
So that: 터미널로 전환하지 않고도 모든 CLI 워크플로우를 GUI에서 진행할 수 있다

Acceptance Criteria:
- CLI의 대화형 프롬프트가 UI에 표시됨
- 객관식 옵션을 클릭하여 선택
- 직접 입력 옵션 지원
- 응답 제출 시 CLI가 즉시 진행
```

**US-4: 코드 변경 사항 확인**
```
As a: 코드 리뷰어
I want to: Claude가 만든 변경 사항을 diff로 확인하고
So that: 수정 내용을 이해하고 승인 여부를 결정할 수 있다

Acceptance Criteria:
- Git diff를 신택스 하이라이팅과 함께 표시
- 추가/삭제 라인이 시각적으로 구분됨
- 파일별로 변경사항 그룹화
- 마크다운 파일은 렌더링된 형태로도 확인 가능
```

**US-5: 팀 서버 구축 (Post-MVP)**
```
As a: 팀 리드
I want to: Linux 서버에 Claude Code 서버를 구축하고
So that: 팀원들이 모바일/데스크탑에서 공용 개발 환경에 접속할 수 있다

Acceptance Criteria:
- CLI로 서버 설치 및 실행 가능
- systemd 또는 Docker로 서비스 관리
- 여러 사용자 동시 접속 지원
- API 토큰으로 인증
```

---

## 3. 기능 명세

### 3.1 MVP 기능 (Phase 1)

#### 3.1.1 macOS 앱 - 서버 기능

**F-001: 로컬 서버 실행**
- 앱 실행 시 자동으로 Vapor 서버 시작
- 기본 포트: 3001 (설정 가능)
- `localhost` 및 네트워크 IP에서 접근 가능
- 메뉴바에서 서버 상태 및 주소 확인

**F-002: Claude Code CLI 프로세스 관리**
- 프로젝트 선택 시 `claude` CLI를 subprocess로 실행
- stdin/stdout/stderr 실시간 캡처
- 프로세스 생명주기 관리 (시작/중지/재시작)
- 여러 프로젝트의 동시 세션 지원

**F-003: JSONL 파싱 및 메시지 관리**
- Claude CLI의 JSONL 출력을 실시간 파싱
- 메시지 타입별 분류 (message, tool_use, tool_result)
- 스키마 변경에 대응하는 방어적 파싱
- 파싱 오류 시에도 서비스 지속

**F-004: WebSocket API 제공**
- 클라이언트와 실시간 양방향 통신
- 메시지 전송/수신 스트리밍
- 세션 상태 동기화
- 자동 재연결 지원

**F-005: 대화형 입력 처리**
- CLI의 대화형 프롬프트(AskUserQuestion 등) 감지
- 질문/선택 데이터를 클라이언트로 전달
- 클라이언트 응답을 CLI stdin에 주입
- 타임아웃 처리 (30분)

**F-006: 프로젝트 및 세션 관리**
- `~/.claude/projects/` 디렉토리 스캔
- 프로젝트별 세션 히스토리 로딩
- JSONL 파일에서 과거 대화 복원
- 세션 재개 기능

#### 3.1.2 macOS 앱 - 클라이언트 기능

**F-007: 프로젝트 브라우저**
- 사용 가능한 Claude Code 프로젝트 목록 표시
- 프로젝트별 메타데이터 (이름, 경로, 세션 수)
- 최근 사용 프로젝트 우선 표시
- 검색 및 필터링

**F-008: 채팅 인터페이스**
- 대화형 메시지 송수신
- 사용자/어시스턴트 메시지 구분
- 타임스탬프 표시
- 코드 블록 신택스 하이라이팅
- 마크다운 렌더링

**F-009: 파일 탐색기**
- 프로젝트 디렉토리 트리 구조 표시
- 폴더 확장/축소
- 파일 클릭 시 내용 표시
- 신택스 하이라이팅 (Tree-sitter)
- 읽기 전용 (편집 기능 제외)

**F-010: Diff 뷰어**
- Git diff 시각화
- 추가/삭제/변경 라인 색상 구분
- 라인 번호 표시
- Hunk 단위 그룹화
- 신택스 하이라이팅 적용

**F-011: 마크다운 뷰어**
- CLAUDE.md, README.md 등 렌더링
- GitHub 스타일 마크다운
- 코드 블록 하이라이팅
- 링크 클릭 가능

**F-012: 대화형 프롬프트 UI**
- CLI 질문/확인 요청 표시
- 객관식 옵션 버튼
- 멀티 셀렉트 지원
- 직접 입력 옵션
- 응답 제출 후 즉시 CLI 진행

**F-013: 설정 화면**
- 서버 포트 설정
- API 토큰 관리
- 로그 레벨 조정
- Claude CLI 경로 설정

#### 3.1.3 iOS 앱

**F-014: 서버 연결 설정**
- 서버 주소 입력 (IP 또는 도메인)
- API 토큰 입력
- 연결 테스트 기능
- 연결 상태 표시

**F-015: 로컬 네트워크 서버 발견 (Bonjour)**
- 같은 WiFi의 macOS 서버 자동 발견
- 발견된 서버 목록 표시
- 탭하여 자동 연결

**F-016: 모바일 최적화 UI**
- 하단 탭 네비게이션 (프로젝트/채팅/설정)
- 스와이프 제스처 지원
- 터치 친화적 버튼 크기
- 다크모드 지원

**F-017: 채팅, 파일, Diff 뷰어**
- macOS와 동일한 기능
- 모바일 화면에 최적화된 레이아웃
- 핀치 줌 지원 (코드 블록)

### 3.2 Post-MVP 기능 (Phase 2)

**F-018: CLI 서버 (Linux/macOS)**
- 독립 실행형 서버 바이너리
- CLI 인자로 포트, 호스트, 토큰 설정
- systemd 서비스 지원
- Docker 이미지 제공

**F-019: 코드 선택 및 컨텍스트 액션**
- 코드 블록 내 텍스트 선택
- 선택 영역에 대한 수정 요청
- 컨텍스트 메뉴 (Refactor, Comment, Fix)
- 선택한 코드를 포함한 메시지 자동 생성

**F-020: Git 통합 고급 기능**
- Staging/Unstaging
- Commit 작성
- 브랜치 전환
- Push/Pull

**F-021: MCP 서버 관리**
- MCP 서버 목록 확인
- UI에서 MCP 서버 추가/제거
- MCP 도구 사용 내역 표시

**F-022: 세션 관리 고급 기능**
- 세션 이름 변경
- 세션 삭제
- 세션 내보내기 (JSONL)
- 세션 검색

**F-023: 알림 및 백그라운드 실행**
- 작업 완료 알림
- 에러 발생 알림
- macOS: 메뉴바 상주
- iOS: 백그라운드 새로고침

**F-024: 다중 사용자 지원**
- 사용자별 인증 토큰
- 권한 관리 (읽기/쓰기)
- 동시 세션 제한

---

## 4. 기술 요구사항

### 4.1 플랫폼 요구사항

**macOS:**
- 최소 버전: macOS 26.0 (Tahoe)
- 아키텍처: Apple Silicon (M1+)
- 필수 소프트웨어: Claude Code CLI

**iOS:**
- 최소 버전: iOS 26.0
- 기기: iPhone, iPad
- 네트워크: WiFi 또는 셀룰러

**Linux (Post-MVP):**
- Ubuntu 22.04+, Debian 11+
- CentOS/RHEL 8+
- 아키텍처: x86_64, ARM64

### 4.2 개발 환경

**언어 및 프레임워크:**
- Swift 6.2+ (Strict Concurrency 기본)
- SwiftUI (iOS 26+, macOS 26+)
- Vapor 4 (서버)

**필수 라이브러리:**
- Tree-sitter (신택스 하이라이팅)
- MarkdownUI (마크다운 렌더링)
- ArgumentParser (CLI, Post-MVP)

**빌드 도구:**
- Xcode 16+
- Swift Package Manager
- Git

### 4.3 외부 의존성

**필수:**
- Claude Code CLI (사용자 설치)
- Git (시스템 기본)

**선택:**
- Tailscale (원격 접속)
- Ngrok/Cloudflare Tunnel (임시 공개)

### 4.4 성능 요구사항

**응답 시간:**
- 메시지 전송 후 첫 응답: 100ms 이내
- JSONL 파싱 지연: 10ms 이하
- WebSocket 메시지 지연: 50ms 이하

**리소스 사용:**
- 메모리: 200MB 이하 (아이들), 500MB 이하 (활성)
- CPU: 평상시 5% 이하, 파싱 시 20% 이하
- 배터리 영향: iOS 백그라운드에서 최소화

**확장성:**
- 동시 세션: 최소 5개
- 메시지 히스토리: 10,000개까지 원활
- 파일 트리: 10,000개 파일까지 지원

### 4.5 보안 요구사항

**인증:**
- API 토큰 기반 인증
- 토큰은 Keychain에 안전하게 저장
- 최소 16자 랜덤 토큰

**전송:**
- 로컬 네트워크: HTTP 허용
- 원격 접속: HTTPS 필수 (인증서 검증)
- WebSocket: WSS 권장

**데이터 보호:**
- 민감 정보 로그 금지
- 세션 데이터 암호화 저장 (선택적)
- 비밀번호, 토큰 등 평문 저장 금지

---

## 5. 아키텍처 개요

### 5.1 전체 시스템 구조

```
┌─────────────────────────────────────────────────────┐
│                   Client Layer                       │
│  ┌──────────────────┐      ┌──────────────────┐    │
│  │   macOS App      │      │    iOS App       │    │
│  │  (SwiftUI)       │      │   (SwiftUI)      │    │
│  └────────┬─────────┘      └────────┬─────────┘    │
└───────────┼──────────────────────────┼──────────────┘
            │                          │
            │ Local/WebSocket          │ WebSocket/HTTP
            │                          │
┌───────────▼──────────────────────────▼──────────────┐
│               Server Layer (macOS)                   │
│  ┌────────────────────────────────────────────┐     │
│  │          Vapor Application                 │     │
│  │  ┌──────────────┐  ┌──────────────────┐   │     │
│  │  │   Routes     │  │  SessionManager  │   │     │
│  │  │ - WebSocket  │  │ - ClaudeCodeMgr  │   │     │
│  │  │ - REST API   │  │ - GitManager     │   │     │
│  │  └──────────────┘  └──────────────────┘   │     │
│  └──────────────────┬─────────────────────────┘     │
└─────────────────────┼───────────────────────────────┘
                      │ Process spawn
                      │ stdin/stdout/stderr
                      │
              ┌───────▼────────┐
              │  claude (CLI)  │
              └────────────────┘
```

### 5.2 모듈 구조

**Shared (공통 모듈):**
- Models: 데이터 모델
- ViewModels: 비즈니스 로직
- Utilities: 헬퍼 함수

**ClaudeCodeServer (서버 코어):**
- ClaudeCodeManager: CLI 프로세스 관리
- SessionManager: 세션 생명주기
- GitManager: Git 작업
- JSONLParser: 메시지 파싱
- Routes: API 엔드포인트

**macOS App:**
- ServerDashboard: 서버 상태 UI
- MenuBarController: 메뉴바 통합
- 내장 Vapor 서버

**iOS App:**
- ServerSettings: 연결 설정
- NetworkManager: API 클라이언트

### 5.3 데이터 흐름

**메시지 전송:**
```
User Input (UI)
  → ViewModel
  → WebSocket Client
  → Server WebSocket Handler
  → ClaudeCodeManager
  → CLI stdin
  → Claude Code
```

**메시지 수신:**
```
Claude Code
  → stdout (JSONL)
  → ClaudeCodeManager
  → JSONLParser
  → SessionManager
  → WebSocket broadcast
  → Client WebSocket
  → ViewModel
  → UI Update
```

**대화형 입력 처리 (AskUserQuestion 등):**
```
Claude (tool_use: AskUserQuestion 등)
  → JSONL output
  → Parser가 대화형 프롬프트 감지
  → 사용자 입력 대기
  → UI에 질문/선택 표시
  → 사용자 응답 선택
  → CLI stdin으로 전달
  → Claude 진행
```

### 5.4 저장소 구조

**로컬 스토리지:**
- `~/.claude/projects/`: Claude 프로젝트 (CLI 관리)
- `~/Library/Application Support/ClaudeCodeNative/`: 앱 설정
- Keychain: API 토큰 저장

**세션 파일:**
- `~/.claude/projects/<project>/.claude/sessions/*.jsonl`
- 읽기 전용 (CLI가 생성)

---

## 6. 사용자 인터페이스

### 6.1 macOS 앱 화면 구성

**메인 윈도우:**
- 사이드바: 프로젝트/세션 목록
- 메인 영역: 채팅 또는 파일/diff 뷰
- 하단: 입력창 + 전송 버튼

**메뉴바 아이콘:**
- 서버 상태 (실행/중지)
- 로컬/네트워크 주소 복사
- 빠른 설정 접근

**프로젝트 브라우저:**
- 그리드 또는 리스트 뷰
- 프로젝트 카드: 이름, 경로, 세션 수
- 검색바

### 6.2 iOS 앱 화면 구성

**하단 탭:**
- Projects (프로젝트 목록)
- Chat (활성 세션)
- Files (파일 탐색)
- Settings (설정)

**채팅 화면:**
- 풀스크린 메시지 리스트
- 하단 고정 입력창
- 스크롤 시 입력창 숨김

**파일/Diff 뷰:**
- 터치 제스처 지원
- 핀치 줌
- 가로 스크롤 (긴 코드 라인)

### 6.3 공통 컴포넌트

**메시지 버블:**
- 사용자: 오른쪽 정렬, 파란색
- Claude: 왼쪽 정렬, 회색
- 코드 블록: 별도 배경, 복사 버튼
- 타임스탬프 (상대 시간)

**대화형 프롬프트 다이얼로그:**
- 모달 또는 인라인
- 질문 제목 (bold)
- 옵션 버튼 (라디오/체크박스)
- 설명 텍스트 (작게)
- 직접 입력 필드
- 제출/취소 버튼

**코드 블록:**
- 신택스 하이라이팅
- 라인 번호 (선택적)
- 언어 표시 (우측 상단)
- 복사 버튼

---

## 7. 제약사항 및 전제조건

### 7.1 전제조건

**사용자 환경:**
- Claude Code CLI가 설치되어 있어야 함
- macOS: `/usr/local/bin/claude` 경로
- 유효한 Anthropic API 키 (CLI 인증 완료)

**네트워크:**
- 로컬: 별도 설정 불필요
- 원격: 방화벽 포트 개방 필요 (3001)
- iOS: 서버와 네트워크 연결 가능해야 함

### 7.2 기술적 제약사항

**iOS subprocess 제한:**
- iOS에서는 Process() 실행 불가
- 반드시 외부 서버 필요 (macOS 또는 Linux)

**JSONL 스키마 의존성:**
- Claude Code의 내부 포맷 의존
- 스키마 변경 시 파싱 로직 수정 필요
- 공식 API 아니므로 breaking change 가능

**Tree-sitter 바이너리:**
- 언어별 파서 바이너리 필요
- 앱 번들 크기 증가 (언어당 ~1-2MB)
- 지원 언어 제한 (초기 10-15개)

### 7.3 비기능적 제약사항

**보안:**
- Claude CLI의 인증 매커니즘 의존
- 서버는 추가 인증 레이어 제공
- HTTPS 인증서는 사용자 책임

**호환성:**
- Claude Code 버전 의존성
- 최소 지원 버전 명시 필요
- 구버전 CLI와 호환성 미보장

**라이선스:**
- Tree-sitter: MIT
- Vapor: MIT
- MarkdownUI: MIT
- 상업적 사용 가능

---

## 8. 개발 로드맵

### 8.1 Phase 1 - MVP (4-5주)

**Week 1-2: 서버 코어**
- ClaudeCodeManager 구현
- JSONL 파싱
- WebSocket API
- AskUserQuestion 처리

**Week 3-4: macOS 앱**
- 기본 UI (채팅, 프로젝트)
- 신택스 하이라이팅
- Diff 뷰어
- 서버 통합

**Week 5: iOS 앱**
- 서버 연결
- 모바일 UI
- 테스트 및 버그 수정

### 8.2 Phase 2 - 고급 기능 (2-3개월)

**Month 2:**
- CLI 서버 구현
- Linux 지원
- Docker 이미지
- Git 고급 기능

**Month 3:**
- 코드 선택 액션
- MCP 관리
- 알림 시스템
- 성능 최적화

### 8.3 Phase 3 - 확장 (3-4개월)

**Long-term:**
- 다중 사용자 지원
- 플러그인 시스템
- AI 모델 선택
- 통계 및 분석

---

## 9. 성공 지표

### 9.1 기술적 지표

**기능 완성도:**
- [ ] CLI 대화형 기능 100% 작동
- [ ] JSONL 파싱 성공률 99%+
- [ ] WebSocket 연결 안정성 99.9%
- [ ] 신택스 하이라이팅 15개 이상 언어

**성능:**
- [ ] 메시지 응답 시간 < 100ms
- [ ] 앱 시작 시간 < 2초
- [ ] 메모리 사용 < 500MB
- [ ] 배터리 영향 < 5%/hour

### 9.2 사용자 경험 지표

**사용성:**
- [ ] 첫 설정 완료 시간 < 5분
- [ ] 서버 연결 성공률 > 95%
- [ ] UI 반응 속도: 모든 인터랙션 < 100ms
- [ ] 크래시 없이 4시간 연속 사용

**채택:**
- [ ] macOS 앱 다운로드 100+
- [ ] iOS 앱 다운로드 50+
- [ ] 일간 활성 사용자 20+
- [ ] 세션당 평균 사용 시간 30분+

---

## 10. 위험 요소 및 대응 방안

### 10.1 기술적 위험

**R-001: Claude Code JSONL 포맷 변경**
- **확률**: 중 (50%)
- **영향**: 높음
- **대응**: 방어적 파싱, 버전 감지, 빠른 업데이트 프로세스

**R-002: Tree-sitter 성능 이슈**
- **확률**: 낮음 (20%)
- **영향**: 중
- **대응**: Lazy loading, WebView fallback

**R-003: iOS subprocess 제한**
- **확률**: 확정 (100%)
- **영향**: 설계상 반영됨
- **대응**: 서버-클라이언트 아키텍처로 해결

### 10.2 제품적 위험

**R-004: Claude Code CLI 필수 의존성**
- **확률**: 확정 (100%)
- **영향**: 중
- **대응**: 명확한 설치 가이드, 자동 확인

**R-005: 사용자 채택 부족**
- **확률**: 중 (40%)
- **영향**: 높음
- **대응**: 기존 Claude Code UI 사용자 타겟팅, 차별점 강조

**R-006: 보안 문제**
- **확률**: 낮음 (10%)
- **영향**: 매우 높음
- **대응**: HTTPS 필수화, 토큰 인증, 보안 감사

---

## 11. 부록

### 11.1 용어 정의

- **CLI**: Command Line Interface, 터미널 기반 프로그램
- **JSONL**: JSON Lines, 한 줄에 하나의 JSON 객체
- **Process**: 운영체제가 실행하는 프로그램 인스턴스
- **stdin/stdout**: 표준 입력/출력 스트림
- **Subprocess**: 메인 프로세스가 실행하는 자식 프로세스
- **WebSocket**: 양방향 실시간 통신 프로토콜
- **Tree-sitter**: 증분 파싱 라이브러리
- **Vapor**: Swift 웹 프레임워크
- **Bonjour**: Apple의 로컬 네트워크 서비스 발견

### 11.2 참고 자료

- Claude Code 공식 문서: https://docs.anthropic.com/claude-code
- Tree-sitter: https://tree-sitter.github.io
- Vapor: https://vapor.codes
- SwiftUI: https://developer.apple.com/swiftui

### 11.3 버전 관리

- **문서 버전**: 1.0
- **최종 수정**: 2026-01-26
- **작성자**: 형진
- **검토자**: -
