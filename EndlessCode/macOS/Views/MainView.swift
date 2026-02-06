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
                SettingsListView()
            }
        }
        .accessibilityIdentifier("contentColumn")
    }
}

// MARK: - DetailView

/// 디테일 뷰 - 선택된 항목에 따른 상세 표시
struct DetailView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        // 각 뷰가 자체 accessibilityIdentifier를 가지므로
        // Group에 identifier를 부여하지 않음 (내부 identifier override 방지)
        if let session = appState.selectedSession {
            ChatView(session: session)
        } else if let project = appState.selectedProject {
            ProjectDetailView(project: project)
        } else {
            EmptyDetailView()
        }
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

// MARK: - ConnectionStatusIndicator

/// 연결 상태 인디케이터
struct ConnectionStatusIndicator: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .accessibilityIdentifier("connectionStatus")
    }

    private var statusColor: Color {
        switch appState.connectionState {
        case .connected:
            return .green
        case .connecting, .reconnecting:
            return .orange
        case .disconnected:
            return .gray
        case .failed:
            return .red
        }
    }

    private var statusText: String {
        switch appState.connectionState {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .reconnecting(let attempt):
            return "Reconnecting (\(attempt))"
        case .disconnected:
            return "Disconnected"
        case .failed(let error):
            return "Error: \(error)"
        }
    }
}

// MARK: - ToastOverlay

/// 토스트 오버레이
struct ToastOverlay: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if let message = appState.toastMessage {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                Text(message)
                    .font(.callout)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 4)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(duration: 0.3), value: message)
        }
    }
}

// MARK: - ErrorBannerOverlay

/// 에러 배너 오버레이
struct ErrorBannerOverlay: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if let error = appState.errorMessage {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)

                Text(error)
                    .font(.callout)

                Spacer()

                Button {
                    appState.dismissError()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 0))
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - Placeholder Views

/// 프로젝트 목록 뷰 - ProjectBrowserView 사용
struct ProjectListView: View {
    var body: some View {
        ProjectBrowserView()
    }
}

// SessionListView는 SessionListView.swift에서 정의됨

/// 설정 목록 뷰 (플레이스홀더)
struct SettingsListView: View {
    var body: some View {
        Text("Settings List")
            .navigationTitle("Settings")
            .accessibilityIdentifier("settingsList")
    }
}

/// 프로젝트 상세 뷰 - FileExplorerView 사용
struct ProjectDetailView: View {
    let project: Project

    var body: some View {
        FileExplorerView(project: project)
            .accessibilityIdentifier("projectDetail-\(project.id)")
    }
}

// ChatView는 ChatView.swift에서 정의됨

/// 새 세션 시트 (플레이스홀더)
struct NewSessionSheet: View {
    let project: Project

    var body: some View {
        Text("New Session for \(project.name)")
    }
}

/// 프로젝트 설정 시트 (플레이스홀더)
struct ProjectSettingsSheet: View {
    let project: Project

    var body: some View {
        Text("Settings for \(project.name)")
    }
}

/// 연결 설정 시트 (플레이스홀더)
struct ConnectionSettingsSheet: View {
    var body: some View {
        Text("Connection Settings")
    }
}

// MARK: - Preview

#Preview {
    MainView()
        .environment(AppState())
        .environment(AppRouter())
}
