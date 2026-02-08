//
//  ServerSettingsViewModel.swift
//  EndlessCode
//
//  서버 설정 ViewModel - 주소/토큰 관리
//

#if os(iOS)
import Foundation
import Observation

// MARK: - ServerSettingsViewModel

/// 서버 설정 관리
@MainActor
@Observable
final class ServerSettingsViewModel {
    // MARK: - Published Properties

    /// 서버 주소 (http://host:port)
    var serverAddress: String {
        didSet {
            saveServerAddress()
        }
    }

    /// API 토큰
    private var _isInitializing = true

    var apiToken: String = "" {
        didSet {
            guard !_isInitializing, !apiToken.isEmpty else { return }
            try? KeychainManager.saveToken(apiToken)
        }
    }

    /// 토큰 표시 여부
    var isTokenVisible: Bool = false

    /// 연결 상태
    var connectionState: ConnectionState = .disconnected

    /// 테스트 중 여부
    var isTesting: Bool = false

    /// 마지막 테스트 결과 메시지
    var lastTestMessage: String?

    // MARK: - Private Properties

    private let urlSession: URLSession
    private let userDefaults: UserDefaults

    // MARK: - UserDefaults Keys

    private static let serverAddressKey = "serverAddress"

    // MARK: - Initialization

    init(
        urlSession: URLSession = .shared,
        userDefaults: UserDefaults = .standard
    ) {
        self.urlSession = urlSession
        self.userDefaults = userDefaults

        // 저장된 서버 주소 로드
        self.serverAddress = userDefaults.string(forKey: Self.serverAddressKey) ?? "http://127.0.0.1:8080"

        // 저장된 토큰 로드
        if let token = try? KeychainManager.loadToken() {
            self.apiToken = token
        }

        self._isInitializing = false
    }

    // MARK: - Public Methods

    /// 연결 테스트
    func testConnection() async {
        guard !isTesting else { return }

        isTesting = true
        connectionState = .connecting
        lastTestMessage = nil

        defer {
            isTesting = false
        }

        do {
            // URL 유효성 검증
            guard let url = validateURL(serverAddress) else {
                connectionState = .failed(error: "Invalid server URL format")
                lastTestMessage = "올바른 URL 형식이 아닙니다"
                return
            }

            // HTTP 요청 생성
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            request.httpMethod = "GET"

            // 토큰이 있으면 헤더에 추가
            if !apiToken.isEmpty {
                request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
            }

            // 요청 전송
            let (_, response) = try await urlSession.data(for: request)

            // 응답 확인
            guard let httpResponse = response as? HTTPURLResponse else {
                connectionState = .failed(error: "Invalid response")
                lastTestMessage = "서버 응답이 올바르지 않습니다"
                return
            }

            // 상태 코드 확인
            switch httpResponse.statusCode {
            case 200...299:
                connectionState = .connected
                lastTestMessage = "연결 성공"
            case 401:
                connectionState = .failed(error: "Unauthorized")
                lastTestMessage = "인증 토큰이 올바르지 않습니다"
            case 403:
                connectionState = .failed(error: "Forbidden")
                lastTestMessage = "접근 권한이 없습니다"
            default:
                connectionState = .failed(error: "HTTP \(httpResponse.statusCode)")
                lastTestMessage = "서버 오류 (HTTP \(httpResponse.statusCode))"
            }

        } catch {
            connectionState = .failed(error: error.localizedDescription)
            lastTestMessage = "연결 실패: \(error.localizedDescription)"
        }
    }

    /// 서버 설정 저장
    func saveSettings() {
        saveServerAddress()
        if !apiToken.isEmpty {
            try? KeychainManager.saveToken(apiToken)
        }
    }

    /// 서버 설정 초기화
    func resetSettings() {
        serverAddress = "http://127.0.0.1:8080"
        apiToken = ""
        try? KeychainManager.deleteToken()
        connectionState = .disconnected
        lastTestMessage = nil
    }

    /// 발견된 서버로부터 설정 업데이트
    func updateFromDiscoveredServer(_ server: DiscoveredServer) {
        serverAddress = server.fullURL
    }

    /// QR 코드 데이터로부터 설정 업데이트
    func updateFromQRCode(_ qrData: QRCodeData) {
        serverAddress = qrData.serverAddress
        if let token = qrData.authToken {
            apiToken = token
        }
    }

    // MARK: - Private Methods

    /// 서버 주소 저장
    private func saveServerAddress() {
        userDefaults.set(serverAddress, forKey: Self.serverAddressKey)
    }

    /// URL 유효성 검증
    private func validateURL(_ urlString: String) -> URL? {
        guard let url = URL(string: urlString) else {
            return nil
        }

        // 스킴 확인
        guard let scheme = url.scheme, ["http", "https", "ws", "wss"].contains(scheme) else {
            return nil
        }

        // 호스트 확인
        guard url.host != nil else {
            return nil
        }

        return url
    }
}
#endif
