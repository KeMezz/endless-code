//
//  WrapperViews.swift
//  EndlessCode
//
//  래퍼 뷰들 - 프로젝트 목록, 설정, 프로젝트 상세, 빈 디테일
//

import SwiftUI

// MARK: - ProjectListView

/// 프로젝트 목록 뷰 - ProjectBrowserView 사용
struct ProjectListView: View {
    var body: some View {
        ProjectBrowserView()
    }
}

// MARK: - SettingsListView

/// 설정 목록 뷰 - SettingsView 사용
struct SettingsListView: View {
    var body: some View {
        SettingsView()
    }
}

// MARK: - ProjectDetailView

/// 프로젝트 상세 뷰 - FileExplorerView 사용
struct ProjectDetailView: View {
    let project: Project

    var body: some View {
        FileExplorerView(project: project)
            .accessibilityIdentifier("projectDetail-\(project.id)")
    }
}

// MARK: - EmptyDetailView

/// 빈 디테일 뷰
struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Select a project or session")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Choose a project from the sidebar to start a new conversation with Claude.")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("emptyDetailView")
    }
}
