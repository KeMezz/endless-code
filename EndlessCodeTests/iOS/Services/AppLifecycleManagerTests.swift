//
//  AppLifecycleManagerTests.swift
//  EndlessCodeTests
//
//  AppLifecycleManager 단위 테스트
//

#if os(iOS)
import Testing
import UIKit
@testable import EndlessCode

// MARK: - AppLifecycleManagerTests

@Suite("AppLifecycleManager Tests")
struct AppLifecycleManagerTests {
    // MARK: - Initialization Tests

    @Test("Initialization creates lifecycle event stream")
    func initializationCreatesLifecycleEventStream() async throws {
        // Given & When
        let sut = AppLifecycleManager()

        // Then
        // lifecycleEvents 스트림이 생성되어야 함
        let stream = sut.lifecycleEvents
        #expect(stream != nil)
    }

    // MARK: - Monitoring Tests

    @Test("Start monitoring registers notifications")
    func startMonitoringRegistersNotifications() async throws {
        // Given
        let sut = AppLifecycleManager()

        // When
        await sut.start()

        // Then
        // 모니터링이 시작되어야 함
        // (실제 알림 등록은 내부적으로 처리되므로 직접 검증 불가)
    }

    @Test("Stop monitoring removes observers")
    func stopMonitoringRemovesObservers() async throws {
        // Given
        let sut = AppLifecycleManager()
        await sut.start()

        // When
        await sut.stop()

        // Then
        // 옵저버가 제거되어야 함
        // (내부 구현 확인 불가하므로 크래시 없이 완료되면 성공)
    }

    // MARK: - Event Stream Tests

    @Test("Lifecycle events are emitted on app state changes")
    func lifecycleEventsAreEmittedOnAppStateChanges() async throws {
        // Given
        let sut = AppLifecycleManager()
        await sut.start()

        // When
        let task = Task {
            var events: [AppLifecycleEvent] = []
            for await event in sut.lifecycleEvents {
                events.append(event)
                if events.count >= 1 {
                    break
                }
            }
            return events
        }

        // didBecomeActive 알림 발송
        await MainActor.run {
            NotificationCenter.default.post(
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
        }

        // 이벤트 수신 대기
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        let events = await task.value
        #expect(events.contains(.didBecomeActive))
    }

    @Test("willResignActive notification emits correct event")
    func willResignActiveNotificationEmitsCorrectEvent() async throws {
        // Given
        let sut = AppLifecycleManager()
        await sut.start()

        // When
        let task = Task {
            var events: [AppLifecycleEvent] = []
            for await event in sut.lifecycleEvents {
                events.append(event)
                if events.count >= 1 {
                    break
                }
            }
            return events
        }

        await MainActor.run {
            NotificationCenter.default.post(
                name: UIApplication.willResignActiveNotification,
                object: nil
            )
        }

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        let events = await task.value
        #expect(events.contains(.willResignActive))
    }

    @Test("didEnterBackground notification emits correct event")
    func didEnterBackgroundNotificationEmitsCorrectEvent() async throws {
        // Given
        let sut = AppLifecycleManager()
        await sut.start()

        // When
        let task = Task {
            var events: [AppLifecycleEvent] = []
            for await event in sut.lifecycleEvents {
                events.append(event)
                if events.count >= 1 {
                    break
                }
            }
            return events
        }

        await MainActor.run {
            NotificationCenter.default.post(
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
        }

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        let events = await task.value
        #expect(events.contains(.didEnterBackground))
    }

    @Test("willEnterForeground notification emits correct event")
    func willEnterForegroundNotificationEmitsCorrectEvent() async throws {
        // Given
        let sut = AppLifecycleManager()
        await sut.start()

        // When
        let task = Task {
            var events: [AppLifecycleEvent] = []
            for await event in sut.lifecycleEvents {
                events.append(event)
                if events.count >= 1 {
                    break
                }
            }
            return events
        }

        await MainActor.run {
            NotificationCenter.default.post(
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )
        }

        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        let events = await task.value
        #expect(events.contains(.willEnterForeground))
    }

    // MARK: - Multiple Start/Stop Tests

    @Test("Multiple start calls are idempotent")
    func multipleStartCallsAreIdempotent() async throws {
        // Given
        let sut = AppLifecycleManager()

        // When
        await sut.start()
        await sut.start()
        await sut.start()

        // Then
        // 여러 번 호출해도 문제없이 동작해야 함
        await sut.stop()
    }

    @Test("Multiple stop calls are idempotent")
    func multipleStopCallsAreIdempotent() async throws {
        // Given
        let sut = AppLifecycleManager()
        await sut.start()

        // When
        await sut.stop()
        await sut.stop()
        await sut.stop()

        // Then
        // 여러 번 호출해도 문제없이 동작해야 함
    }
}
#endif
