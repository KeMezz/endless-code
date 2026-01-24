# Chat Interface

대화형 메시지 송수신 UI를 제공하는 기능입니다.

## ADDED Requirements

### Requirement: Message Display
시스템은 대화 메시지를 적절한 형태로 표시해야 합니다(SHALL).

#### Scenario: 사용자 메시지 표시
- **GIVEN** 사용자가 메시지 전송
- **WHEN** 메시지 전송 완료
- **THEN** 메시지를 오른쪽 정렬, 파란색 배경으로 표시
- **AND** 전송 시간 표시

#### Scenario: 어시스턴트 메시지 표시
- **GIVEN** Claude로부터 응답 수신
- **WHEN** 메시지 파싱 완료
- **THEN** 메시지를 왼쪽 정렬, 회색 배경으로 표시
- **AND** 수신 시간 표시

#### Scenario: 실시간 스트리밍 표시
- **GIVEN** Claude가 응답 생성 중
- **WHEN** 부분 응답 수신
- **THEN** 실시간으로 텍스트 추가 표시
- **AND** 타이핑 인디케이터 표시

### Requirement: Code Block Rendering
시스템은 코드 블록을 신택스 하이라이팅과 함께 표시해야 합니다(SHALL).

#### Scenario: 코드 블록 감지
- **GIVEN** 메시지에 마크다운 코드 블록 포함
- **WHEN** 메시지 렌더링
- **THEN** 코드 블록을 별도 영역으로 분리
- **AND** 다크 배경 적용

#### Scenario: 언어별 하이라이팅
- **GIVEN** 코드 블록에 언어 명시 (예: ```swift)
- **WHEN** 코드 블록 렌더링
- **THEN** 해당 언어의 Tree-sitter 문법으로 하이라이팅
- **AND** 언어 이름을 코드 블록 우측 상단에 표시

#### Scenario: 코드 복사
- **GIVEN** 코드 블록 표시 중
- **WHEN** 복사 버튼 클릭
- **THEN** 코드 내용을 클립보드에 복사
- **AND** 복사 완료 피드백 표시

### Requirement: Markdown Rendering
시스템은 마크다운 콘텐츠를 렌더링해야 합니다(SHALL).

#### Scenario: 기본 마크다운 렌더링
- **GIVEN** 메시지에 마크다운 문법 포함
- **WHEN** 메시지 렌더링
- **THEN** GitHub 스타일 마크다운으로 렌더링
- **AND** 헤딩, 리스트, 볼드, 이탤릭 등 지원

#### Scenario: 링크 처리
- **GIVEN** 메시지에 URL 포함
- **WHEN** 메시지 렌더링
- **THEN** 클릭 가능한 링크로 표시
- **AND** 클릭 시 기본 브라우저에서 열기

#### Scenario: 테이블 렌더링
- **GIVEN** 메시지에 마크다운 테이블 포함
- **WHEN** 메시지 렌더링
- **THEN** 적절한 테이블 형태로 표시
- **AND** 가로 스크롤 지원 (필요 시)

### Requirement: Message Input
시스템은 메시지 입력 및 전송 기능을 제공해야 합니다(SHALL).

#### Scenario: 텍스트 입력
- **GIVEN** 채팅 화면 표시 중
- **WHEN** 입력 필드에 텍스트 입력
- **THEN** 실시간으로 텍스트 반영
- **AND** 여러 줄 입력 지원

#### Scenario: 메시지 전송
- **GIVEN** 입력 필드에 텍스트 존재
- **WHEN** Enter 키 또는 전송 버튼 클릭
- **THEN** 메시지를 서버로 전송
- **AND** 입력 필드 초기화
- **AND** 전송 중 인디케이터 표시

#### Scenario: 빈 메시지 방지
- **GIVEN** 입력 필드가 비어있거나 공백만 존재
- **WHEN** 전송 시도
- **THEN** 전송 차단
- **AND** 전송 버튼 비활성화 상태 유지

### Requirement: Timestamp Display
시스템은 메시지 타임스탬프를 표시해야 합니다(SHALL).

#### Scenario: 상대 시간 표시
- **GIVEN** 메시지 수신 후 1시간 이내
- **WHEN** 타임스탬프 표시
- **THEN** "방금", "5분 전", "30분 전" 형식으로 표시

#### Scenario: 절대 시간 표시
- **GIVEN** 메시지 수신 후 1시간 이상
- **WHEN** 타임스탬프 표시
- **THEN** "오늘 14:30", "어제 09:15" 형식으로 표시

#### Scenario: 날짜 구분선
- **GIVEN** 다른 날짜의 메시지가 연속
- **WHEN** 메시지 목록 렌더링
- **THEN** 날짜 구분선 삽입 ("2026년 1월 25일")

### Requirement: Tool Use Display
시스템은 도구 사용 내역을 표시해야 합니다(SHALL).

#### Scenario: 도구 사용 요청 표시
- **GIVEN** Claude가 tool_use 메시지 전송
- **WHEN** 메시지 렌더링
- **THEN** 도구 이름과 입력 파라미터 표시
- **AND** 접을 수 있는 상세 정보 영역 제공

#### Scenario: 도구 결과 표시
- **GIVEN** tool_result 메시지 수신
- **WHEN** 메시지 렌더링
- **THEN** 도구 실행 결과 표시
- **AND** 성공/실패 상태 시각적 표시
