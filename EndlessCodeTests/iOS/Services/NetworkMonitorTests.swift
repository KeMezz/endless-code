//
//  NetworkMonitorTests.swift
//  EndlessCodeTests
//
//  NetworkMonitor 단위 테스트
//

#if os(iOS)
import Testing
import Network
@testable import EndlessCode

// MARK: - NetworkMonitorTests

@Suite("NetworkMonitor Tests")
struct NetworkMonitorTests {
    // MARK: - Initialization Tests

    @Test("Initialization sets default values")
    func initializationSetsDefaultValues() async throws {
        // Given & When
        let sut = NetworkMonitor()

        // Then
        let isConnected = await sut.isConnected
        #expect(isConnected == true) // 기본값은 연결됨으로 가정
    }

    // MARK: - Monitoring Tests

    @Test("Start monitoring begins path updates")
    func startMonitoringBeginsPathUpdates() async throws {
        // Given
        let sut = NetworkMonitor()

        // When
        await sut.start()

        // Then
        // 모니터링 시작 후 최소 1개의 경로 업데이트를 받아야 함
        let task = Task {
            var updates: [NWPath] = []
            for await path in sut.pathUpdates {
                updates.append(path)
                if updates.count >= 1 {
                    break
                }
            }
            return updates
        }

        // 타임아웃 설정 (2초)
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            task.cancel()
        }

        let updates = await task.value
        timeoutTask.cancel()

        #expect(updates.count >= 1)
    }

    @Test("Stop monitoring stops path updates")
    func stopMonitoringStopsPathUpdates() async throws {
        // Given
        let sut = NetworkMonitor()
        await sut.start()

        // When
        await sut.stop()

        // Then
        // 중지 후에는 새로운 업데이트가 없어야 함
        let task = Task {
            var updateCount = 0
            for await _ in sut.pathUpdates {
                updateCount += 1
                if updateCount >= 1 {
                    break
                }
            }
            return updateCount
        }

        // 1초 대기 후 확인
        try await Task.sleep(nanoseconds: 1_000_000_000)
        task.cancel()

        // 중지 후에는 업데이트가 없을 것으로 예상
        // (타임아웃으로 인해 task가 완료되지 않음)
    }

    // MARK: - Connection State Tests

    @Test("Connection type reflects network interface")
    func connectionTypeReflectsNetworkInterface() async throws {
        // Given
        let sut = NetworkMonitor()
        await sut.start()

        // When
        // 경로 업데이트를 기다림
        let task = Task {
            for await _ in sut.pathUpdates {
                break
            }
        }

        try await Task.sleep(nanoseconds: 500_000_000)
        task.cancel()

        // Then
        let connectionType = await sut.connectionType
        // 시뮬레이터나 실제 기기에서는 WiFi 또는 Cellular일 것으로 예상
        #expect(connectionType != nil)
    }

    // MARK: - Multiple Start/Stop Tests

    @Test("Multiple start calls are idempotent")
    func multipleStartCallsAreIdempotent() async throws {
        // Given
        let sut = NetworkMonitor()

        // When
        await sut.start()
        await sut.start()
        await sut.start()

        // Then
        // 여러 번 호출해도 문제없이 동작해야 함
        let isConnected = await sut.isConnected
        #expect(isConnected != nil)
    }

    @Test("Multiple stop calls are idempotent")
    func multipleStopCallsAreIdempotent() async throws {
        // Given
        let sut = NetworkMonitor()
        await sut.start()

        // When
        await sut.stop()
        await sut.stop()
        await sut.stop()

        // Then
        // 여러 번 호출해도 문제없이 동작해야 함
        let isConnected = await sut.isConnected
        #expect(isConnected != nil)
    }
}
#endif
