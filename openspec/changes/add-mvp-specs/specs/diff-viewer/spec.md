# Diff Viewer

Git diff를 시각화하여 표시하는 기능입니다.

## ADDED Requirements

### Requirement: Diff Display
시스템은 Git diff를 시각적으로 표시해야 합니다(SHALL).

#### Scenario: Unified Diff 표시
- **GIVEN** Git diff 데이터 존재
- **WHEN** Diff 뷰어 열기
- **THEN** unified diff 형식으로 표시
- **AND** 추가/삭제/변경 라인 구분

#### Scenario: 추가된 라인 표시
- **GIVEN** diff에 추가된 라인 존재
- **WHEN** diff 렌더링
- **THEN** 녹색 배경으로 표시
- **AND** "+" 접두사 또는 추가 아이콘 표시

#### Scenario: 삭제된 라인 표시
- **GIVEN** diff에 삭제된 라인 존재
- **WHEN** diff 렌더링
- **THEN** 빨간색 배경으로 표시
- **AND** "-" 접두사 또는 삭제 아이콘 표시

#### Scenario: 변경되지 않은 컨텍스트 라인
- **GIVEN** diff에 컨텍스트 라인 존재
- **WHEN** diff 렌더링
- **THEN** 기본 배경으로 표시
- **AND** 라인 번호만 표시

### Requirement: Line Numbers
시스템은 diff에 라인 번호를 표시해야 합니다(SHALL).

#### Scenario: 이중 라인 번호
- **GIVEN** diff 표시 중
- **WHEN** 라인 번호 렌더링
- **THEN** 원본 파일 라인 번호와 새 파일 라인 번호 모두 표시

#### Scenario: 라인 번호 클릭
- **GIVEN** 라인 번호 표시 중
- **WHEN** 라인 번호 클릭
- **THEN** 해당 라인 선택/하이라이트

### Requirement: Hunk Grouping
시스템은 변경 사항을 Hunk 단위로 그룹화해야 합니다(SHALL).

#### Scenario: Hunk 구분
- **GIVEN** 여러 영역에 변경 존재
- **WHEN** diff 렌더링
- **THEN** 각 변경 영역(Hunk)을 시각적으로 구분
- **AND** Hunk 헤더 표시 (예: @@ -10,5 +10,7 @@)

#### Scenario: Hunk 접기/펼치기
- **GIVEN** Hunk 표시 중
- **WHEN** Hunk 헤더 클릭
- **THEN** 해당 Hunk 내용 접기/펼치기

### Requirement: File-level Grouping
시스템은 변경 사항을 파일별로 그룹화해야 합니다(SHALL).

#### Scenario: 파일별 diff 표시
- **GIVEN** 여러 파일에 변경 존재
- **WHEN** diff 목록 표시
- **THEN** 파일별로 그룹화하여 표시
- **AND** 각 파일의 변경 요약 (추가/삭제 라인 수)

#### Scenario: 파일 선택
- **GIVEN** 파일 목록 표시 중
- **WHEN** 파일 선택
- **THEN** 해당 파일의 diff만 상세 표시

#### Scenario: 파일 목록 정렬
- **GIVEN** 여러 파일의 변경 존재
- **WHEN** 파일 목록 표시
- **THEN** 파일 경로 기준 알파벳 순 정렬
- **OR** 변경량 순 정렬 옵션 제공

### Requirement: Syntax Highlighting in Diff
시스템은 diff 내 코드에 신택스 하이라이팅을 적용해야 합니다(SHALL).

#### Scenario: 코드 하이라이팅
- **GIVEN** 코드 파일의 diff 표시 중
- **WHEN** diff 렌더링
- **THEN** 파일 확장자에 맞는 신택스 하이라이팅 적용
- **AND** 추가/삭제 배경색과 조화롭게 표시

#### Scenario: 지원되지 않는 언어
- **GIVEN** Tree-sitter 미지원 언어의 파일
- **WHEN** diff 렌더링
- **THEN** 하이라이팅 없이 일반 텍스트로 표시

### Requirement: Diff Navigation
시스템은 diff 내 탐색 기능을 제공해야 합니다(SHALL).

#### Scenario: 다음/이전 변경으로 이동
- **GIVEN** diff 표시 중
- **WHEN** 다음/이전 버튼 클릭 또는 단축키
- **THEN** 다음/이전 변경 영역으로 스크롤

#### Scenario: 파일 간 이동
- **GIVEN** 여러 파일의 diff 존재
- **WHEN** 다음/이전 파일 탐색
- **THEN** 다음/이전 파일의 diff로 이동

### Requirement: Diff Statistics
시스템은 diff 통계를 표시해야 합니다(SHALL).

#### Scenario: 전체 통계 표시
- **GIVEN** diff 데이터 로드됨
- **WHEN** diff 뷰어 열기
- **THEN** 전체 변경 파일 수 표시
- **AND** 전체 추가/삭제 라인 수 표시

#### Scenario: 파일별 통계 표시
- **GIVEN** 파일별 diff 목록 표시 중
- **WHEN** 파일 항목 렌더링
- **THEN** 해당 파일의 추가/삭제 라인 수 표시
