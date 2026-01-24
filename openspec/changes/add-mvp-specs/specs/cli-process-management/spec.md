# CLI Process Management

Claude Code CLI를 subprocess로 실행하고 관리하는 기능입니다.

## ADDED Requirements

### Requirement: CLI Process Lifecycle
시스템은 Claude Code CLI 프로세스의 생명주기를 관리해야 합니다(SHALL).

#### Scenario: CLI 프로세스 시작
- **GIVEN** 유효한 프로젝트 경로가 선택됨
- **WHEN** 세션 시작 요청
- **THEN** `claude` CLI를 해당 프로젝트 디렉토리에서 subprocess로 실행
- **AND** stdin, stdout, stderr 파이프가 연결됨

#### Scenario: CLI 프로세스 종료
- **GIVEN** 실행 중인 CLI 프로세스가 있음
- **WHEN** 세션 종료 요청
- **THEN** CLI 프로세스에 SIGTERM 전송
- **AND** 5초 내 종료되지 않으면 SIGKILL 전송

#### Scenario: CLI 프로세스 재시작
- **GIVEN** 실행 중인 CLI 프로세스가 있음
- **WHEN** 재시작 요청
- **THEN** 기존 프로세스 종료 후 새 프로세스 시작
- **AND** 동일한 프로젝트 컨텍스트 유지

### Requirement: stdin/stdout Streaming
시스템은 CLI의 표준 입출력을 실시간으로 처리해야 합니다(SHALL).

#### Scenario: stdout 스트리밍 수신
- **GIVEN** CLI 프로세스가 실행 중
- **WHEN** CLI가 stdout으로 데이터 출력
- **THEN** 100ms 이내에 데이터 수신
- **AND** 라인 단위로 버퍼링하여 파서에 전달

#### Scenario: stdin 메시지 전송
- **GIVEN** CLI 프로세스가 실행 중
- **WHEN** 사용자 메시지 전송 요청
- **THEN** 메시지를 CLI stdin에 작성
- **AND** 줄바꿈 문자로 종료

#### Scenario: stderr 캡처
- **GIVEN** CLI 프로세스가 실행 중
- **WHEN** CLI가 stderr로 에러 출력
- **THEN** 에러 메시지 캡처
- **AND** 로그에 기록

### Requirement: Multiple Session Support
시스템은 여러 프로젝트의 CLI 세션을 동시에 관리할 수 있어야 합니다(SHALL).

#### Scenario: 다중 세션 생성
- **GIVEN** 프로젝트 A에서 세션 실행 중
- **WHEN** 프로젝트 B에서 새 세션 시작 요청
- **THEN** 프로젝트 B의 CLI 프로세스가 별도로 시작
- **AND** 두 세션이 독립적으로 동작

#### Scenario: 세션 수 제한
- **GIVEN** 동시에 5개 세션이 실행 중
- **WHEN** 새 세션 시작 요청
- **THEN** 세션 수 초과 에러 반환
- **OR** 가장 오래된 유휴 세션 종료 후 새 세션 시작

### Requirement: CLI Path Configuration
시스템은 Claude CLI 경로를 설정할 수 있어야 합니다(SHALL).

#### Scenario: 기본 경로 사용
- **GIVEN** 사용자가 CLI 경로를 설정하지 않음
- **WHEN** 세션 시작
- **THEN** `/usr/local/bin/claude` 경로 사용

#### Scenario: 사용자 정의 경로
- **GIVEN** 사용자가 CLI 경로를 `/opt/bin/claude`로 설정
- **WHEN** 세션 시작
- **THEN** 설정된 경로의 CLI 실행

#### Scenario: CLI 미설치 감지
- **GIVEN** 설정된 경로에 CLI가 존재하지 않음
- **WHEN** 세션 시작
- **THEN** "Claude CLI not found" 에러 반환
- **AND** 설치 안내 메시지 표시
