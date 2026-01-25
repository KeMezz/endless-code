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
    }
}
