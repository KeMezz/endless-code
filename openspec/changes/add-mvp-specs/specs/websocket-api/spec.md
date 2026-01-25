# WebSocket API

클라이언트와 서버 간 실시간 양방향 통신을 제공하는 WebSocket API입니다.

## ADDED Requirements

### Requirement: WebSocket Connection
시스템은 WebSocket 연결을 통해 클라이언트와 실시간 통신해야 합니다(SHALL).

#### Scenario: WebSocket 연결 수립
- **GIVEN** 클라이언트가 서버에 WebSocket 연결 요청
- **WHEN** 유효한 API 토큰 제공
- **THEN** WebSocket 연결 수립
- **AND** 연결 성공 메시지 전송

#### Scenario: 인증 실패
- **GIVEN** 클라이언트가 WebSocket 연결 요청
- **WHEN** 유효하지 않은 API 토큰 제공
- **THEN** 연결 거부
- **AND** 401 Unauthorized 응답

#### Scenario: 연결 해제
- **GIVEN** 활성 WebSocket 연결
- **WHEN** 클라이언트가 연결 종료
- **THEN** 서버에서 연결 정리
- **AND** 관련 리소스 해제

### Requirement: Message Streaming
시스템은 CLI 출력을 실시간으로 클라이언트에 스트리밍해야 합니다(SHALL).

#### Scenario: 메시지 실시간 전송
- **GIVEN** CLI가 새 메시지 출력
- **WHEN** JSONL 파서가 메시지 처리 완료
- **THEN** 50ms 이내에 연결된 모든 클라이언트에 전송

#### Scenario: 대용량 메시지 분할
- **GIVEN** CLI가 큰 메시지 출력 (>64KB)
- **WHEN** 메시지 전송
- **THEN** 적절한 크기로 분할하여 전송
- **AND** 클라이언트에서 재조립 가능

#### Scenario: 전송 실패 처리
- **GIVEN** 클라이언트에 메시지 전송 중
- **WHEN** 네트워크 오류 발생
- **THEN** 재전송 시도 (최대 3회)
- **AND** 실패 시 연결 종료 및 로그 기록

### Requirement: User Input Forwarding
시스템은 클라이언트의 입력을 CLI stdin으로 전달해야 합니다(SHALL).

#### Scenario: 사용자 메시지 전달
- **GIVEN** WebSocket 연결 활성
- **WHEN** 클라이언트가 사용자 메시지 전송
- **THEN** 해당 세션의 CLI stdin에 메시지 작성
- **AND** 확인 응답 전송

#### Scenario: 대화형 프롬프트 응답 전달
- **GIVEN** 대화형 프롬프트 대기 중
- **WHEN** 클라이언트가 선택 응답 전송
- **THEN** 응답을 CLI stdin에 주입
- **AND** CLI 진행 재개

### Requirement: Session State Synchronization
시스템은 세션 상태를 클라이언트와 동기화해야 합니다(SHALL).

#### Scenario: 초기 상태 동기화
- **GIVEN** 새 WebSocket 연결 수립
- **WHEN** 연결 완료
- **THEN** 현재 세션 상태 전송 (활성 세션 목록, 각 세션 상태)

#### Scenario: 상태 변경 브로드캐스트
- **GIVEN** 세션 상태 변경 (시작/종료/에러)
- **WHEN** 상태 변경 감지
- **THEN** 연결된 모든 클라이언트에 상태 업데이트 전송

#### Scenario: 재연결 시 동기화
- **GIVEN** 클라이언트가 연결 끊김 후 재연결
- **WHEN** 재연결 성공
- **THEN** 끊어진 동안의 메시지 히스토리 전송 (최근 100개)
- **AND** 현재 상태 동기화

### Requirement: Auto Reconnection Support
시스템은 클라이언트의 자동 재연결을 지원해야 합니다(SHALL).

#### Scenario: Ping/Pong 핸들링
- **GIVEN** 활성 WebSocket 연결
- **WHEN** 30초간 활동 없음
- **THEN** Ping 프레임 전송
- **AND** 10초 내 Pong 미수신 시 연결 종료

#### Scenario: 연결 ID 유지
- **GIVEN** 클라이언트가 재연결
- **WHEN** 이전 연결 ID 제공
- **THEN** 이전 세션 컨텍스트 복원
- **AND** 중단된 지점부터 재개

### Requirement: Error Handling
시스템은 네트워크 및 프로토콜 오류를 처리해야 합니다(SHALL).

#### Scenario: 네트워크 연결 끊김
- **GIVEN** 활성 WebSocket 연결
- **WHEN** 네트워크 연결이 끊김 (TCP RST, 타임아웃 등)
- **THEN** 연결 상태를 "disconnected"로 변경
- **AND** 지수 백오프로 재연결 시도 (1s, 2s, 4s, ... 최대 60s)
- **AND** 최대 10회 재시도 후 "연결 실패" 알림

#### Scenario: 서버 과부하
- **GIVEN** 클라이언트가 연결 요청
- **WHEN** 서버의 동시 연결 수가 한계 도달 (100개)
- **THEN** 503 Service Unavailable 응답
- **AND** Retry-After 헤더에 권장 재시도 시간 포함

#### Scenario: 메시지 형식 오류
- **GIVEN** 활성 WebSocket 연결
- **WHEN** 클라이언트가 잘못된 JSON 형식 전송
- **THEN** 에러 메시지 응답 (type: "error", code: "invalid_format")
- **AND** 연결은 유지
- **AND** 에러 로그 기록

#### Scenario: 세션 ID 불일치
- **GIVEN** 클라이언트가 메시지 전송
- **WHEN** 지정된 sessionId가 존재하지 않거나 권한 없음
- **THEN** 에러 메시지 응답 (type: "error", code: "session_not_found")
- **AND** 유효한 세션 목록 함께 전송

#### Scenario: 메시지 버퍼 오버플로우
- **GIVEN** 클라이언트 연결 끊김 중 메시지 누적
- **WHEN** 버퍼 크기가 10MB 초과
- **THEN** 오래된 메시지부터 삭제
- **AND** 재연결 시 "일부 메시지 손실" 경고 전송

#### Scenario: 토큰 만료
- **GIVEN** 활성 WebSocket 연결
- **WHEN** 서버에서 토큰 무효화 (재생성 등)
- **THEN** 에러 메시지 전송 (type: "error", code: "token_expired")
- **AND** 연결 종료
- **AND** 클라이언트에 재인증 요청
