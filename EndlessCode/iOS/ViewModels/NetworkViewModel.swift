//
//  NetworkViewModel.swift
//  EndlessCode
//
//  네트워크 상태 UI 바인딩 - SwiftUI @Observable 래퍼
//

#if os(iOS)
import Foundation
import Network
import Observation

// MARK: - NetworkViewModel

/// 네트워크 상태 ViewModel
@MainActor
@Observable
final class NetworkViewModel {
    // MARK: - Properties

    private(set) var isNetworkAvailable: Bool = true
    private(set) var connectionType: String = "WiFi"
    private(set) var showCellularWarning: Bool = false

    private var monitor: NetworkMonitor?
    private var pathUpdateTask: Task<Void, Never>?
    private var lifecycleManager: AppLifecycleManager?
    private var lifecycleEventTask: Task<Void, Never>?

    // 재연결 콜백
    var onNetworkRestored: (() async -> Void)?
    var onNetworkLost: (() async -> Void)?

    // MARK: - Initialization

    init() {}

    deinit {
        pathUpdateTask?.cancel()
        lifecycleEventTask?.cancel()
    }

    // MARK: - Public Methods

    /// 네트워크 및 생명주기 모니터링 시작
    func startMonitoring() async {
        guard monitor == nil else { return }

        let networkMonitor = NetworkMonitor()
        self.monitor = networkMonitor

        let lifecycleManager = AppLifecycleManager()
        self.lifecycleManager = lifecycleManager

        await networkMonitor.start()
        await lifecycleManager.start()

        // 네트워크 경로 변경 감시
        pathUpdateTask = Task { [weak self] in
            guard let self = self else { return }

            for await path in networkMonitor.pathUpdates {
                guard !Task.isCancelled else { break }
                await self.handlePathUpdate(path)
            }
        }

        // 생명주기 이벤트 감시
        lifecycleEventTask = Task { [weak self] in
            guard let self = self else { return }

            for await event in lifecycleManager.lifecycleEvents {
                guard !Task.isCancelled else { break }
                await self.handleLifecycleEvent(event)
            }
        }
    }

    /// 모니터링 중지
    func stopMonitoring() async {
        pathUpdateTask?.cancel()
        pathUpdateTask = nil

        lifecycleEventTask?.cancel()
        lifecycleEventTask = nil

        await monitor?.stop()
        await lifecycleManager?.stop()

        monitor = nil
        lifecycleManager = nil
    }

    // MARK: - Private Methods

    private func handlePathUpdate(_ path: NWPath) async {
        let wasConnected = isNetworkAvailable
        isNetworkAvailable = path.status == .satisfied

        // 연결 타입 업데이트
        if path.usesInterfaceType(.wifi) {
            connectionType = "WiFi"
            showCellularWarning = false
        } else if path.usesInterfaceType(.cellular) {
            connectionType = "Cellular"
            showCellularWarning = true
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = "Ethernet"
            showCellularWarning = false
        } else {
            connectionType = "Unknown"
            showCellularWarning = false
        }

        // 네트워크 복구 감지
        if !wasConnected && isNetworkAvailable {
            await onNetworkRestored?()
        }

        // 네트워크 끊김 감지
        if wasConnected && !isNetworkAvailable {
            await onNetworkLost?()
        }
    }

    private func handleLifecycleEvent(_ event: AppLifecycleEvent) async {
        switch event {
        case .willResignActive:
            // 앱이 비활성화될 예정 - 특별한 처리 불필요
            break

        case .didEnterBackground:
            // 백그라운드 진입 - 타이머 정지 등 처리는 각 ViewModel에서 수행
            break

        case .willEnterForeground:
            // 포그라운드 복귀 예정 - 연결 상태 확인은 didBecomeActive에서 수행
            break

        case .didBecomeActive:
            // 포그라운드 복귀 완료 - 네트워크 상태 재확인
            // NetworkMonitor가 자동으로 감지하므로 추가 처리 불필요
            break
        }
    }
}
#endif
