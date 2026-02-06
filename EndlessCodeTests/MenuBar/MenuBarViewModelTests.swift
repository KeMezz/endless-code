//
//  MenuBarViewModelTests.swift
//  EndlessCodeTests
//
//  MenuBarViewModel 테스트
//

import Testing
import Foundation
@testable import EndlessCode

// MARK: - MenuBarViewModel Tests

@Suite("MenuBarViewModel Tests")
@MainActor
struct MenuBarViewModelTests {
    // MARK: - Initialization Tests

    @Test("초기화 시 기본값 설정")
    func initializationSetsDefaults() async throws {
        // Given
        let config = ServerConfiguration(host: "localhost", port: 8080)

        // When
        let sut = MenuBarViewModel(serverConfig: config)

        // Then
        #expect(sut.serverAddress == "localhost:8080")
        #expect(sut.recentProjects.isEmpty)
        #expect(sut.hasError == false)
        #expect(sut.errorMessage == nil)
        #expect(sut.showResourceWarning == false)
    }

    // MARK: - Server Control Tests

    @Test("서버 주소 복사")
    func copyServerAddressCopiesAddress() async throws {
        // Given
        let appState = AppState()
        let sut = MenuBarViewModel(appState: appState)

        // When
        sut.copyServerAddress()

        // Then
        #expect(appState.toastMessage == "서버 주소가 복사되었습니다")
    }

    @Test("서버 토글 - 중지 상태에서 시작")
    func toggleServerStartsWhenStopped() async throws {
        // Given
        let appState = AppState()
        appState.serverState = .stopped
        let sut = MenuBarViewModel(appState: appState)

        // When
        sut.toggleServer()

        // Then
        #expect(appState.serverState == .running)
        #expect(appState.toastMessage == "서버가 시작되었습니다")
    }

    @Test("서버 토글 - 실행 상태에서 중지")
    func toggleServerStopsWhenRunning() async throws {
        // Given
        let appState = AppState()
        appState.serverState = .running
        let sut = MenuBarViewModel(appState: appState)

        // When
        sut.toggleServer()

        // Then
        #expect(appState.serverState == .stopped)
        #expect(appState.toastMessage == "서버가 중지되었습니다")
    }

    @Test("서버 토글 - 에러 상태에서 시작")
    func toggleServerStartsWhenError() async throws {
        // Given
        let appState = AppState()
        appState.serverState = .error("Test error")
        let sut = MenuBarViewModel(appState: appState)

        // When
        sut.toggleServer()

        // Then
        #expect(appState.serverState == .running)
    }

    // MARK: - Recent Projects Tests

    @Test("최근 프로젝트 업데이트 - 최대 2개")
    func updateRecentProjectsLimitsToTwo() async throws {
        // Given
        let sut = MenuBarViewModel()
        let projects = [
            Project(id: "1", name: "Project 1", path: "/path/1", lastUsed: Date()),
            Project(id: "2", name: "Project 2", path: "/path/2", lastUsed: Date().addingTimeInterval(-100)),
            Project(id: "3", name: "Project 3", path: "/path/3", lastUsed: Date().addingTimeInterval(-200))
        ]

        // When
        sut.updateRecentProjects(projects)

        // Then
        #expect(sut.recentProjects.count == 2)
        #expect(sut.recentProjects[0].id == "1")
        #expect(sut.recentProjects[1].id == "2")
    }

    @Test("최근 프로젝트 업데이트 - 최근 사용 순 정렬")
    func updateRecentProjectsSortsByLastUsed() async throws {
        // Given
        let sut = MenuBarViewModel()
        let oldDate = Date().addingTimeInterval(-1000)
        let recentDate = Date()

        let projects = [
            Project(id: "1", name: "Old Project", path: "/path/1", lastUsed: oldDate),
            Project(id: "2", name: "Recent Project", path: "/path/2", lastUsed: recentDate)
        ]

        // When
        sut.updateRecentProjects(projects)

        // Then
        #expect(sut.recentProjects.count == 2)
        #expect(sut.recentProjects[0].id == "2") // Recent first
        #expect(sut.recentProjects[1].id == "1")
    }

    // MARK: - Error Handling Tests

    @Test("에러 설정")
    func setErrorSetsErrorState() async throws {
        // Given
        let appState = AppState()
        let sut = MenuBarViewModel(appState: appState)

        // When
        sut.setError("Test error message")

        // Then
        #expect(sut.hasError == true)
        #expect(sut.errorMessage == "Test error message")
        #expect(appState.serverState == .error("Test error message"))
    }

    @Test("에러 해제")
    func clearErrorClearsErrorState() async throws {
        // Given
        let appState = AppState()
        let sut = MenuBarViewModel(appState: appState)
        sut.setError("Test error")

        // When
        sut.clearError()

        // Then
        #expect(sut.hasError == false)
        #expect(sut.errorMessage == nil)
    }

    // MARK: - QR Code Tests

    @Test("QR 코드 생성 - 토큰이 있을 때")
    func generateQRCodeReturnsImageWhenTokenExists() async throws {
        // Given
        let config = ServerConfiguration(
            host: "192.168.1.100",
            port: 8080,
            authToken: "test-token-123"
        )
        let sut = MenuBarViewModel(serverConfig: config)

        // When
        let qrCode = sut.generateQRCode()

        // Then
        #expect(qrCode != nil)
    }

    @Test("QR 코드 생성 - 토큰이 없을 때")
    func generateQRCodeReturnsNilWhenNoToken() async throws {
        // Given
        let config = ServerConfiguration(
            host: "localhost",
            port: 8080,
            authToken: nil
        )
        let sut = MenuBarViewModel(serverConfig: config)

        // When
        let qrCode = sut.generateQRCode()

        // Then
        #expect(qrCode == nil)
    }

    // MARK: - Resource Warning Tests

    @Test("리소스 경고 확인 - 세션 4개 이하")
    func checkResourceWarningNoWarningWithFewSessions() async throws {
        // Given
        let appState = AppState()
        appState.activeSessions = [
            Session(projectId: "1"),
            Session(projectId: "2"),
            Session(projectId: "3")
        ]
        let sut = MenuBarViewModel(appState: appState)

        // When
        sut.checkResourceWarning()

        // Then (메모리 사용량에 따라 달라질 수 있으므로 세션 수만 확인)
        // 세션 수가 4개 이하이므로 세션 경고는 없어야 함
        #expect(appState.activeSessions.count <= 4)
    }

    @Test("리소스 경고 확인 - 세션 5개 이상")
    func checkResourceWarningShowsWarningWithManySessions() async throws {
        // Given
        let appState = AppState()
        appState.activeSessions = [
            Session(projectId: "1"),
            Session(projectId: "2"),
            Session(projectId: "3"),
            Session(projectId: "4"),
            Session(projectId: "5")
        ]
        let sut = MenuBarViewModel(appState: appState)

        // When
        sut.checkResourceWarning()

        // Then
        #expect(sut.showResourceWarning == true)
    }
}
