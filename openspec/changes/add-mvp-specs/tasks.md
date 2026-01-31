# Tasks: MVP Implementation

## 1. Server Core

### 1.1 프로젝트 기반 설정
- [x] 1.1.1 Vapor 패키지 추가 및 서버 엔트리포인트
- [x] 1.1.2 공통 모델 정의 - Message, Session, Project 타입
- [x] 1.1.3 설정 모델 및 환경 변수 처리

### 1.2 CLI 프로세스 관리
- [x] 1.2.1 ProcessRunner - 기본 Process 래퍼, 시작/종료
- [x] 1.2.2 ProcessRunner - stdin 쓰기, stdout/stderr 스트리밍
- [x] 1.2.3 ClaudeCodeManager - ProcessRunner 통합, 세션별 프로세스 관리
- [x] 1.2.4 ClaudeCodeManager - 에러 복구 (크래시 감지, 자동 재시작, 지수 백오프)
- [x] 1.2.5 ClaudeCodeManager - 리소스 관리 (세션 수 제한, 좀비 프로세스 정리)

### 1.3 JSONL 파싱
- [x] 1.3.1 JSONLParser - 라인 버퍼링 및 기본 파싱
- [x] 1.3.2 메시지 타입 분류 - message, tool_use, tool_result
- [x] 1.3.3 방어적 파싱 - 누락 필드, 알 수 없는 타입 처리

### 1.4 세션 관리
- [x] 1.4.1 ProjectDiscovery - ~/.claude/projects 디렉토리 스캔
- [x] 1.4.2 ProjectDiscovery - 메타데이터 추출 (이름, 경로, 세션 수)
- [x] 1.4.3 ProjectDiscovery - 유효성 검증 및 필터링
- [x] 1.4.4 SessionStore - 세션 CRUD (Create, Read, Update, Delete)
- [x] 1.4.5 SessionStore - 메모리 캐시 및 상태 관리
- [x] 1.4.6 SessionHistoryLoader - JSONL 파일 파싱
- [x] 1.4.7 SessionHistoryLoader - 페이지네이션 (최근 1,000개 초기 로드)
- [x] 1.4.8 SessionHistoryLoader - 손상 파일 복구 (유효 라인만 로드)

### 1.5 WebSocket API
- [x] 1.5.1 WebSocket 라우트 및 연결 관리
- [x] 1.5.2 토큰 기반 인증 - Authorization 헤더 검증, 401 응답
- [x] 1.5.3 메시지 수신 → CLI stdin 전달
- [x] 1.5.4 CLI stdout → 클라이언트 브로드캐스트
- [x] 1.5.5 연결 상태 동기화 - 초기 상태 전송, 상태 변경 브로드캐스트
- [x] 1.5.6 재연결 지원 - Ping/Pong, 연결 ID 유지, 히스토리 재전송
- [x] 1.5.7 에러 처리 - 지수 백오프 재연결, 버퍼 오버플로우 방지

### 1.6 대화형 프롬프트
- [x] 1.6.1 AskUserQuestion 감지 - tool_use 타입 필터링
- [x] 1.6.2 프롬프트 상태 관리 - 대기 중/응답됨/타임아웃
- [x] 1.6.3 응답 주입 - 선택 옵션 직렬화, stdin 전송
- [x] 1.6.4 타임아웃 처리 - 30분 대기, 만료 시 알림

### 1.7 서버 테스트
- [x] 1.7.1 ProcessRunner 단위 테스트 - 시작/종료, stdin/stdout
- [x] 1.7.2 JSONLParser 단위 테스트 - 타입 분류, 방어적 파싱
- [x] 1.7.3 SessionManager 단위 테스트 - CRUD, 상태 전환
- [x] 1.7.4 WebSocket 통합 테스트 - 연결, 인증, 메시지 전달
- [x] 1.7.5 에러 시나리오 테스트 - 크래시 복구, 타임아웃, 재연결

## 2. macOS App - 공통 컴포넌트

### 2.0 서버 통신 레이어
- [x] 2.0.1 WebSocketClient - 연결/해제, 메시지 송수신
- [x] 2.0.2 WebSocketClient - 자동 재연결 (지수 백오프)
- [x] 2.0.3 ConnectionManager - 연결 상태 모니터링, 상태 이벤트 발행
- [x] 2.0.4 MessageRouter - 수신 메시지 타입별 라우팅

### 2.1 앱 구조 설정
- [x] 2.1.1 앱 구조 - NavigationSplitView, 탭 구조
- [x] 2.1.2 앱 상태 관리 - @Observable 모델
- [x] 2.1.3 라우터 - 화면 전환, 딥링크 처리

### 2.2 프로젝트 브라우저
- [x] 2.2.1 프로젝트 목록 View
- [x] 2.2.2 프로젝트 카드 컴포넌트
- [x] 2.2.3 검색 - 이름 부분 문자열 매칭
- [x] 2.2.4 필터링 - 경로 기반, 최근 사용 순

### 2.3 세션 목록
- [x] 2.3.1 SessionListView - 활성 세션 표시
- [x] 2.3.2 SessionCard - 상태 뱃지, 프로젝트 이름, 마지막 메시지
- [x] 2.3.3 세션 전환 - 선택 시 채팅 뷰로 이동
- [x] 2.3.4 세션 관리 - 일시정지, 종료 액션

### 2.4 Section 2 E2E 테스트
- [x] 2.4.1 앱 실행 시 메인 뷰 표시 확인
- [x] 2.4.2 사이드바 탭 전환 테스트 (Projects ↔ Sessions ↔ Settings)
- [x] 2.4.3 프로젝트 목록 표시 및 검색 테스트
- [x] 2.4.4 프로젝트 선택 → 상세 뷰 전환 테스트
- [x] 2.4.5 세션 목록 표시 및 필터 테스트

### 2.5 리팩토링 (PR #4 리뷰 피드백)
> Section 3 시작 전 처리 권장

- [x] 2.5.1 ConnectionManager actor 변환 - class → actor, NSLock 제거
- [x] 2.5.2 ConnectionManager 이벤트 기반 상태 변경 - polling(100ms) → stateChanges 스트림
- [x] 2.5.3 ConnectionManagerProtocol 재설계 - actor 기반 인터페이스

## 3. macOS App - 채팅

### 3.1 메시지 표시
- [x] 3.1.1 MessageBubble - 사용자/어시스턴트 구분
- [x] 3.1.2 MessageList - 스크롤, 날짜 구분선
- [x] 3.1.3 스트리밍 메시지 표시 - 타이핑 인디케이터

### 3.2 코드 블록
- [x] 3.2.1 CodeBlockView - 기본 레이아웃, 언어 라벨, 라인 번호
- [x] 3.2.2 언어 감지 - 마크다운 fence 파싱, 확장자 기반 fallback
- [x] 3.2.3 향상된 신택스 하이라이팅 - 정규표현식 기반, 언어별 규칙 확장
  > Tree-sitter 통합은 Post-MVP로 연기 (Xcode 26.x SPM 빌드 버그 및 복잡성)
- [x] 3.2.4 언어별 하이라이팅 규칙 - Swift, JavaScript, Python, TypeScript, Go 등
- [x] 3.2.5 대용량 코드 처리 - LazyVStack 기반 최적화, 1,000줄 이상 지원
- [x] 3.2.6 복사 버튼 - 클립보드 복사, 완료 피드백 (2초)

### 3.3 입력 및 전송
- [x] 3.3.1 MessageInputView - 텍스트 입력, 여러 줄
- [x] 3.3.2 전송 로직 및 상태 표시

### 3.4 도구 사용 표시
- [x] 3.4.1 ToolUseView - 도구 이름, 파라미터
- [x] 3.4.2 ToolResultView - 결과, 접기/펼치기

### 3.5 에러 및 상태 알림
- [x] 3.5.1 ToastView - 일시적 알림 (3초 자동 해제)
- [x] 3.5.2 ErrorBanner - 지속 에러 표시 (수동 해제)
- [x] 3.5.3 ConnectionStatusBar - 연결 상태, 재연결 진행률

### 3.6 Section 3 E2E 테스트
> 모든 테스트 통과 (7개). accessibilityIdentifier 문제 해결됨:
> - SidebarPage: SwiftUI List(.sidebar)는 XCUITest에서 Outline 타입으로 렌더링
> - ChatPage: NavigationSplitView detail의 accessibilityIdentifier 전파 이슈 → text-based detection으로 우회
> - MessageInputView: TextEditor에 명시적 accessibilityIdentifier 추가
- [x] 3.6.1 메시지 전송 및 표시 테스트 ✅
- [x] 3.6.2 코드 블록 렌더링 테스트 ✅
- [x] 3.6.3 스트리밍 메시지 표시 테스트 ✅
- [x] 3.6.4 도구 사용 표시 테스트 ✅

## 4. macOS App - 파일 탐색기

### 4.1 디렉토리 트리
- [x] 4.1.1 FileTreeView - OutlineGroup 기반 트리 구조
- [x] 4.1.2 FileTreeNode - 확장/축소 상태 관리
- [x] 4.1.3 지연 로딩 - 폴더 확장 시 자식 노드만 로드
- [x] 4.1.4 가상화 - 1,000개 이상 항목 시 뷰포트 렌더링
- [x] 4.1.5 심볼릭 링크 처리 - 순환 참조 감지, 경고 표시
- [x] 4.1.6 깊이 제한 - 50레벨 초과 시 경고
- [x] 4.1.7 파일 타입별 아이콘 - SF Symbols 매핑

### 4.2 파일 뷰어
- [x] 4.2.1 FileContentView - 기본 텍스트 표시, 라인 번호
- [x] 4.2.2 신택스 하이라이팅 적용
- [x] 4.2.3 바이너리/대용량 파일 처리

### 4.3 Git 상태
- [x] 4.3.1 Git 상태 조회 서비스
- [x] 4.3.2 파일 트리에 상태 표시

### 4.4 파일 검색
- [x] 4.4.1 SearchField - 검색어 입력, 디바운싱 (300ms)
- [x] 4.4.2 파일명 검색 - 부분 문자열 매칭
- [x] 4.4.3 Fuzzy 매칭 - 약어 검색 지원 (예: "vc" → "ViewController")
- [x] 4.4.4 검색 결과 하이라이팅

### 4.5 Section 4 E2E 테스트
- [x] 4.5.1 디렉토리 트리 표시 및 탐색 테스트
- [x] 4.5.2 파일 선택 및 내용 표시 테스트
- [x] 4.5.3 파일 검색 테스트

## 5. macOS App - Diff 뷰어

### 5.1 Diff 파싱
- [x] 5.1.1 DiffDataSource - tool_result에서 diff 추출
- [x] 5.1.2 DiffDataSource - git diff 출력 감지 및 자동 표시
- [x] 5.1.3 UnifiedDiff 파서 - 파일 헤더 파싱 (--- / +++)
- [x] 5.1.4 UnifiedDiff 파서 - Hunk 추출 (@@ 패턴)
- [x] 5.1.5 DiffLine 모델 - 추가/삭제/컨텍스트 분류
- [x] 5.1.6 대용량 Diff 처리 - 100개 파일 초과 시 페이지네이션

### 5.2 Diff 표시
- [x] 5.2.1 DiffHunkView - 라인별 렌더링
- [x] 5.2.2 이중 라인 번호 표시
- [x] 5.2.3 Diff 내 신택스 하이라이팅

### 5.3 파일 목록
- [x] 5.3.1 DiffFileList - 파일별 그룹화
- [x] 5.3.2 통계 표시 - 추가/삭제 라인 수

### 5.4 Section 5 E2E 테스트
- [x] 5.4.1 Diff 뷰어 표시 테스트
- [x] 5.4.2 Hunk 탐색 테스트
- [x] 5.4.3 파일 목록 필터링 테스트

## 6. macOS App - 기타 UI

### 6.1 마크다운 뷰어
- [ ] 6.1.1 MarkdownUI 통합 및 스타일링

### 6.2 대화형 프롬프트 UI
- [ ] 6.2.1 PromptDialog - 질문 표시
- [ ] 6.2.2 옵션 버튼 및 멀티 셀렉트
- [ ] 6.2.3 직접 입력 필드

### 6.3 설정 화면
- [ ] 6.3.1 SettingsView - 서버, CLI 경로 설정
- [ ] 6.3.2 Keychain 토큰 관리

### 6.4 메뉴바
- [ ] 6.4.1 MenuBarExtra - 서버 상태 아이콘 (활성/비활성/오류)
- [ ] 6.4.2 상태 정보 표시 - 활성 세션 수, 연결된 클라이언트 수
- [ ] 6.4.3 빠른 액션 - 새 세션, 최근 프로젝트, 서버 시작/중지
- [ ] 6.4.4 서버 정보 - 주소 복사, 토큰 보기, QR 코드 생성
- [ ] 6.4.5 에러 알림 - 배지 표시, 리소스 경고

### 6.5 Section 6 E2E 테스트
- [ ] 6.5.1 마크다운 렌더링 테스트
- [ ] 6.5.2 대화형 프롬프트 UI 테스트
- [ ] 6.5.3 설정 화면 테스트
- [ ] 6.5.4 메뉴바 테스트

## 7. iOS App

### 7.1 서버 연결
- [ ] 7.1.1 ServerSettingsView - 주소/토큰 입력
- [ ] 7.1.2 연결 테스트 및 상태 표시
- [ ] 7.1.3 Bonjour 서버 발견
- [ ] 7.1.4 QR 코드 스캔 - 카메라 권한, 자동 연결
- [ ] 7.1.5 로컬 네트워크 권한 - NSLocalNetworkUsageDescription

### 7.2 모바일 UI 적응
- [ ] 7.2.1 탭 기반 네비게이션 구조
- [ ] 7.2.2 채팅 뷰 모바일 최적화 - 키보드 대응
- [ ] 7.2.3 코드 블록 - 가로 스크롤, 핀치 줌
- [ ] 7.2.4 파일/Diff 뷰어 모바일 레이아웃

### 7.3 네트워크 처리
- [ ] 7.3.1 연결 상태 모니터링 및 재연결
- [ ] 7.3.2 백그라운드/포그라운드 전환 처리

### 7.4 오프라인 처리
- [ ] 7.4.1 로컬 캐시 - 최근 세션 메시지 저장
- [ ] 7.4.2 오프라인 UI - 연결 불가 상태 표시
- [ ] 7.4.3 재연결 대기 - 진행률 표시, 수동 재시도 버튼

### 7.5 Section 7 E2E 테스트
- [ ] 7.5.1 서버 연결 및 QR 스캔 테스트
- [ ] 7.5.2 모바일 채팅 플로우 테스트
- [ ] 7.5.3 오프라인/재연결 테스트

## 8. 테스트 및 문서화

### 8.1 macOS 테스트
- [ ] 8.1.1 ViewModel 단위 테스트
- [ ] 8.1.2 View 스냅샷 테스트
- [ ] 8.1.3 통합 테스트 - Server + WebSocket + UI 연동
- [ ] 8.1.4 성능 테스트 - 메시지 처리량, 대용량 파일 로딩, 메모리 사용량
- [ ] 8.1.5 WebSocketClient 통합 테스트 - 로컬 WebSocket 서버 사용, 재연결/ping 로직 검증 (PR #4 리뷰 피드백)

### 8.2 iOS 테스트
- [ ] 8.2.1 iOS 통합 테스트
- [ ] 8.2.2 네트워크 시나리오 테스트 - 연결/해제/재연결

### 8.3 문서화
- [ ] 8.3.1 README - 설치 및 사용법
- [ ] 8.3.2 개발자 가이드

## Dependencies

```
1.1 → 1.2 → 1.3 → 1.4 → 1.5 → 1.6 (순차)
      ↓
2.1 → 2.2 (macOS 공통)
      ↓
┌─────┼─────┬─────┐
3.x   4.x   5.x   6.x (병렬 가능)
      ↓
     7.x (iOS, macOS 완료 후)
      ↓
     8.x (테스트/문서)
```
