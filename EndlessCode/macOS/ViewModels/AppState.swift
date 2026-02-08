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

    /// 서버 상태
    var serverState: ServerState = .stopped

    /// 연결된 클라이언트 수
    var connectedClientCount: Int = 0

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
