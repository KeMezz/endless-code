# File Explorer

프로젝트 디렉토리를 탐색하고 파일 내용을 표시하는 기능입니다.

## ADDED Requirements

### Requirement: Directory Tree Display
시스템은 프로젝트 디렉토리를 트리 구조로 표시해야 합니다(SHALL).

#### Scenario: 루트 디렉토리 로드
- **GIVEN** 프로젝트 선택됨
- **WHEN** 파일 탐색기 열기
- **THEN** 프로젝트 루트 디렉토리의 항목 표시
- **AND** 디렉토리와 파일을 구분하여 표시

#### Scenario: 디렉토리 확장
- **GIVEN** 접힌 상태의 디렉토리
- **WHEN** 디렉토리 클릭 또는 확장 아이콘 클릭
- **THEN** 하위 항목 로드 및 표시
- **AND** 확장 상태로 아이콘 변경

#### Scenario: 디렉토리 축소
- **GIVEN** 확장된 상태의 디렉토리
- **WHEN** 디렉토리 클릭 또는 축소 아이콘 클릭
- **THEN** 하위 항목 숨김
- **AND** 축소 상태로 아이콘 변경

#### Scenario: 대용량 디렉토리 처리
- **GIVEN** 디렉토리에 1,000개 이상 항목 존재
- **WHEN** 디렉토리 확장
- **THEN** 처음 100개 항목만 로드
- **AND** "더 보기" 옵션 표시

### Requirement: File Icon Display
시스템은 파일 타입에 따른 아이콘을 표시해야 합니다(SHALL).

#### Scenario: 파일 확장자별 아이콘
- **GIVEN** 파일 목록 표시 중
- **WHEN** 파일 렌더링
- **THEN** 확장자에 따른 아이콘 표시 (예: .swift → Swift 아이콘)

#### Scenario: 디렉토리 아이콘
- **GIVEN** 디렉토리 표시 중
- **WHEN** 디렉토리 렌더링
- **THEN** 확장/축소 상태에 따른 폴더 아이콘 표시

#### Scenario: 특수 파일 아이콘
- **GIVEN** 특수 파일 (예: .gitignore, README.md)
- **WHEN** 파일 렌더링
- **THEN** 해당 파일 타입의 특수 아이콘 표시

### Requirement: File Content Viewer
시스템은 파일 내용을 읽기 전용으로 표시해야 합니다(SHALL).

#### Scenario: 텍스트 파일 표시
- **GIVEN** 텍스트 파일 선택
- **WHEN** 파일 뷰어 열기
- **THEN** 파일 내용 표시
- **AND** 라인 번호 표시

#### Scenario: 신택스 하이라이팅
- **GIVEN** 코드 파일 선택 (예: .swift, .ts, .py)
- **WHEN** 파일 뷰어 열기
- **THEN** Tree-sitter로 신택스 하이라이팅 적용
- **AND** 테마에 맞는 색상 적용

#### Scenario: 바이너리 파일 처리
- **GIVEN** 바이너리 파일 선택 (예: .png, .exe)
- **WHEN** 파일 뷰어 열기
- **THEN** "바이너리 파일입니다" 메시지 표시
- **AND** 파일 크기 및 타입 정보 표시

#### Scenario: 대용량 파일 처리
- **GIVEN** 파일 크기가 1MB 이상
- **WHEN** 파일 선택
- **THEN** "대용량 파일입니다" 경고 표시
- **AND** 사용자 확인 후 로드 또는 부분 로드 옵션 제공

### Requirement: File Search
시스템은 파일 이름으로 검색을 지원해야 합니다(SHALL).

#### Scenario: 파일 이름 검색
- **GIVEN** 파일 탐색기 표시 중
- **WHEN** 검색어 입력
- **THEN** 파일 이름에 검색어 포함된 항목 필터링
- **AND** 매칭된 부분 하이라이트

#### Scenario: 검색 결과 없음
- **GIVEN** 검색어 입력됨
- **WHEN** 매칭되는 파일 없음
- **THEN** "검색 결과 없음" 메시지 표시

### Requirement: Git Status Integration
시스템은 파일의 Git 상태를 표시해야 합니다(SHALL).

#### Scenario: 변경된 파일 표시
- **GIVEN** Git 저장소 내 파일
- **WHEN** 파일이 수정됨 (modified)
- **THEN** 파일 이름 옆에 변경 표시 (예: M 아이콘 또는 색상)

#### Scenario: 새 파일 표시
- **GIVEN** Git 저장소 내 파일
- **WHEN** 파일이 추적되지 않음 (untracked)
- **THEN** 파일 이름 옆에 새 파일 표시 (예: U 아이콘 또는 색상)

#### Scenario: 삭제된 파일 표시
- **GIVEN** Git 저장소
- **WHEN** 파일이 삭제됨 (deleted)
- **THEN** 삭제된 파일 목록에 표시 (취소선 또는 D 아이콘)
