//
//  MainView.swift
//  EndlessCode
//
//  메인 뷰 - NavigationSplitView 기반 앱 구조
//

import SwiftUI

// MARK: - MainView

/// 메인 뷰 - 앱의 루트 뷰
struct MainView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var appState = appState
        @Bindable var router = router

        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } content: {
            ContentColumnView()
                .navigationSplitViewColumnWidth(min: 300, ideal: 350, max: 400)
        } detail: {
            DetailView()
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                ConnectionStatusIndicator()
            }
        }
        .sheet(item: $router.presentedSheet) { sheet in
            sheetContent(for: sheet)
        }
        .alert(item: $router.presentedAlert) { alert in
            alertContent(for: alert)
        }
        .overlay(alignment: .top) {
            ToastOverlay()
        }
        .overlay(alignment: .bottom) {
            ErrorBannerOverlay()
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: SheetDestination) -> some View {
        switch sheet {
        case .newSession(let project):
            NewSessionSheet(project: project)
        case .projectSettings(let project):
            ProjectSettingsSheet(project: project)
        case .connectionSettings:
            ConnectionSettingsSheet()
        case .diffViewer(let diff):
            DiffViewerView(viewModel: DiffViewerViewModel(diff: diff))
                .frame(minWidth: 800, minHeight: 600)
        }
    }

    private func alertContent(for alert: AlertDestination) -> Alert {
        switch alert {
        case .confirmEndSession(let session):
            return Alert(
                title: Text("End Session"),
                message: Text("Are you sure you want to end session '\(session.id)'?"),
                primaryButton: .destructive(Text("End")) {
                    // TODO(Section-2.3): End session - SessionListViewModel.terminateSession() 호출
                },
                secondaryButton: .cancel()
            )
        case .confirmDeleteProject(let project):
            return Alert(
                title: Text("Delete Project"),
                message: Text("Are you sure you want to remove project '\(project.name)'?"),
                primaryButton: .destructive(Text("Delete")) {
                    // TODO(Section-2.2): Delete project - ProjectBrowserViewModel에서 프로젝트 제거
                },
                secondaryButton: .cancel()
            )
        case .error(let message):
            return Alert(
                title: Text("Error"),
                message: Text(message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - SidebarView

/// 사이드바 뷰 - 탭 네비게이션
struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        List(selection: $appState.selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationLink(value: tab) {
                    Label(tab.title, systemImage: tab.icon)
                }
                .accessibilityIdentifier("sidebarTab-\(tab.rawValue)")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("EndlessCode")
        .accessibilityIdentifier("sidebar")
    }
}

// MARK: - ContentColumnView

/// 콘텐츠 컬럼 뷰 - 선택된 탭에 따른 목록 표시
struct ContentColumnView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.selectedTab {
            case .projects:
                ProjectListView()
            case .sessions:
                SessionListView()
            case .settings:
                // Settings는 detail 패널에서 전체 너비로 표시
                List {}
                    .navigationTitle("Settings")
            }
        }
        .accessibilityIdentifier("contentColumn")
    }
}

// MARK: - DetailView

/// 디테일 뷰 - 선택된 탭과 항목에 따른 상세 표시
struct DetailView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        // 현재 탭에 맞는 디테일만 표시
        switch appState.selectedTab {
        case .projects:
            if let project = appState.selectedProject {
                ProjectDetailView(project: project)
            } else {
                EmptyDetailView()
            }
        case .sessions:
            if let session = appState.selectedSession {
                ChatView(session: session)
            } else {
                EmptyDetailView()
            }
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Preview

#Preview {
    MainView()
        .environment(AppState())
        .environment(AppRouter())
}
