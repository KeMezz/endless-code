//
//  PlaceholderSheets.swift
//  EndlessCode
//
//  플레이스홀더 시트 뷰들 - 새 세션, 프로젝트 설정, 연결 설정
//

import SwiftUI

// MARK: - NewSessionSheet

/// 새 세션 시트 (플레이스홀더)
struct NewSessionSheet: View {
    let project: Project

    var body: some View {
        Text("New Session for \(project.name)")
    }
}

// MARK: - ProjectSettingsSheet

/// 프로젝트 설정 시트 (플레이스홀더)
struct ProjectSettingsSheet: View {
    let project: Project

    var body: some View {
        Text("Settings for \(project.name)")
    }
}

// MARK: - ConnectionSettingsSheet

/// 연결 설정 시트 (플레이스홀더)
struct ConnectionSettingsSheet: View {
    var body: some View {
        Text("Connection Settings")
    }
}
