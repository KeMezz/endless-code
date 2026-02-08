//
//  AppRouter.swift
//  EndlessCode
//
//  앱 라우터 - 화면 전환, 딥링크 처리
//

import Foundation

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
                // TODO: 프로젝트를 조회하여 실제 네비게이션 구현
                print("Deep link to project: \(projectId)")
            }
        case "session":
            if let sessionId = url.pathComponents.dropFirst().first {
                // TODO: 세션을 조회하여 실제 네비게이션 구현
                print("Deep link to session: \(sessionId)")
            }
        default:
            break
        }
    }
}
