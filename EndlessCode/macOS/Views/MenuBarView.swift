//
//  MenuBarView.swift
//  EndlessCode
//
//  메뉴바 뷰
//

import SwiftUI

// MARK: - MenuBarView

/// 메뉴바 뷰
struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = MenuBarViewModel()
    @State private var showQRCode = false
    @State private var qrCodeImage: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 서버 상태
            serverStatusSection

            Divider()

            // 세션 정보
            sessionInfoSection

            Divider()

            // 빠른 액션
            quickActionsSection

            Divider()

            // 서버 정보
            serverInfoSection

            // 에러 메시지
            if viewModel.hasError, let errorMessage = viewModel.errorMessage {
                Divider()
                errorSection(errorMessage)
            }

            // 리소스 경고
            if viewModel.showResourceWarning {
                Divider()
                resourceWarningSection
            }

            Divider()

            // 종료
            Button("종료") {
                NSApplication.shared.terminate(nil)
            }
            .accessibilityIdentifier("menuBarQuit")
        }
        .padding(.vertical, 4)
        .frame(width: 280)
        .onAppear {
            viewModel = MenuBarViewModel(appState: appState)
            viewModel.updateRecentProjects(appState.projects)
            viewModel.checkResourceWarning()
        }
        .onChange(of: appState.projects) { _, newProjects in
            viewModel.updateRecentProjects(newProjects)
        }
        .onChange(of: appState.activeSessions.count) { _, _ in
            viewModel.checkResourceWarning()
        }
        .accessibilityIdentifier("menuBarView")
    }

    // MARK: - Sections

    /// 서버 상태 섹션
    private var serverStatusSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("서버 상태")
                .font(.headline)

            HStack {
                Circle()
                    .fill(serverStatusColor)
                    .frame(width: 8, height: 8)

                Text(serverStatusText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityIdentifier("menuBarServerStatus")
    }

    /// 세션 정보 섹션
    private var sessionInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.secondary)
                Text("활성 세션: \(appState.activeSessions.count)개")
                    .font(.subheadline)
            }
            .accessibilityIdentifier("menuBarSessionCount")

            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.secondary)
                Text("연결된 클라이언트: \(appState.connectedClientCount)개")
                    .font(.subheadline)
            }
            .accessibilityIdentifier("menuBarClientCount")

            // 세션 목록 (최대 5개)
            if !appState.activeSessions.isEmpty {
                Divider()
                    .padding(.vertical, 4)

                ForEach(appState.activeSessions.prefix(5)) { session in
                    if let project = appState.projects.first(where: { $0.id == session.projectId }) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(project.name)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }

                if appState.activeSessions.count > 5 {
                    Text("외 \(appState.activeSessions.count - 5)개")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    /// 빠른 액션 섹션
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                viewModel.openMainWindow()
            } label: {
                Label("새 세션 시작", systemImage: "plus.circle.fill")
            }
            .accessibilityIdentifier("menuBarNewSession")

            // 최근 프로젝트
            if !viewModel.recentProjects.isEmpty {
                Menu {
                    ForEach(viewModel.recentProjects) { project in
                        Button(project.name) {
                            // TODO: 프로젝트로 바로 이동
                            viewModel.openMainWindow()
                        }
                    }
                } label: {
                    Label("최근 프로젝트", systemImage: "clock.fill")
                }
                .accessibilityIdentifier("menuBarRecentProjects")
            }

            Button {
                viewModel.toggleServer()
            } label: {
                let isRunning = appState.serverState == .running
                Label(
                    isRunning ? "서버 중지" : "서버 시작",
                    systemImage: isRunning ? "stop.circle.fill" : "play.circle.fill"
                )
            }
            .accessibilityIdentifier("menuBarToggleServer")

            Button {
                // TODO: 설정 화면 열기
                viewModel.openMainWindow()
            } label: {
                Label("설정", systemImage: "gearshape.fill")
            }
            .accessibilityIdentifier("menuBarSettings")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    /// 서버 정보 섹션
    private var serverInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                viewModel.copyServerAddress()
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc.fill")
                    Text(viewModel.serverAddress)
                        .font(.caption.monospaced())
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("menuBarServerAddress")

            Button {
                // TODO: 토큰 보기 구현
            } label: {
                Label("접속 토큰 보기", systemImage: "key.fill")
            }
            .accessibilityIdentifier("menuBarShowToken")

            Button {
                qrCodeImage = viewModel.generateQRCode()
                showQRCode = qrCodeImage != nil
            } label: {
                Label("QR 코드 생성", systemImage: "qrcode")
            }
            .accessibilityIdentifier("menuBarQRCode")
            .popover(isPresented: $showQRCode) {
                VStack(spacing: 12) {
                    Text("서버 연결 QR 코드")
                        .font(.headline)

                    if let image = qrCodeImage {
                        Image(nsImage: image)
                            .interpolation(.none)
                            .resizable()
                            .frame(width: 200, height: 200)
                    }

                    Text("iOS 앱에서 스캔하세요")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    /// 에러 섹션
    private func errorSection(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityIdentifier("menuBarErrorMessage")
    }

    /// 리소스 경고 섹션
    private var resourceWarningSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.orange)
            Text("리소스 사용량이 높습니다")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityIdentifier("menuBarResourceWarning")
    }

    // MARK: - Computed Properties

    /// 서버 상태 색상
    private var serverStatusColor: Color {
        switch appState.serverState {
        case .running:
            return .green
        case .stopped:
            return .gray
        case .error:
            return .red
        }
    }

    /// 서버 상태 텍스트
    private var serverStatusText: String {
        switch appState.serverState {
        case .running:
            return "실행 중"
        case .stopped:
            return "중지됨"
        case .error(let message):
            return "오류: \(message)"
        }
    }
}

// MARK: - Preview

#Preview {
    MenuBarView()
        .environment(AppState())
}
