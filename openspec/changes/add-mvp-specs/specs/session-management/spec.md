# Session Management

프로젝트 및 세션의 생명주기를 관리하는 기능입니다.

## ADDED Requirements

### Requirement: Project Discovery
시스템은 Claude Code 프로젝트를 자동으로 발견해야 합니다(SHALL).

#### Scenario: 프로젝트 디렉토리 스캔
- **GIVEN** 앱 실행 또는 새로고침 요청
- **WHEN** 프로젝트 목록 조회
- **THEN** `~/.claude/projects/` 디렉토리 스캔
- **AND** 유효한 프로젝트 목록 반환

#### Scenario: 프로젝트 메타데이터 추출
- **GIVEN** 프로젝트 디렉토리 발견
- **WHEN** 프로젝트 정보 로드
- **THEN** 프로젝트 이름 추출
- **AND** 프로젝트 경로 기록
- **AND** 세션 수 계산

#### Scenario: 유효하지 않은 프로젝트 필터링
- **GIVEN** `~/.claude/projects/` 디렉토리에 항목 존재
- **WHEN** 유효한 Claude 프로젝트가 아닌 경우
- **THEN** 프로젝트 목록에서 제외
- **AND** 경고 로그 기록

### Requirement: Session History Loading
시스템은 프로젝트의 과거 세션 히스토리를 로드해야 합니다(SHALL).

#### Scenario: 세션 파일 로드
- **GIVEN** 프로젝트 선택됨
- **WHEN** 세션 목록 요청
- **THEN** `~/.claude/projects/<project>/.claude/sessions/` 디렉토리 스캔
- **AND** JSONL 세션 파일 목록 반환

#### Scenario: 세션 대화 복원
- **GIVEN** 세션 파일 선택됨
- **WHEN** 세션 상세 정보 요청
- **THEN** JSONL 파일 파싱
- **AND** 과거 대화 메시지 복원

#### Scenario: 대용량 세션 처리
- **GIVEN** 세션 파일이 10,000개 이상의 메시지 포함
- **WHEN** 세션 로드
- **THEN** 최근 1,000개 메시지만 초기 로드
- **AND** 이전 메시지는 요청 시 페이지네이션으로 로드

### Requirement: Session Lifecycle
시스템은 활성 세션의 생명주기를 관리해야 합니다(SHALL).

#### Scenario: 새 세션 시작
- **GIVEN** 프로젝트 선택됨
- **WHEN** 새 세션 시작 요청
- **THEN** 고유한 세션 ID 생성
- **AND** CLI 프로세스 시작
- **AND** 세션 상태 "active"로 설정

#### Scenario: 세션 재개
- **GIVEN** 이전 세션이 존재
- **WHEN** 세션 재개 요청
- **THEN** 해당 세션의 컨텍스트로 CLI 시작
- **AND** 이전 대화 히스토리 복원

#### Scenario: 세션 일시 정지
- **GIVEN** 활성 세션 존재
- **WHEN** 세션 일시 정지 요청
- **THEN** CLI 프로세스 유지
- **AND** 세션 상태 "paused"로 변경

#### Scenario: 세션 종료
- **GIVEN** 활성 또는 일시 정지된 세션 존재
- **WHEN** 세션 종료 요청
- **THEN** CLI 프로세스 종료
- **AND** 세션 상태 "terminated"로 변경
- **AND** 세션 데이터 보존

### Requirement: Recent Projects
시스템은 최근 사용 프로젝트를 추적해야 합니다(SHALL).

#### Scenario: 최근 사용 기록
- **GIVEN** 사용자가 프로젝트에서 세션 시작
- **WHEN** 세션 시작됨
- **THEN** 해당 프로젝트를 최근 사용 목록에 추가
- **AND** 마지막 사용 시간 기록

#### Scenario: 최근 프로젝트 정렬
- **GIVEN** 프로젝트 목록 조회
- **WHEN** 최근 사용 순 정렬 요청
- **THEN** 마지막 사용 시간 기준 내림차순 정렬

### Requirement: Project Search
시스템은 프로젝트 검색 및 필터링을 지원해야 합니다(SHALL).

#### Scenario: 이름으로 검색
- **GIVEN** 프로젝트 목록 표시 중
- **WHEN** 검색어 입력
- **THEN** 프로젝트 이름에 검색어 포함된 항목만 표시

#### Scenario: 경로로 필터링
- **GIVEN** 프로젝트 목록 표시 중
- **WHEN** 경로 필터 적용
- **THEN** 해당 경로 하위의 프로젝트만 표시
