//
//  PromptManager.swift
//  EndlessCode
//
//  대화형 프롬프트 관리 - AskUserQuestion 감지, 상태 관리, 응답 주입, 타임아웃
//

import Foundation

// MARK: - PromptState

/// 프롬프트 상태
enum PromptState: Sendable {
    case pending
    case responded(response: String)
    case timedOut
    case cancelled
}

extension PromptState: Equatable {
    nonisolated static func == (lhs: PromptState, rhs: PromptState) -> Bool {
        switch (lhs, rhs) {
        case (.pending, .pending):
            return true
        case (.responded(let l), .responded(let r)):
            return l == r
        case (.timedOut, .timedOut):
            return true
        case (.cancelled, .cancelled):
            return true
        default:
            return false
        }
    }
}

// MARK: - PendingPrompt

/// 대기 중인 프롬프트
struct PendingPrompt: Sendable, Identifiable {
    let id: String
    let sessionId: String
    let toolUseId: String
    let question: AskUserQuestion
    let createdAt: Date
    let expiresAt: Date
    var state: PromptState
}

// MARK: - PromptManagerProtocol

/// 프롬프트 관리자 프로토콜
protocol PromptManagerProtocol: Sendable {
    func registerPrompt(
        sessionId: String,
        question: AskUserQuestion
    ) async -> PendingPrompt

    func respondToPrompt(
        promptId: String,
        selectedOptions: [String],
        customInput: String?
    ) async throws -> String

    func cancelPrompt(promptId: String) async throws
    func getPendingPrompts(sessionId: String) async -> [PendingPrompt]
    func cleanupExpiredPrompts() async -> [PendingPrompt]
}

// MARK: - PromptManager

/// 대화형 프롬프트를 관리하는 Actor
actor PromptManager: PromptManagerProtocol {
    private var pendingPrompts: [String: PendingPrompt] = [:]
    private let timeoutSeconds: Int
    private var timeoutTasks: [String: Task<Void, Never>] = [:]

    /// 프롬프트 상태 변경 콜백
    private var stateChangeCallbacks: [(PendingPrompt) async -> Void] = []

    init(timeoutSeconds: Int = 1800) { // 30분 기본값
        self.timeoutSeconds = timeoutSeconds
    }

    // MARK: - Public API

    func registerPrompt(
        sessionId: String,
        question: AskUserQuestion
    ) async -> PendingPrompt {
        let promptId = UUID().uuidString
        let now = Date()
        let expiresAt = now.addingTimeInterval(TimeInterval(timeoutSeconds))

        let prompt = PendingPrompt(
            id: promptId,
            sessionId: sessionId,
            toolUseId: question.toolUseId,
            question: question,
            createdAt: now,
            expiresAt: expiresAt,
            state: .pending
        )

        pendingPrompts[promptId] = prompt

        // 타임아웃 타스크 시작
        startTimeoutTask(for: promptId)

        return prompt
    }

    func respondToPrompt(
        promptId: String,
        selectedOptions: [String],
        customInput: String?
    ) async throws -> String {
        guard var prompt = pendingPrompts[promptId] else {
            throw PromptError.promptNotFound(promptId: promptId)
        }

        guard prompt.state == .pending else {
            throw PromptError.promptNotPending(promptId: promptId, currentState: prompt.state)
        }

        // 응답 포맷팅
        let formattedResponse = formatResponse(
            question: prompt.question,
            selectedOptions: selectedOptions,
            customInput: customInput
        )

        // 상태 업데이트
        prompt.state = .responded(response: formattedResponse)
        pendingPrompts[promptId] = prompt

        // 타임아웃 타스크 취소
        cancelTimeoutTask(for: promptId)

        // 콜백 호출
        await notifyStateChange(prompt)

        return formattedResponse
    }

    func cancelPrompt(promptId: String) async throws {
        guard var prompt = pendingPrompts[promptId] else {
            throw PromptError.promptNotFound(promptId: promptId)
        }

        guard prompt.state == .pending else {
            throw PromptError.promptNotPending(promptId: promptId, currentState: prompt.state)
        }

        prompt.state = .cancelled
        pendingPrompts[promptId] = prompt

        cancelTimeoutTask(for: promptId)
        await notifyStateChange(prompt)
    }

    func getPendingPrompts(sessionId: String) async -> [PendingPrompt] {
        pendingPrompts.values
            .filter { $0.sessionId == sessionId && $0.state == .pending }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func getAllPendingPrompts() async -> [PendingPrompt] {
        pendingPrompts.values
            .filter { $0.state == .pending }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func getPrompt(id: String) async -> PendingPrompt? {
        pendingPrompts[id]
    }

    func cleanupExpiredPrompts() async -> [PendingPrompt] {
        let now = Date()
        var expiredPrompts: [PendingPrompt] = []

        for (promptId, prompt) in pendingPrompts {
            if prompt.state == .pending && prompt.expiresAt < now {
                var updatedPrompt = prompt
                updatedPrompt.state = .timedOut
                pendingPrompts[promptId] = updatedPrompt
                expiredPrompts.append(updatedPrompt)
            }
        }

        return expiredPrompts
    }

    // MARK: - Callbacks

    func onStateChange(_ callback: @escaping (PendingPrompt) async -> Void) {
        stateChangeCallbacks.append(callback)
    }

    private func notifyStateChange(_ prompt: PendingPrompt) async {
        for callback in stateChangeCallbacks {
            await callback(prompt)
        }
    }

    // MARK: - Response Formatting

    private func formatResponse(
        question: AskUserQuestion,
        selectedOptions: [String],
        customInput: String?
    ) -> String {
        // 직접 입력이 있으면 우선 사용
        if let custom = customInput, !custom.isEmpty {
            return formatAsToolResult(toolUseId: question.toolUseId, response: custom)
        }

        // 선택된 옵션 처리
        let response: String
        if selectedOptions.isEmpty {
            response = ""
        } else if selectedOptions.count == 1 {
            response = selectedOptions[0]
        } else {
            // 멀티 셀렉트의 경우 JSON 배열로 변환
            if question.multiSelect {
                response = formatMultiSelectResponse(selectedOptions)
            } else {
                response = selectedOptions.joined(separator: ", ")
            }
        }

        return formatAsToolResult(toolUseId: question.toolUseId, response: response)
    }

    private func formatMultiSelectResponse(_ options: [String]) -> String {
        // JSON 배열 형식으로 변환
        if let data = try? JSONEncoder().encode(options),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        return options.joined(separator: ", ")
    }

    private func formatAsToolResult(toolUseId: String, response: String) -> String {
        // Claude CLI가 기대하는 tool_result 형식
        let result: [String: Any] = [
            "type": "tool_result",
            "tool_use_id": toolUseId,
            "content": response
        ]

        if let data = try? JSONSerialization.data(withJSONObject: result),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }

        return response
    }

    // MARK: - Timeout Management

    private func startTimeoutTask(for promptId: String) {
        let task = Task { [weak self, timeoutSeconds] in
            try? await Task.sleep(for: .seconds(timeoutSeconds))

            guard !Task.isCancelled else { return }

            await self?.handleTimeout(promptId: promptId)
        }

        timeoutTasks[promptId] = task
    }

    private func cancelTimeoutTask(for promptId: String) {
        timeoutTasks[promptId]?.cancel()
        timeoutTasks.removeValue(forKey: promptId)
    }

    private func handleTimeout(promptId: String) async {
        guard var prompt = pendingPrompts[promptId],
              prompt.state == .pending else {
            return
        }

        prompt.state = .timedOut
        pendingPrompts[promptId] = prompt
        timeoutTasks.removeValue(forKey: promptId)

        await notifyStateChange(prompt)
    }

    // MARK: - Cleanup

    func cleanup(sessionId: String) async {
        let promptsToCleanup = pendingPrompts.values.filter { $0.sessionId == sessionId }

        for prompt in promptsToCleanup {
            cancelTimeoutTask(for: prompt.id)
            pendingPrompts.removeValue(forKey: prompt.id)
        }
    }

    func cleanupAll() async {
        for promptId in timeoutTasks.keys {
            cancelTimeoutTask(for: promptId)
        }
        pendingPrompts.removeAll()
    }
}

// MARK: - PromptError

/// 프롬프트 에러
enum PromptError: Error, Sendable {
    case promptNotFound(promptId: String)
    case promptNotPending(promptId: String, currentState: PromptState)
    case invalidResponse(reason: String)
    case timeout(promptId: String)
}

extension PromptError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .promptNotFound(let promptId):
            return "프롬프트를 찾을 수 없습니다: \(promptId)"
        case .promptNotPending(let promptId, let state):
            return "프롬프트가 대기 중이 아닙니다: \(promptId) (현재: \(state))"
        case .invalidResponse(let reason):
            return "잘못된 응답: \(reason)"
        case .timeout(let promptId):
            return "프롬프트 타임아웃: \(promptId)"
        }
    }
}

// MARK: - AskUserQuestion Detection

extension ParsedMessage {
    /// AskUserQuestion인지 확인
    var isAskUserQuestion: Bool {
        if case .askUser = self {
            return true
        }
        return false
    }

    /// AskUserQuestion 추출
    var askUserQuestion: AskUserQuestion? {
        if case .askUser(let question) = self {
            return question
        }
        return nil
    }
}
