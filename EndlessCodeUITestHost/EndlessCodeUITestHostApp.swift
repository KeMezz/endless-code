//
//  EndlessCodeUITestHostApp.swift
//  EndlessCodeUITestHost
//
//  UI 테스트용 호스트 앱 - Vapor 의존성 없이 UI만 빌드
//

import SwiftUI

@main
struct EndlessCodeUITestHostApp: App {
    @State private var appState = AppState()
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(appState)
                .environment(router)
        }
    }
}
