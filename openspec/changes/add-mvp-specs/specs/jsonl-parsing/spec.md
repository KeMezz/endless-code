# JSONL Parsing

Claude Code CLI의 JSONL 출력을 실시간으로 파싱하는 기능입니다.

## ADDED Requirements

### Requirement: Streaming JSONL Parser
시스템은 CLI stdout에서 JSONL 데이터를 실시간으로 파싱해야 합니다(SHALL).

#### Scenario: 유효한 JSONL 라인 파싱
- **GIVEN** CLI가 stdout으로 JSONL 라인 출력
- **WHEN** 완전한 JSON 라인 수신
- **THEN** 10ms 이내에 파싱 완료
- **AND** 해당 메시지 타입의 객체로 변환

#### Scenario: 불완전한 라인 처리
- **GIVEN** stdout에서 부분적인 JSON 데이터 수신
- **WHEN** 줄바꿈 문자가 아직 수신되지 않음
- **THEN** 버퍼에 데이터 보관
- **AND** 완전한 라인이 될 때까지 대기

#### Scenario: 잘못된 JSON 처리
- **GIVEN** stdout에서 잘못된 JSON 형식의 라인 수신
- **WHEN** JSON 파싱 시도
- **THEN** 파싱 에러 로깅
- **AND** 해당 라인 스킵 후 다음 라인 처리 계속
- **AND** 서비스 중단 없음

### Requirement: Message Type Classification
시스템은 파싱된 메시지를 타입별로 분류해야 합니다(SHALL).

#### Scenario: message 타입 분류
- **GIVEN** 파싱된 JSON 객체
- **WHEN** `type` 필드가 `message`
- **THEN** `ChatMessage` 객체로 변환
- **AND** `role`, `content` 필드 추출

#### Scenario: tool_use 타입 분류
- **GIVEN** 파싱된 JSON 객체
- **WHEN** `type` 필드가 `tool_use`
- **THEN** `ToolUseMessage` 객체로 변환
- **AND** `tool_name`, `tool_input` 필드 추출

#### Scenario: tool_result 타입 분류
- **GIVEN** 파싱된 JSON 객체
- **WHEN** `type` 필드가 `tool_result`
- **THEN** `ToolResultMessage` 객체로 변환
- **AND** `tool_use_id`, `output` 필드 추출

#### Scenario: 알 수 없는 타입 처리
- **GIVEN** 파싱된 JSON 객체
- **WHEN** `type` 필드가 알려지지 않은 값
- **THEN** `GenericMessage` 객체로 변환
- **AND** 원본 JSON 데이터 보존

### Requirement: Defensive Parsing
시스템은 스키마 변경에 대응하는 방어적 파싱을 수행해야 합니다(SHALL).

#### Scenario: 누락된 필드 처리
- **GIVEN** 파싱된 JSON 객체에 필수 필드 누락
- **WHEN** 객체 변환 시도
- **THEN** 기본값 또는 nil로 해당 필드 설정
- **AND** 경고 로그 기록

#### Scenario: 추가 필드 무시
- **GIVEN** 파싱된 JSON 객체에 알려지지 않은 필드 존재
- **WHEN** 객체 변환
- **THEN** 추가 필드 무시하고 변환 완료
- **AND** 에러 발생하지 않음

#### Scenario: 타입 불일치 처리
- **GIVEN** 파싱된 JSON 객체의 필드 타입이 예상과 다름
- **WHEN** 객체 변환 시도
- **THEN** 타입 변환 시도 (예: 문자열 → 숫자)
- **OR** 변환 실패 시 기본값 사용

### Requirement: Interactive Prompt Detection
시스템은 대화형 프롬프트 메시지를 감지해야 합니다(SHALL).

#### Scenario: AskUserQuestion 감지
- **GIVEN** 파싱된 JSON 객체
- **WHEN** tool_use 타입이고 `tool_name`이 `AskUserQuestion`
- **THEN** 대화형 프롬프트 이벤트 발생
- **AND** `question`, `options` 필드 추출

#### Scenario: 확인 요청 감지
- **GIVEN** 파싱된 JSON 객체
- **WHEN** 사용자 확인이 필요한 메시지
- **THEN** 확인 요청 이벤트 발생
- **AND** 관련 컨텍스트 정보 포함

### Requirement: Error Handling
시스템은 파싱 오류 및 예외 상황을 처리해야 합니다(SHALL).

#### Scenario: 대용량 JSON 라인 처리
- **GIVEN** CLI가 stdout으로 출력
- **WHEN** 단일 라인이 1MB 초과
- **THEN** 메모리 제한을 위해 청크 단위로 파싱
- **AND** 1MB 초과 시 "large_message" 플래그 설정
- **AND** UI에서 "접기" 상태로 표시 권장

#### Scenario: 인코딩 오류
- **GIVEN** stdout에서 데이터 수신
- **WHEN** 유효하지 않은 UTF-8 시퀀스 발견
- **THEN** 해당 바이트 대체 문자(�)로 변환
- **AND** 인코딩 경고 로그 기록
- **AND** 파싱 계속 진행

#### Scenario: 버퍼 오버플로우 방지
- **GIVEN** 불완전한 라인이 버퍼에 누적
- **WHEN** 버퍼 크기가 10MB 초과 (줄바꿈 없이)
- **THEN** 현재 버퍼 내용 폐기
- **AND** "buffer_overflow" 에러 로그 기록
- **AND** 다음 줄바꿈부터 다시 파싱 시작

#### Scenario: 타임스탬프 형식 불일치
- **GIVEN** 파싱된 JSON에 timestamp 필드 존재
- **WHEN** ISO8601 형식이 아닌 경우
- **THEN** 여러 형식으로 파싱 시도 (Unix epoch, RFC2822)
- **AND** 모두 실패 시 현재 시간으로 대체
- **AND** 경고 로그 기록

#### Scenario: 스키마 버전 불일치
- **GIVEN** 파싱된 JSON에 version 필드 존재
- **WHEN** 지원하지 않는 버전인 경우
- **THEN** 최선 노력 파싱 (best-effort parsing)
- **AND** "unsupported_version" 경고 발생
- **AND** 사용자에게 앱 업데이트 권장

#### Scenario: 연속 파싱 실패
- **GIVEN** JSONL 스트림 파싱 중
- **WHEN** 연속 10개 라인 파싱 실패
- **THEN** "stream_corrupted" 에러 발생
- **AND** CLI 프로세스 상태 확인 요청
- **AND** 스트림 재초기화 시도
