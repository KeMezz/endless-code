//
//  MenuBarViewModel.swift
//  EndlessCode
//
//  메뉴바 ViewModel
//

import Foundation
import AppKit

// MARK: - MenuBarViewModel

/// 메뉴바 ViewModel
@Observable @MainActor
final class MenuBarViewModel {
    // MARK: - Properties

    /// 서버 주소
    private(set) var serverAddress: String = ""

    /// 최근 프로젝트 목록
    private(set) var recentProjects: [Project] = []

    /// 에러 상태
    private(set) var hasError: Bool = false

    /// 에러 메시지
    private(set) var errorMessage: String?

    /// 리소스 경고 표시 여부
    private(set) var showResourceWarning: Bool = false

    /// AppState 참조
    private weak var appState: AppState?

    /// 서버 설정
    private var serverConfig: ServerConfiguration

    // MARK: - Initialization

    init(appState: AppState? = nil, serverConfig: ServerConfiguration = .fromEnvironment()) {
        self.appState = appState
        self.serverConfig = serverConfig
        self.serverAddress = "\(serverConfig.host):\(serverConfig.port)"
    }

    // MARK: - Methods

    /// 서버 토글
    func toggleServer() {
        guard let appState = appState else { return }

        switch appState.serverState {
        case .running:
            stopServer()
        case .stopped, .error:
            startServer()
        }
    }

    /// 서버 시작
    private func startServer() {
        guard let appState = appState else { return }

        // TODO: 실제 서버 시작 로직 구현
        appState.serverState = .running
        hasError = false
        errorMessage = nil
        appState.showToast("서버가 시작되었습니다")
    }

    /// 서버 중지
    private func stopServer() {
        guard let appState = appState else { return }

        // TODO: 실제 서버 중지 로직 구현
        appState.serverState = .stopped
        appState.showToast("서버가 중지되었습니다")
    }

    /// 서버 주소 복사
    func copyServerAddress() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(serverAddress, forType: .string)

        appState?.showToast("서버 주소가 복사되었습니다")
    }

    /// 메인 윈도우 열기
    func openMainWindow() {
        // 메인 윈도우 활성화
        NSApp.activate(ignoringOtherApps: true)

        // 메인 윈도우가 없으면 새로 생성
        if NSApp.windows.isEmpty {
            // TODO: 새 윈도우 생성 로직
        } else {
            // 기존 윈도우 활성화
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }

    /// QR 코드 생성
    func generateQRCode() -> NSImage? {
        guard let token = serverConfig.authToken else {
            return nil
        }

        // 연결 정보를 JSON으로 직렬화
        let connectionInfo: [String: String] = [
            "host": serverConfig.host,
            "port": "\(serverConfig.port)",
            "token": token
        ]

        guard let jsonData = try? JSONEncoder().encode(connectionInfo),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }

        return QRCodeGenerator.generate(from: jsonString, size: 200)
    }

    /// 최근 프로젝트 업데이트
    func updateRecentProjects(_ projects: [Project]) {
        // 최근 사용 순으로 정렬하여 상위 2개만 저장
        recentProjects = projects
            .sorted { ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast) }
            .prefix(2)
            .map { $0 }
    }

    /// 에러 설정
    func setError(_ message: String) {
        hasError = true
        errorMessage = message
        appState?.serverState = .error(message)
    }

    /// 에러 해제
    func clearError() {
        hasError = false
        errorMessage = nil
    }

    /// 리소스 경고 확인
    func checkResourceWarning() {
        guard let appState = appState else { return }

        // 메모리 사용량 확인
        let memoryUsage = getMemoryUsage()
        let memoryWarning = memoryUsage > 500 * 1024 * 1024 // 500MB

        // 세션 수 확인
        let sessionWarning = appState.activeSessions.count > 4

        showResourceWarning = memoryWarning || sessionWarning
    }

    /// 메모리 사용량 가져오기 (바이트)
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return result == KERN_SUCCESS ? info.resident_size : 0
    }
}
