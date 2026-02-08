//
//  NavigationModels.swift
//  EndlessCode
//
//  Navigation 관련 모델 타입 (AppTab, NavigationDestination, SheetDestination, AlertDestination, ServerState)
//

import Foundation

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

// MARK: - ServerState

/// 서버 상태
enum ServerState: Equatable {
    case running
    case stopped
    case error(String)
}
