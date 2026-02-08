//
//  SortFilterModels.swift
//  EndlessCode
//
//  정렬/필터 관련 모델 타입 (ProjectSortOrder, SessionSortOrder)
//

import Foundation

// MARK: - ProjectSortOrder

/// 프로젝트 정렬 순서
enum ProjectSortOrder: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case name = "Name"
    case sessionCount = "Sessions"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .recent:
            return "clock"
        case .name:
            return "textformat.abc"
        case .sessionCount:
            return "bubble.left.and.bubble.right"
        }
    }
}

// MARK: - SessionSortOrder

/// 세션 정렬 순서
enum SessionSortOrder: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case project = "Project"
    case messageCount = "Messages"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .recent:
            return "clock"
        case .project:
            return "folder"
        case .messageCount:
            return "text.bubble"
        }
    }
}
