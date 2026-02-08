//
//  AppLifecycleManager.swift
//  EndlessCode
//
//  앱 생명주기 관리 - 백그라운드/포그라운드 전환 처리
//  UIApplication notifications 감시 및 이벤트 발행
//

#if os(iOS)
import Foundation
import UIKit

// MARK: - AppLifecycleEvent

/// 앱 생명주기 이벤트
enum AppLifecycleEvent: Sendable, Equatable {
    /// 앱이 비활성화될 예정 (전화, 알림 등)
    case willResignActive

    /// 앱이 백그라운드로 진입함
    case didEnterBackground

    /// 앱이 포그라운드로 진입할 예정
    case willEnterForeground

    /// 앱이 활성화됨
    case didBecomeActive
}

// MARK: - AppLifecycleManagerProtocol

/// 앱 생명주기 관리자 프로토콜
protocol AppLifecycleManagerProtocol: Sendable {
    /// 생명주기 이벤트 스트림
    var lifecycleEvents: AsyncStream<AppLifecycleEvent> { get }

    /// 모니터링 시작
    func start() async

    /// 모니터링 중지
    func stop() async
}

// MARK: - AppLifecycleManager

/// 앱 생명주기 관리자 구현
actor AppLifecycleManager: AppLifecycleManagerProtocol {
    // MARK: - Properties

    private var isMonitoring: Bool = false
    private var observers: [NSObjectProtocol] = []
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    private let eventContinuation: AsyncStream<AppLifecycleEvent>.Continuation
    private let _lifecycleEvents: AsyncStream<AppLifecycleEvent>

    // MARK: - Initialization

    init() {
        let (stream, continuation) = AsyncStream.makeStream(of: AppLifecycleEvent.self)
        self._lifecycleEvents = stream
        self.eventContinuation = continuation
    }

    deinit {
        let notificationCenter = NotificationCenter.default
        for observer in observers {
            notificationCenter.removeObserver(observer)
        }
        eventContinuation.finish()
    }

    // MARK: - AppLifecycleManagerProtocol

    nonisolated var lifecycleEvents: AsyncStream<AppLifecycleEvent> {
        _lifecycleEvents
    }

    func start() async {
        guard !isMonitoring else { return }
        isMonitoring = true

        await registerNotifications()
    }

    func stop() async {
        guard isMonitoring else { return }
        isMonitoring = false

        await cleanup()
    }

    // MARK: - Private Methods

    private func registerNotifications() async {
        let notificationCenter = NotificationCenter.default

        // willResignActive
        let willResignActiveObserver = notificationCenter.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleWillResignActive()
            }
        }
        observers.append(willResignActiveObserver)

        // didEnterBackground
        let didEnterBackgroundObserver = notificationCenter.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleDidEnterBackground()
            }
        }
        observers.append(didEnterBackgroundObserver)

        // willEnterForeground
        let willEnterForegroundObserver = notificationCenter.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleWillEnterForeground()
            }
        }
        observers.append(willEnterForegroundObserver)

        // didBecomeActive
        let didBecomeActiveObserver = notificationCenter.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleDidBecomeActive()
            }
        }
        observers.append(didBecomeActiveObserver)
    }

    private func cleanup() async {
        let notificationCenter = NotificationCenter.default
        for observer in observers {
            notificationCenter.removeObserver(observer)
        }
        observers.removeAll()

        await endBackgroundTask()

        eventContinuation.finish()
    }

    private func handleWillResignActive() {
        eventContinuation.yield(.willResignActive)
    }

    private func handleDidEnterBackground() {
        // 백그라운드 태스크 시작 - 연결 상태 유지 시도
        Task {
            await beginBackgroundTask()
        }

        eventContinuation.yield(.didEnterBackground)
    }

    private func handleWillEnterForeground() {
        // 백그라운드 태스크 종료
        Task {
            await endBackgroundTask()
        }

        eventContinuation.yield(.willEnterForeground)
    }

    private func handleDidBecomeActive() {
        eventContinuation.yield(.didBecomeActive)
    }

    private func beginBackgroundTask() async {
        guard backgroundTaskID == .invalid else { return }

        backgroundTaskID = await UIApplication.shared.beginBackgroundTask { [weak self] in
            Task {
                await self?.endBackgroundTask()
            }
        }
    }

    private func endBackgroundTask() async {
        guard backgroundTaskID != .invalid else { return }

        await UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
    }
}
#endif
