//
//  NetworkMonitor.swift
//  EndlessCode
//
//  네트워크 상태 모니터링 - NWPathMonitor 래퍼
//  WiFi / 셀룰러 / 이더넷 구분 및 상태 변경 감지
//

#if os(iOS)
import Foundation
import Network

// MARK: - NetworkMonitorProtocol

/// 네트워크 모니터 프로토콜
protocol NetworkMonitorProtocol: Sendable {
    /// 현재 네트워크 연결 여부
    var isConnected: Bool { get async }

    /// 현재 연결 타입 (WiFi, Cellular, Ethernet 등)
    var connectionType: NWInterface.InterfaceType? { get async }

    /// 네트워크 경로 변경 스트림
    var pathUpdates: AsyncStream<NWPath> { get }

    /// 모니터링 시작
    func start() async

    /// 모니터링 중지
    func stop() async
}

// MARK: - NetworkMonitor

/// 네트워크 모니터 구현
actor NetworkMonitor: NetworkMonitorProtocol {
    // MARK: - Properties

    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private var _isConnected: Bool = true
    private var _connectionType: NWInterface.InterfaceType?
    private var isMonitoring: Bool = false

    private let pathContinuation: AsyncStream<NWPath>.Continuation
    private let _pathUpdates: AsyncStream<NWPath>

    // MARK: - Initialization

    init() {
        self.monitor = NWPathMonitor()
        self.queue = DispatchQueue(label: "com.endlesscode.network-monitor", qos: .utility)

        let (stream, continuation) = AsyncStream.makeStream(of: NWPath.self)
        self._pathUpdates = stream
        self.pathContinuation = continuation
    }

    deinit {
        monitor.cancel()
        pathContinuation.finish()
    }

    // MARK: - NetworkMonitorProtocol

    var isConnected: Bool {
        _isConnected
    }

    var connectionType: NWInterface.InterfaceType? {
        _connectionType
    }

    nonisolated var pathUpdates: AsyncStream<NWPath> {
        _pathUpdates
    }

    func start() async {
        guard !isMonitoring else { return }
        isMonitoring = true

        monitor.pathUpdateHandler = { [weak self] path in
            Task {
                await self?.handlePathUpdate(path)
            }
        }

        monitor.start(queue: queue)
    }

    func stop() async {
        guard isMonitoring else { return }
        isMonitoring = false

        monitor.cancel()
    }

    // MARK: - Private Methods

    private func handlePathUpdate(_ path: NWPath) {
        // 연결 상태 업데이트
        _isConnected = path.status == .satisfied

        // 연결 타입 결정
        if path.usesInterfaceType(.wifi) {
            _connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            _connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            _connectionType = .wiredEthernet
        } else if path.usesInterfaceType(.loopback) {
            _connectionType = .loopback
        } else if path.usesInterfaceType(.other) {
            _connectionType = .other
        } else {
            _connectionType = nil
        }

        // 경로 변경 이벤트 발행
        pathContinuation.yield(path)
    }
}
#endif
