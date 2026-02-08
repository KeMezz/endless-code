//
//  BonjourBrowser.swift
//  EndlessCode
//
//  Bonjour 서비스 검색
//

#if os(iOS)
import Foundation
import Network

// MARK: - BonjourBrowserProtocol

/// Bonjour 브라우저 프로토콜
protocol BonjourBrowserProtocol: Sendable {
    /// 브라우징 시작
    /// - Returns: 발견된 서버 스트림
    func startBrowsing() async -> AsyncStream<DiscoveredServer>

    /// 브라우징 중지
    func stopBrowsing()
}

// MARK: - BonjourBrowser

/// Bonjour 서비스 검색 구현
actor BonjourBrowser: BonjourBrowserProtocol {
    // MARK: - Private Properties

    private var browser: NWBrowser?
    private var continuation: AsyncStream<DiscoveredServer>.Continuation?

    // MARK: - Constants

    /// EndlessCode 서비스 타입
    private static let serviceType = "_endlesscode._tcp"

    // MARK: - Public Methods

    /// 브라우징 시작
    func startBrowsing() async -> AsyncStream<DiscoveredServer> {
        let (stream, continuation) = AsyncStream.makeStream(of: DiscoveredServer.self)
        self.continuation = continuation

        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        let browser = NWBrowser(for: .bonjour(type: Self.serviceType, domain: nil), using: parameters)

        browser.stateUpdateHandler = { [weak self] state in
            Task { await self?.handleStateChange(state) }
        }

        browser.browseResultsChangedHandler = { [weak self] results, changes in
            Task { await self?.handleBrowseResults(results, changes: changes) }
        }

        browser.start(queue: .main)
        self.browser = browser

        return stream
    }

    /// 브라우징 중지
    func stopBrowsing() {
        browser?.cancel()
        browser = nil
        continuation?.finish()
        continuation = nil
    }

    // MARK: - Private Methods

    /// 상태 변경 처리
    private func handleStateChange(_ state: NWBrowser.State) {
        switch state {
        case .ready:
            break
        case .failed(let error):
            continuation?.finish()
        case .cancelled:
            continuation?.finish()
        default:
            break
        }
    }

    /// 브라우즈 결과 처리
    private func handleBrowseResults(_ results: Set<NWBrowser.Result>, changes: Set<NWBrowser.Result.Change>) {
        for change in changes {
            switch change {
            case .added(let result):
                handleAddedResult(result)
            case .removed:
                break
            case .identical:
                break
            @unknown default:
                break
            }
        }
    }

    /// 추가된 결과 처리
    private func handleAddedResult(_ result: NWBrowser.Result) {
        guard case .service(let name, let type, let domain, _) = result.endpoint else {
            return
        }

        // 엔드포인트 해석
        resolveEndpoint(result.endpoint, name: name, type: type, domain: domain)
    }

    /// 엔드포인트 해석
    private func resolveEndpoint(_ endpoint: NWEndpoint, name: String, type: String, domain: String) {
        let connection = NWConnection(to: endpoint, using: .tcp)

        connection.stateUpdateHandler = { [weak self] state in
            if case .ready = state {
                Task {
                    await self?.extractServerInfo(from: connection, name: name)
                }
                connection.cancel()
            }
        }

        connection.start(queue: .main)
    }

    /// 서버 정보 추출
    private func extractServerInfo(from connection: NWConnection, name: String) {
        guard case .hostPort(let host, let port) = connection.currentPath?.remoteEndpoint else {
            return
        }

        let address: String
        switch host {
        case .ipv4(let ipv4):
            address = ipv4.debugDescription
        case .ipv6(let ipv6):
            address = "[\(ipv6.debugDescription)]"
        case .name(let hostname, _):
            address = hostname
        @unknown default:
            return
        }

        let server = DiscoveredServer(
            name: name,
            address: address,
            port: Int(port.rawValue)
        )

        continuation?.yield(server)
    }

    // MARK: - Cleanup

    deinit {
        browser?.cancel()
    }
}
#endif
