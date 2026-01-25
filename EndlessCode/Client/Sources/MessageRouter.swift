//
//  MessageRouter.swift
//  EndlessCode
//
//  수신 메시지 타입별 라우팅
//

import Foundation

// MARK: - MessageRouterProtocol

/// 메시지 라우터 프로토콜
protocol MessageRouterProtocol: Sendable {
    /// CLI 출력 메시지 스트림
    var cliOutputs: AsyncStream<CLIOutput> { get }

    /// 세션 상태 변경 스트림
    var sessionStates: AsyncStream<SessionStateMessage> { get }

    /// 프롬프트 요청 스트림
    var promptRequests: AsyncStream<PromptRequest> { get }

    /// 에러 메시지 스트림
    var errors: AsyncStream<ErrorMessage> { get }

    /// 동기화 메시지 스트림
    var syncs: AsyncStream<SyncMessage> { get }

    /// 라우팅 시작
    func start() async

    /// 라우팅 중지
    func stop() async
}

// MARK: - MessageRouter

/// 메시지 라우터 구현
/// ConnectionManager로부터 메시지를 받아 타입별로 분류하여 스트림으로 발행
actor MessageRouter: MessageRouterProtocol {
    // MARK: - Properties

    private let connectionManager: any ConnectionManagerProtocol
    private var routingTask: Task<Void, Never>?

    // CLI Output
    private let cliOutputContinuation: AsyncStream<CLIOutput>.Continuation
    private let _cliOutputs: AsyncStream<CLIOutput>

    // Session State
    private let sessionStateContinuation: AsyncStream<SessionStateMessage>.Continuation
    private let _sessionStates: AsyncStream<SessionStateMessage>

    // Prompt Request
    private let promptRequestContinuation: AsyncStream<PromptRequest>.Continuation
    private let _promptRequests: AsyncStream<PromptRequest>

    // Error
    private let errorContinuation: AsyncStream<ErrorMessage>.Continuation
    private let _errors: AsyncStream<ErrorMessage>

    // Sync
    private let syncContinuation: AsyncStream<SyncMessage>.Continuation
    private let _syncs: AsyncStream<SyncMessage>

    // MARK: - Initialization

    init(connectionManager: any ConnectionManagerProtocol) {
        self.connectionManager = connectionManager

        var cliCont: AsyncStream<CLIOutput>.Continuation!
        self._cliOutputs = AsyncStream { cont in
            cliCont = cont
        }
        self.cliOutputContinuation = cliCont

        var sessionCont: AsyncStream<SessionStateMessage>.Continuation!
        self._sessionStates = AsyncStream { cont in
            sessionCont = cont
        }
        self.sessionStateContinuation = sessionCont

        var promptCont: AsyncStream<PromptRequest>.Continuation!
        self._promptRequests = AsyncStream { cont in
            promptCont = cont
        }
        self.promptRequestContinuation = promptCont

        var errorCont: AsyncStream<ErrorMessage>.Continuation!
        self._errors = AsyncStream { cont in
            errorCont = cont
        }
        self.errorContinuation = errorCont

        var syncCont: AsyncStream<SyncMessage>.Continuation!
        self._syncs = AsyncStream { cont in
            syncCont = cont
        }
        self.syncContinuation = syncCont
    }

    deinit {
        cliOutputContinuation.finish()
        sessionStateContinuation.finish()
        promptRequestContinuation.finish()
        errorContinuation.finish()
        syncContinuation.finish()
    }

    // MARK: - MessageRouterProtocol

    nonisolated var cliOutputs: AsyncStream<CLIOutput> {
        _cliOutputs
    }

    nonisolated var sessionStates: AsyncStream<SessionStateMessage> {
        _sessionStates
    }

    nonisolated var promptRequests: AsyncStream<PromptRequest> {
        _promptRequests
    }

    nonisolated var errors: AsyncStream<ErrorMessage> {
        _errors
    }

    nonisolated var syncs: AsyncStream<SyncMessage> {
        _syncs
    }

    func start() async {
        await stop()

        routingTask = Task { [weak self] in
            guard let self = self else { return }

            for await message in self.connectionManager.messages {
                guard !Task.isCancelled else { break }
                await self.route(message)
            }
        }
    }

    func stop() async {
        routingTask?.cancel()
        routingTask = nil
    }

    // MARK: - Private Methods

    private func route(_ message: ServerMessage) {
        switch message {
        case .cliOutput(let output):
            cliOutputContinuation.yield(output)

        case .sessionState(let state):
            sessionStateContinuation.yield(state)

        case .promptRequest(let request):
            promptRequestContinuation.yield(request)

        case .error(let error):
            errorContinuation.yield(error)

        case .sync(let sync):
            syncContinuation.yield(sync)
        }
    }
}

// MARK: - Convenience Extensions

extension MessageRouter {
    /// 특정 세션의 CLI 출력만 필터링
    nonisolated func cliOutputs(for sessionId: String) -> AsyncFilterSequence<AsyncStream<CLIOutput>> {
        cliOutputs.filter { $0.sessionId == sessionId }
    }

    /// 특정 세션의 상태 변경만 필터링
    nonisolated func sessionStates(for sessionId: String) -> AsyncFilterSequence<AsyncStream<SessionStateMessage>> {
        sessionStates.filter { $0.sessionId == sessionId }
    }

    /// 특정 세션의 프롬프트 요청만 필터링
    nonisolated func promptRequests(for sessionId: String) -> AsyncFilterSequence<AsyncStream<PromptRequest>> {
        promptRequests.filter { $0.sessionId == sessionId }
    }

    /// 특정 세션의 에러만 필터링
    nonisolated func errors(for sessionId: String) -> AsyncFilterSequence<AsyncStream<ErrorMessage>> {
        errors.filter { $0.sessionId == sessionId }
    }
}

// MARK: - MessageHandler

/// 메시지 핸들러 - 특정 타입의 메시지를 처리하는 클로저를 등록
actor MessageHandler {
    typealias CLIOutputHandler = @Sendable (CLIOutput) async -> Void
    typealias SessionStateHandler = @Sendable (SessionStateMessage) async -> Void
    typealias PromptRequestHandler = @Sendable (PromptRequest) async -> Void
    typealias ErrorHandler = @Sendable (ErrorMessage) async -> Void
    typealias SyncHandler = @Sendable (SyncMessage) async -> Void

    private let router: MessageRouter
    private var handlerTasks: [Task<Void, Never>] = []

    init(router: MessageRouter) {
        self.router = router
    }

    deinit {
        for task in handlerTasks {
            task.cancel()
        }
    }

    /// CLI 출력 핸들러 등록
    func onCLIOutput(_ handler: @escaping CLIOutputHandler) {
        let task = Task {
            for await output in router.cliOutputs {
                guard !Task.isCancelled else { break }
                await handler(output)
            }
        }
        handlerTasks.append(task)
    }

    /// 세션 상태 핸들러 등록
    func onSessionState(_ handler: @escaping SessionStateHandler) {
        let task = Task {
            for await state in router.sessionStates {
                guard !Task.isCancelled else { break }
                await handler(state)
            }
        }
        handlerTasks.append(task)
    }

    /// 프롬프트 요청 핸들러 등록
    func onPromptRequest(_ handler: @escaping PromptRequestHandler) {
        let task = Task {
            for await request in router.promptRequests {
                guard !Task.isCancelled else { break }
                await handler(request)
            }
        }
        handlerTasks.append(task)
    }

    /// 에러 핸들러 등록
    func onError(_ handler: @escaping ErrorHandler) {
        let task = Task {
            for await error in router.errors {
                guard !Task.isCancelled else { break }
                await handler(error)
            }
        }
        handlerTasks.append(task)
    }

    /// 동기화 핸들러 등록
    func onSync(_ handler: @escaping SyncHandler) {
        let task = Task {
            for await sync in router.syncs {
                guard !Task.isCancelled else { break }
                await handler(sync)
            }
        }
        handlerTasks.append(task)
    }

    /// 모든 핸들러 해제
    func removeAllHandlers() {
        for task in handlerTasks {
            task.cancel()
        }
        handlerTasks.removeAll()
    }
}
