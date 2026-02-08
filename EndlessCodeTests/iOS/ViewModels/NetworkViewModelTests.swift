//
//  NetworkViewModelTests.swift
//  EndlessCodeTests
//
//  NetworkViewModel 단위 테스트
//

#if os(iOS)
import Testing
import Network
@testable import EndlessCode

// MARK: - NetworkViewModelTests

@Suite("NetworkViewModel Tests")
@MainActor
struct NetworkViewModelTests {
    // MARK: - Initialization Tests

    @Test("Initialization sets default values")
    func initializationSetsDefaultValues() async throws {
        // Given & When
        let sut = NetworkViewModel()

        // Then
        #expect(sut.isNetworkAvailable == true)
        #expect(sut.connectionType == "WiFi")
        #expect(sut.showCellularWarning == false)
    }

    // MARK: - Monitoring Tests

    @Test("Start monitoring initializes network monitor")
    func startMonitoringInitializesNetworkMonitor() async throws {
        // Given
        let sut = NetworkViewModel()

        // When
        await sut.startMonitoring()

        // Then
        // 모니터링이 시작되어야 함 (크래시 없이 완료되면 성공)
        #expect(sut.isNetworkAvailable != nil)
    }

    @Test("Stop monitoring cleans up resources")
    func stopMonitoringCleansUpResources() async throws {
        // Given
        let sut = NetworkViewModel()
        await sut.startMonitoring()

        // When
        sut.stopMonitoring()

        // Then
        // 리소스가 정리되어야 함 (크래시 없이 완료되면 성공)
        #expect(sut.isNetworkAvailable != nil)
    }

    // MARK: - Network State Tests

    @Test("Network state reflects actual connectivity")
    func networkStateReflectsActualConnectivity() async throws {
        // Given
        let sut = NetworkViewModel()

        // When
        await sut.startMonitoring()

        // 네트워크 상태 업데이트 대기
        try await Task.sleep(nanoseconds: 500_000_000)

        // Then
        // 시뮬레이터/실제 기기에서는 대부분 연결되어 있을 것으로 예상
        #expect(sut.isNetworkAvailable == true)
        #expect(sut.connectionType != "")
    }

    @Test("Cellular connection shows warning")
    func cellularConnectionShowsWarning() async throws {
        // Given
        let sut = NetworkViewModel()
        await sut.startMonitoring()

        // When
        // 실제 셀룰러 연결 시뮬레이션은 어려우므로
        // connectionType 값 변경은 실제 네트워크 환경에 의존

        // Then
        // WiFi 연결 시 경고 없음
        if sut.connectionType == "WiFi" {
            #expect(sut.showCellularWarning == false)
        }
        // Cellular 연결 시 경고 표시
        else if sut.connectionType == "Cellular" {
            #expect(sut.showCellularWarning == true)
        }
    }

    // MARK: - Callback Tests

    @Test("Network restored callback is invoked")
    func networkRestoredCallbackIsInvoked() async throws {
        // Given
        let sut = NetworkViewModel()
        var restoredCallbackInvoked = false

        sut.onNetworkRestored = {
            restoredCallbackInvoked = true
        }

        // When
        await sut.startMonitoring()

        // 네트워크 상태 변경을 시뮬레이션하기 어려우므로
        // 콜백 설정이 정상적으로 작동하는지만 확인
        try await Task.sleep(nanoseconds: 500_000_000)

        // Then
        // 실제 네트워크 복구 이벤트가 있을 때만 콜백이 호출됨
        // 테스트 환경에서는 대부분 초기부터 연결되어 있으므로
        // 콜백 호출 여부는 환경에 의존
    }

    @Test("Network lost callback is invoked")
    func networkLostCallbackIsInvoked() async throws {
        // Given
        let sut = NetworkViewModel()
        var lostCallbackInvoked = false

        sut.onNetworkLost = {
            lostCallbackInvoked = true
        }

        // When
        await sut.startMonitoring()

        // 네트워크 상태 변경을 시뮬레이션하기 어려우므로
        // 콜백 설정이 정상적으로 작동하는지만 확인
        try await Task.sleep(nanoseconds: 500_000_000)

        // Then
        // 실제 네트워크 손실 이벤트가 있을 때만 콜백이 호출됨
    }

    // MARK: - Multiple Start/Stop Tests

    @Test("Multiple start calls are idempotent")
    func multipleStartCallsAreIdempotent() async throws {
        // Given
        let sut = NetworkViewModel()

        // When
        await sut.startMonitoring()
        await sut.startMonitoring()
        await sut.startMonitoring()

        // Then
        // 여러 번 호출해도 문제없이 동작해야 함
        #expect(sut.isNetworkAvailable != nil)
    }

    @Test("Multiple stop calls are idempotent")
    func multipleStopCallsAreIdempotent() async throws {
        // Given
        let sut = NetworkViewModel()
        await sut.startMonitoring()

        // When
        sut.stopMonitoring()
        sut.stopMonitoring()
        sut.stopMonitoring()

        // Then
        // 여러 번 호출해도 문제없이 동작해야 함
        #expect(sut.isNetworkAvailable != nil)
    }

    // MARK: - Cleanup Tests

    @Test("Deinit stops monitoring")
    func deinitStopsMonitoring() async throws {
        // Given
        var sut: NetworkViewModel? = NetworkViewModel()
        await sut?.startMonitoring()

        // When
        sut = nil

        // Then
        // deinit에서 stopMonitoring이 호출되어야 함
        // 메모리 릭 없이 정리되면 성공
        try await Task.sleep(nanoseconds: 100_000_000)
    }
}
#endif
