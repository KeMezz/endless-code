//
//  EndlessCodeApp.swift
//  EndlessCode
//
//  Created by hyeongjin on 2026/01/25.
//

import SwiftUI

@main
struct EndlessCodeApp: App {
    @State private var appState = AppState()
    @State private var appRouter = AppRouter()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(appState)
                .environment(appRouter)
        }

        MenuBarExtra {
            MenuBarView()
                .environment(appState)
        } label: {
            Image(systemName: menuBarIconName)
        }
    }

    /// 메뉴바 아이콘 이름
    private var menuBarIconName: String {
        switch appState.serverState {
        case .running:
            return "terminal.fill"
        case .stopped:
            return "terminal"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
}
