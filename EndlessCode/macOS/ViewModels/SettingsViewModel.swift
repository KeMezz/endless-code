//
//  SettingsViewModel.swift
//  EndlessCode
//
//  설정 화면의 상태 관리
//

import Foundation

// MARK: - SettingsViewModel

/// 설정 화면의 상태를 관리하는 ViewModel
@Observable @MainActor
final class SettingsViewModel {
    // MARK: - Properties

    /// 현재 설정
    var config: ServerConfiguration

    /// 원본 설정 (변경사항 추적용)
    private let originalConfig: ServerConfiguration

    /// 인증 토큰 표시 여부
    var isTokenVisible = false

    /// 임시 토큰 (UI 표시용)
    var displayToken: String

    /// CLI 경로 에러 메시지
    private(set) var cliPathError: String?

    /// 저장 에러 메시지
    private(set) var saveError: String?

    // MARK: - Computed Properties

    /// 변경사항 존재 여부
    var hasChanges: Bool {
        config != originalConfig || displayToken != (originalConfig.authToken ?? "")
    }

    /// 유효성 검사 통과 여부
    var isValid: Bool {
        !config.host.isEmpty &&
        config.port > 0 && config.port <= 65535 &&
        !config.cliPath.isEmpty &&
        cliPathError == nil &&
        config.maxConcurrentSessions > 0 && config.maxConcurrentSessions <= 10 &&
        config.sessionTimeoutSeconds > 0 &&
        config.promptTimeoutSeconds > 0
    }

    // MARK: - Initialization

    init(config: ServerConfiguration = .init()) {
        self.config = config
        self.originalConfig = config
        self.displayToken = config.authToken ?? ""
    }

    // MARK: - Actions

    /// CLI 경로 유효성 검사
    func validateCLIPath() {
        cliPathError = nil

        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false

        // 파일 존재 여부 확인
        guard fileManager.fileExists(atPath: config.cliPath, isDirectory: &isDirectory) else {
            cliPathError = "File does not exist"
            return
        }

        // 디렉토리가 아닌지 확인
        guard !isDirectory.boolValue else {
            cliPathError = "Path is a directory, not a file"
            return
        }

        // 실행 가능한지 확인
        guard fileManager.isExecutableFile(atPath: config.cliPath) else {
            cliPathError = "File is not executable"
            return
        }
    }

    /// 설정 저장
    func save() {
        saveError = nil

        // 유효성 검사
        guard isValid else {
            saveError = "Invalid settings. Please check all fields."
            return
        }

        // 토큰 업데이트
        if displayToken.isEmpty {
            config.authToken = nil
        } else {
            config.authToken = displayToken
        }

        // TODO: 실제 저장 로직 (UserDefaults 또는 파일)
        // 현재는 메모리에만 유지

        print("Settings saved: \(config)")
    }

    /// 설정 초기화 (기본값 복원)
    func reset() {
        config = ServerConfiguration()
        displayToken = ""
        cliPathError = nil
        saveError = nil
    }

    /// 변경사항 취소
    func cancel() {
        config = originalConfig
        displayToken = originalConfig.authToken ?? ""
        cliPathError = nil
        saveError = nil
    }

    /// 새 토큰 생성 (UUID 기반)
    func generateToken() {
        displayToken = UUID().uuidString
    }

    /// 토큰을 Keychain에 저장
    func saveTokenToKeychain() throws {
        guard !displayToken.isEmpty else {
            // 빈 토큰이면 Keychain에서 삭제
            try KeychainManager.deleteToken()
            return
        }

        try KeychainManager.saveToken(displayToken)
    }

    /// Keychain에서 토큰 로드
    func loadTokenFromKeychain() throws {
        if let token = try KeychainManager.loadToken() {
            displayToken = token
            config.authToken = token
        }
    }

    /// 토큰 표시/숨김 토글
    func toggleTokenVisibility() {
        isTokenVisible.toggle()
    }

    /// CLI 경로 선택 (파일 선택 다이얼로그)
    func selectCLIPath() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.message = "Select Claude CLI executable"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/usr/local/bin")

        if panel.runModal() == .OK, let url = panel.url {
            config.cliPath = url.path
            validateCLIPath()
        }
        #endif
    }

    /// 에러 메시지 해제
    func clearError() {
        saveError = nil
    }
}
