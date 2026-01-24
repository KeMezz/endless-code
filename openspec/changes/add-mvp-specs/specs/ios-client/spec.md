# iOS Client

iOS 앱의 서버 연결 및 모바일 최적화 UI 기능입니다.

## ADDED Requirements

### Requirement: Server Connection
iOS 앱은 macOS 서버에 연결하여 통신해야 합니다(SHALL).

#### Scenario: 서버 주소 입력
- **GIVEN** 설정 화면
- **WHEN** 서버 주소 입력 (IP 또는 도메인)
- **THEN** 주소 형식 유효성 검사
- **AND** 저장 시 Keychain에 보관

#### Scenario: API 토큰 입력
- **GIVEN** 설정 화면
- **WHEN** API 토큰 입력
- **THEN** 토큰을 Keychain에 암호화 저장

#### Scenario: 연결 테스트
- **GIVEN** 서버 주소와 토큰 입력됨
- **WHEN** 연결 테스트 버튼 클릭
- **THEN** 서버에 테스트 요청 전송
- **AND** 연결 성공/실패 결과 표시

#### Scenario: 연결 상태 표시
- **GIVEN** 앱 실행 중
- **WHEN** 서버 연결 상태 변경
- **THEN** 연결 상태 아이콘 업데이트 (연결됨/끊김/연결 중)

### Requirement: Bonjour Server Discovery
iOS 앱은 로컬 네트워크에서 macOS 서버를 자동 발견해야 합니다(SHALL).

#### Scenario: 로컬 서버 스캔
- **GIVEN** iOS 앱과 macOS 서버가 같은 WiFi 네트워크
- **WHEN** 서버 발견 시작
- **THEN** Bonjour로 네트워크 스캔
- **AND** 발견된 EndlessCode 서버 목록 표시

#### Scenario: 서버 선택
- **GIVEN** 발견된 서버 목록 표시 중
- **WHEN** 서버 탭
- **THEN** 해당 서버 주소로 자동 연결
- **AND** 연결 설정에 주소 저장

#### Scenario: 서버 미발견
- **GIVEN** 네트워크 스캔 완료
- **WHEN** 서버 발견 실패
- **THEN** "서버를 찾을 수 없습니다" 메시지
- **AND** 수동 입력 안내

### Requirement: Mobile Navigation
iOS 앱은 모바일에 최적화된 네비게이션을 제공해야 합니다(SHALL).

#### Scenario: 탭 바 네비게이션
- **GIVEN** 앱 실행 중
- **WHEN** 메인 화면 표시
- **THEN** 하단에 탭 바 표시 (Projects, Chat, Files, Settings)
- **AND** 탭 전환 시 해당 화면으로 이동

#### Scenario: 스와이프 제스처
- **GIVEN** 상세 화면 표시 중
- **WHEN** 왼쪽에서 오른쪽으로 스와이프
- **THEN** 이전 화면으로 돌아가기

#### Scenario: Pull to Refresh
- **GIVEN** 목록 화면 표시 중
- **WHEN** 아래로 당기기
- **THEN** 데이터 새로고침
- **AND** 새로고침 인디케이터 표시

### Requirement: Mobile-Optimized Chat
iOS 앱은 모바일에 최적화된 채팅 UI를 제공해야 합니다(SHALL).

#### Scenario: 풀스크린 메시지 목록
- **GIVEN** 채팅 화면
- **WHEN** 화면 렌더링
- **THEN** 메시지 목록이 전체 화면 사용
- **AND** 하단 입력창 고정

#### Scenario: 키보드 대응
- **GIVEN** 입력 필드 포커스
- **WHEN** 키보드 표시
- **THEN** 입력창이 키보드 위로 이동
- **AND** 최근 메시지가 보이도록 스크롤

#### Scenario: 스크롤 시 입력창 숨김
- **GIVEN** 메시지 목록 스크롤 중
- **WHEN** 위로 스크롤
- **THEN** 입력창 숨김 (더 많은 메시지 표시)
- **AND** 아래로 스크롤하면 입력창 다시 표시

### Requirement: Mobile Code Display
iOS 앱은 코드를 모바일에 맞게 표시해야 합니다(SHALL).

#### Scenario: 코드 블록 가로 스크롤
- **GIVEN** 긴 코드 라인 표시 중
- **WHEN** 코드 블록 렌더링
- **THEN** 가로 스크롤 지원
- **AND** 코드 래핑 없음

#### Scenario: 핀치 줌
- **GIVEN** 코드 블록 또는 파일 뷰어 표시 중
- **WHEN** 핀치 줌 제스처
- **THEN** 텍스트 크기 확대/축소
- **AND** 최소/최대 배율 제한

### Requirement: Touch-Friendly Controls
iOS 앱은 터치에 최적화된 컨트롤을 제공해야 합니다(SHALL).

#### Scenario: 적절한 버튼 크기
- **GIVEN** UI 요소 렌더링
- **WHEN** 탭 가능한 요소 표시
- **THEN** 최소 44x44pt 터치 영역 보장

#### Scenario: 다크 모드 지원
- **GIVEN** 시스템 다크 모드 활성화
- **WHEN** 앱 실행
- **THEN** 다크 모드 테마 적용
- **AND** 모든 UI 요소가 다크 모드에 맞게 표시

### Requirement: Network Handling
iOS 앱은 네트워크 상태 변화에 대응해야 합니다(SHALL).

#### Scenario: 네트워크 끊김 감지
- **GIVEN** 서버 연결 중
- **WHEN** 네트워크 연결 끊김
- **THEN** 연결 끊김 알림 표시
- **AND** 재연결 시도 (자동)

#### Scenario: 백그라운드 전환
- **GIVEN** 앱이 포그라운드에서 실행 중
- **WHEN** 백그라운드로 전환
- **THEN** WebSocket 연결 유지 (가능한 경우)
- **OR** 포그라운드 복귀 시 자동 재연결

#### Scenario: 셀룰러 네트워크 경고
- **GIVEN** WiFi 연결 없음
- **WHEN** 셀룰러로 연결 시도
- **THEN** 셀룰러 데이터 사용 경고 표시
- **AND** 사용자 확인 후 연결
