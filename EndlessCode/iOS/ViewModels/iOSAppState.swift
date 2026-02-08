//
//  iOSAppState.swift
//  EndlessCode
//
//  iOS 전용 앱 상태 관리
//

#if os(iOS)
import Foundation
import Observation

// MARK: - iOSTab

/// iOS 탭 타입
enum iOSTab: String, CaseIterable, Identifiable {
    case projects = "Projects"
    case chat = "Chat"
    case files = "Files"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .projects: return "folder.fill"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .files: return "doc.text.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - iOSAppState

/// iOS 앱 전역 상태
@Observable @MainActor
final class iOSAppState {
    // MARK: Navigation
    var selectedTab: iOSTab = .projects
    var selectedProject: Project?
    var selectedSession: Session?

    // MARK: Connection
    var connectionState: ConnectionState = .disconnected
    var serverURL: String?

    // MARK: Data
    var projects: [Project] = []
    var activeSessions: [Session] = []
    var messages: [ChatMessageItem] = []

    // MARK: UI State
    var errorMessage: String?
    var toastMessage: String?
    var isLoading: Bool = false

    // MARK: - Methods

    /// 프로젝트 선택
    func selectProject(_ project: Project) {
        selectedProject = project
        selectedSession = nil
        messages = []
    }

    /// 세션 선택
    func selectSession(_ session: Session) {
        selectedSession = session
        selectedTab = .chat
        // 메시지 로드 (실제로는 서버에서 가져옴)
        loadMessages(for: session)
    }

    /// 메시지 로드 (Mock)
    private func loadMessages(for session: Session) {
        // 실제 구현에서는 서버에서 메시지를 가져옴
        // 여기서는 샘플 데이터 사용
        messages = ChatMessageItem.sampleMessages
    }

    /// 에러 표시
    func showError(_ message: String) {
        errorMessage = message
    }

    /// 토스트 표시
    private var toastTask: Task<Void, Never>?

    func showToast(_ message: String) {
        toastTask?.cancel()
        toastMessage = message
        toastTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            toastMessage = nil
        }
    }

    /// 에러 메시지 초기화
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Sample Data

extension iOSAppState {
    /// 샘플 데이터로 초기화된 상태 (프리뷰용)
    static var preview: iOSAppState {
        let state = iOSAppState()
        state.connectionState = .connected
        state.projects = [
            Project(
                id: "proj-1",
                name: "DashboardApp",
                path: "/Users/demo/projects/DashboardApp",
                sessionCount: 3,
                lastUsed: Date().addingTimeInterval(-3600)
            ),
            Project(
                id: "proj-2",
                name: "ChatBot",
                path: "/Users/demo/projects/ChatBot",
                sessionCount: 1,
                lastUsed: Date().addingTimeInterval(-7200)
            ),
            Project(
                id: "proj-3",
                name: "EndlessCode",
                path: "/Users/demo/projects/EndlessCode",
                sessionCount: 5,
                lastUsed: Date()
            )
        ]
        state.activeSessions = [
            Session(
                id: "sess-1",
                projectId: "proj-1",
                state: .active,
                createdAt: Date().addingTimeInterval(-86400),
                lastActiveAt: Date().addingTimeInterval(-3600),
                messageCount: 42
            ),
            Session(
                id: "sess-2",
                projectId: "proj-1",
                state: .paused,
                createdAt: Date().addingTimeInterval(-172800),
                lastActiveAt: Date().addingTimeInterval(-7200),
                messageCount: 15
            )
        ]
        return state
    }
}
#endif
