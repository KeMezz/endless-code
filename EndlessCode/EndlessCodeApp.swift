//
//  EndlessCodeApp.swift
//  EndlessCode
//
//  Created by hyeongjin on 2026/01/25.
//

import SwiftUI

@main
struct EndlessCodeApp: App {
    #if os(macOS)
    @State private var appState = AppState()
    @State private var appRouter = AppRouter()
    #elseif os(iOS)
    @State private var appState = iOSAppState()
    #endif

    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            MainView()
                .environment(appState)
                .environment(appRouter)
            #elseif os(iOS)
            iOSMainView()
                .environment(appState)
            #endif
        }

        #if os(macOS)
        MenuBarExtra {
            MenuBarView()
                .environment(appState)
        } label: {
            Image(systemName: menuBarIconName)
        }
        #endif
    }

    #if os(macOS)
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
    #endif
}
