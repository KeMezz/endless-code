//
//  AppState.swift
//  EndlessCode
//
//  앱 전역 상태 관리 - @Observable 모델
//

import Foundation
import SwiftUI

// MARK: - AppState

/// 앱 전역 상태
@Observable @MainActor
final class AppState {
    // MARK: - Properties

    /// 현재 선택된 탭
    var selectedTab: AppTab = .projects

    /// 현재 선택된 프로젝트
    var selectedProject: Project?

    /// 현재 선택된 세션
    var selectedSession: Session?

    /// 연결 상태
    var connectionState: ConnectionState = .disconnected

    /// 활성 세션 목록
    var activeSessions: [Session] = []

    /// 프로젝트 목록
    var projects: [Project] = []

    /// 에러 메시지 (일시적)
    var errorMessage: String?

    /// 알림 메시지 (일시적)
    var toastMessage: String?

    // MARK: - Initialization

    init() {}

    // MARK: - Methods

    /// 프로젝트 선택
    func selectProject(_ project: Project) {
        selectedProject = project
        selectedSession = nil
    }

    /// 세션 선택
    func selectSession(_ session: Session) {
        selectedSession = session
    }

    /// 에러 표시
    func showError(_ message: String) {
        errorMessage = message
    }

    /// 에러 해제
    func dismissError() {
        errorMessage = nil
    }

    /// 토스트 표시
    func showToast(_ message: String) {
        toastMessage = message

        // 3초 후 자동 해제
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            if self.toastMessage == message {
                self.toastMessage = nil
            }
        }
    }

    /// 토스트 해제
    func dismissToast() {
        toastMessage = nil
    }
}

// MARK: - AppTab

/// 앱 탭
enum AppTab: String, CaseIterable, Identifiable {
    case projects = "Projects"
    case sessions = "Sessions"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .projects:
            return "folder.fill"
        case .sessions:
            return "bubble.left.and.bubble.right.fill"
        case .settings:
            return "gearshape.fill"
        }
    }

    var title: String {
        rawValue
    }
}

// MARK: - Navigation Destination

/// 네비게이션 목적지
enum NavigationDestination: Hashable {
    case projectDetail(Project)
    case sessionDetail(Session)
    case chatView(Session)
    case fileExplorer(Project)
    case settings

    var id: String {
        switch self {
        case .projectDetail(let project):
            return "project-\(project.id)"
        case .sessionDetail(let session):
            return "session-detail-\(session.id)"
        case .chatView(let session):
            return "chat-\(session.id)"
        case .fileExplorer(let project):
            return "files-\(project.id)"
        case .settings:
            return "settings"
        }
    }
}

// MARK: - AppRouter

/// 앱 라우터 - 화면 전환, 딥링크 처리
@Observable @MainActor
final class AppRouter {
    // MARK: - Properties

    /// 현재 네비게이션 경로
    var path: [NavigationDestination] = []

    /// 현재 시트
    var presentedSheet: SheetDestination?

    /// 현재 알림
    var presentedAlert: AlertDestination?

    // MARK: - Navigation Methods

    /// 화면 이동
    func navigate(to destination: NavigationDestination) {
        path.append(destination)
    }

    /// 뒤로 가기
    func goBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    /// 루트로 이동
    func goToRoot() {
        path.removeAll()
    }

    /// 시트 표시
    func presentSheet(_ sheet: SheetDestination) {
        presentedSheet = sheet
    }

    /// 시트 해제
    func dismissSheet() {
        presentedSheet = nil
    }

    /// 알림 표시
    func presentAlert(_ alert: AlertDestination) {
        presentedAlert = alert
    }

    /// 알림 해제
    func dismissAlert() {
        presentedAlert = nil
    }

    // MARK: - Deep Link Handling

    /// 딥링크 처리
    func handleDeepLink(_ url: URL) {
        guard let host = url.host else { return }

        switch host {
        case "project":
            if let projectId = url.pathComponents.dropFirst().first {
                // 프로젝트 딥링크: endlesscode://project/{projectId}
                // 실제 구현에서는 프로젝트를 조회하여 navigate
                print("Deep link to project: \(projectId)")
            }
        case "session":
            if let sessionId = url.pathComponents.dropFirst().first {
                // 세션 딥링크: endlesscode://session/{sessionId}
                print("Deep link to session: \(sessionId)")
            }
        default:
            break
        }
    }
}

// MARK: - Sheet Destination

/// 시트 목적지
enum SheetDestination: Identifiable {
    case newSession(Project)
    case projectSettings(Project)
    case connectionSettings
    case diffViewer(UnifiedDiff)

    var id: String {
        switch self {
        case .newSession(let project):
            return "new-session-\(project.id)"
        case .projectSettings(let project):
            return "project-settings-\(project.id)"
        case .connectionSettings:
            return "connection-settings"
        case .diffViewer(let diff):
            return "diff-viewer-\(diff.id)"
        }
    }
}

// MARK: - Alert Destination

/// 알림 목적지
enum AlertDestination: Identifiable {
    case confirmEndSession(Session)
    case confirmDeleteProject(Project)
    case error(String)

    var id: String {
        switch self {
        case .confirmEndSession(let session):
            return "confirm-end-\(session.id)"
        case .confirmDeleteProject(let project):
            return "confirm-delete-\(project.id)"
        case .error(let message):
            return "error-\(message.hashValue)"
        }
    }
}
