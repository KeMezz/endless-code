# Interactive Prompts

CLI의 대화형 프롬프트(AskUserQuestion 등)를 GUI에서 처리하는 기능입니다.

## ADDED Requirements

### Requirement: Interactive Prompt Detection
시스템은 CLI의 대화형 프롬프트를 감지하고 클라이언트에 전달해야 합니다(SHALL).

#### Scenario: AskUserQuestion 프롬프트 감지
- **GIVEN** CLI가 tool_use로 AskUserQuestion 출력
- **WHEN** JSONL 파서가 처리
- **THEN** 대화형 프롬프트 이벤트 생성
- **AND** WebSocket을 통해 클라이언트에 전달

#### Scenario: 질문 데이터 추출
- **GIVEN** AskUserQuestion 메시지 수신
- **WHEN** 파싱 완료
- **THEN** `question` 텍스트 추출
- **AND** `options` 배열 추출 (있는 경우)
- **AND** `multiSelect` 플래그 추출

### Requirement: User Response Injection
시스템은 사용자의 응답을 CLI stdin에 주입해야 합니다(SHALL).

#### Scenario: 단일 선택 응답
- **GIVEN** 대화형 프롬프트가 단일 선택 요구
- **WHEN** 사용자가 옵션 선택
- **THEN** 선택된 옵션의 값을 CLI stdin에 작성
- **AND** CLI가 즉시 진행

#### Scenario: 다중 선택 응답
- **GIVEN** 대화형 프롬프트가 다중 선택 허용
- **WHEN** 사용자가 여러 옵션 선택
- **THEN** 선택된 옵션들을 적절한 형식으로 CLI stdin에 작성
- **AND** CLI가 즉시 진행

#### Scenario: 직접 입력 응답
- **GIVEN** 대화형 프롬프트에 "Other" 옵션 존재
- **WHEN** 사용자가 직접 텍스트 입력
- **THEN** 입력된 텍스트를 CLI stdin에 작성
- **AND** CLI가 즉시 진행

### Requirement: Timeout Handling
시스템은 대화형 프롬프트의 타임아웃을 처리해야 합니다(SHALL).

#### Scenario: 응답 타임아웃
- **GIVEN** 대화형 프롬프트 대기 중
- **WHEN** 30분 동안 응답 없음
- **THEN** 타임아웃 이벤트 발생
- **AND** 세션 상태를 "응답 대기 만료"로 변경
- **AND** 클라이언트에 타임아웃 알림

#### Scenario: 타임아웃 후 재시도
- **GIVEN** 대화형 프롬프트가 타임아웃됨
- **WHEN** 사용자가 응답 제출
- **THEN** "타임아웃됨" 에러 반환
- **AND** 세션 재시작 안내

### Requirement: Prompt UI Rendering
클라이언트는 대화형 프롬프트를 적절한 UI로 렌더링해야 합니다(SHALL).

#### Scenario: 객관식 옵션 렌더링
- **GIVEN** 대화형 프롬프트에 옵션 목록 존재
- **WHEN** UI 렌더링
- **THEN** 각 옵션을 클릭 가능한 버튼으로 표시
- **AND** 옵션 설명이 있으면 함께 표시

#### Scenario: 멀티 셀렉트 렌더링
- **GIVEN** 대화형 프롬프트가 다중 선택 허용
- **WHEN** UI 렌더링
- **THEN** 체크박스 형태로 옵션 표시
- **AND** 제출 버튼 별도 표시

#### Scenario: 직접 입력 필드 렌더링
- **GIVEN** 대화형 프롬프트에 직접 입력 옵션 존재
- **WHEN** UI 렌더링
- **THEN** 텍스트 입력 필드 표시
- **AND** 입력 후 제출 버튼 활성화
