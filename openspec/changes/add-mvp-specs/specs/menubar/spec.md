# MenuBar

macOS 메뉴바에서 EndlessCode 서버 상태를 확인하고 빠른 액션을 수행하는 기능입니다.

## ADDED Requirements

### Requirement: Menu Bar Status Display
시스템은 메뉴바에서 서버 상태를 표시해야 합니다(SHALL).

#### Scenario: 서버 실행 중 상태 표시
- **GIVEN** EndlessCode 서버가 실행 중
- **WHEN** 메뉴바 아이콘 확인
- **THEN** 활성 상태 아이콘 표시 (녹색 또는 채워진 아이콘)
- **AND** 아이콘 툴팁에 "EndlessCode 실행 중" 표시

#### Scenario: 서버 중지 상태 표시
- **GIVEN** EndlessCode 서버가 중지됨
- **WHEN** 메뉴바 아이콘 확인
- **THEN** 비활성 상태 아이콘 표시 (회색 또는 빈 아이콘)
- **AND** 아이콘 툴팁에 "EndlessCode 중지됨" 표시

#### Scenario: 활성 세션 수 표시
- **GIVEN** 서버가 실행 중이고 N개 세션 활성
- **WHEN** 메뉴바 메뉴 열기
- **THEN** "활성 세션: N개" 표시
- **AND** 각 세션의 프로젝트 이름 목록 표시 (최대 5개)

#### Scenario: 연결된 클라이언트 수 표시
- **GIVEN** 서버가 실행 중
- **WHEN** 메뉴바 메뉴 열기
- **THEN** "연결된 클라이언트: N개" 표시

### Requirement: Quick Actions
시스템은 메뉴바에서 빠른 액션을 제공해야 합니다(SHALL).

#### Scenario: 새 세션 시작
- **GIVEN** 서버가 실행 중
- **WHEN** 메뉴에서 "새 세션 시작" 클릭
- **THEN** 메인 앱 창 열림
- **AND** 프로젝트 선택 화면 표시

#### Scenario: 최근 프로젝트 바로가기
- **GIVEN** 최근 사용한 프로젝트 존재
- **WHEN** 메뉴바 메뉴 열기
- **THEN** 최근 프로젝트 2개 표시 (서브메뉴)
- **AND** 클릭 시 해당 프로젝트로 새 세션 시작

#### Scenario: 서버 시작/중지
- **GIVEN** 앱이 실행 중
- **WHEN** 메뉴에서 "서버 시작" 또는 "서버 중지" 클릭
- **THEN** 해당 동작 수행
- **AND** 메뉴 항목 텍스트 업데이트

#### Scenario: 설정 열기
- **GIVEN** 앱이 실행 중
- **WHEN** 메뉴에서 "설정..." 클릭
- **THEN** 설정 창 열림

#### Scenario: 앱 종료
- **GIVEN** 앱이 실행 중
- **WHEN** 메뉴에서 "종료" 클릭
- **THEN** 활성 세션이 있으면 확인 다이얼로그 표시
- **AND** 확인 시 모든 세션 종료 후 앱 종료

### Requirement: Server Information
시스템은 메뉴바에서 서버 정보를 제공해야 합니다(SHALL).

#### Scenario: 서버 주소 표시
- **GIVEN** 서버가 실행 중
- **WHEN** 메뉴바 메뉴 열기
- **THEN** 서버 주소 표시 (예: "192.168.1.100:8080")
- **AND** 클릭 시 주소 클립보드에 복사

#### Scenario: 접속 토큰 표시
- **GIVEN** 서버가 실행 중
- **WHEN** 메뉴에서 "접속 토큰 보기" 클릭
- **THEN** 토큰 표시 다이얼로그 열림 (마스킹된 상태)
- **AND** "복사" 버튼으로 클립보드에 복사 가능
- **AND** "QR 코드" 버튼으로 iOS 연결용 QR 표시

#### Scenario: QR 코드 생성
- **GIVEN** 서버가 실행 중
- **WHEN** QR 코드 버튼 클릭
- **THEN** 서버 주소 + 토큰이 인코딩된 QR 코드 표시
- **AND** iOS 앱에서 스캔하여 자동 연결 가능

### Requirement: Error Notifications
시스템은 메뉴바에서 오류를 알려야 합니다(SHALL).

#### Scenario: 서버 오류 알림
- **GIVEN** 서버에서 오류 발생
- **WHEN** 오류 감지
- **THEN** 메뉴바 아이콘에 경고 배지 표시 (느낌표)
- **AND** 메뉴에 오류 메시지 표시

#### Scenario: 세션 크래시 알림
- **GIVEN** CLI 프로세스가 크래시됨
- **WHEN** 크래시 감지
- **THEN** macOS 알림 전송 (선택적, 설정에 따라)
- **AND** 메뉴에 "세션 오류 발생" 표시

#### Scenario: 리소스 경고
- **GIVEN** 서버가 실행 중
- **WHEN** 메모리 사용량 > 500MB 또는 세션 수 > 4개
- **THEN** 메뉴에 리소스 경고 표시
- **AND** "유휴 세션 정리" 버튼 제공
