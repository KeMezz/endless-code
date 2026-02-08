//
//  BonjourDiscoveryViewModel.swift
//  EndlessCode
//
//  Bonjour 서버 발견 ViewModel
//

#if os(iOS)
import Foundation
import Observation

// MARK: - BonjourDiscoveryViewModel

/// Bonjour 서버 발견 관리
@MainActor
@Observable
final class BonjourDiscoveryViewModel {
    // MARK: - Published Properties

    /// 발견된 서버 목록
    var discoveredServers: [DiscoveredServer] = []

    /// 스캔 중 여부
    var isScanning: Bool = false

    /// 에러 메시지
    var errorMessage: String?

    // MARK: - Private Properties

    private let bonjourBrowser: BonjourBrowserProtocol
    nonisolated(unsafe) private var scanTask: Task<Void, Never>?

    // MARK: - Initialization

    init(bonjourBrowser: BonjourBrowserProtocol) {
        self.bonjourBrowser = bonjourBrowser
    }

    #if os(iOS)
    convenience init() {
        self.init(bonjourBrowser: BonjourBrowser())
    }
    #endif

    // MARK: - Public Methods

    /// 스캔 시작
    func startScanning() {
        guard !isScanning else { return }

        isScanning = true
        errorMessage = nil
        discoveredServers = []

        scanTask = Task { [weak self] in
            guard let self else { return }

            do {
                for try await server in await self.bonjourBrowser.startBrowsing() {
                    await self.addServer(server)
                }
            } catch {
                await self.handleScanError(error)
            }
        }
    }

    /// 스캔 중지
    func stopScanning() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
        bonjourBrowser.stopBrowsing()
    }

    /// 서버 선택
    func selectServer(_ server: DiscoveredServer) -> ServerSettingsUpdate {
        return ServerSettingsUpdate(
            serverAddress: server.fullURL,
            authToken: nil
        )
    }

    // MARK: - Private Methods

    /// 서버 추가
    private func addServer(_ server: DiscoveredServer) {
        // 중복 확인
        if !discoveredServers.contains(where: { $0.address == server.address && $0.port == server.port }) {
            discoveredServers.append(server)
        }
    }

    /// 스캔 에러 처리
    private func handleScanError(_ error: Error) {
        isScanning = false
        errorMessage = error.localizedDescription
    }

    // MARK: - Cleanup

    deinit {
        scanTask?.cancel()
    }
}

// MARK: - ServerSettingsUpdate

/// 서버 설정 업데이트 데이터
struct ServerSettingsUpdate {
    let serverAddress: String
    let authToken: String?
}
#endif
