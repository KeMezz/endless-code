//
//  iOSMainView.swift
//  EndlessCode
//
//  iOS 탭 기반 메인 뷰
//

#if os(iOS)
import SwiftUI

struct iOSMainView: View {
    @Environment(iOSAppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.selectedTab) {
            iOSProjectListView()
                .tabItem {
                    Label(iOSTab.projects.rawValue, systemImage: iOSTab.projects.icon)
                }
                .tag(iOSTab.projects)
                .accessibilityIdentifier("iosTab-Projects")

            iOSChatView()
                .tabItem {
                    Label(iOSTab.chat.rawValue, systemImage: iOSTab.chat.icon)
                }
                .tag(iOSTab.chat)
                .accessibilityIdentifier("iosTab-Chat")

            MobileFileViewer()
                .tabItem {
                    Label(iOSTab.files.rawValue, systemImage: iOSTab.files.icon)
                }
                .tag(iOSTab.files)
                .accessibilityIdentifier("iosTab-Files")

            iOSSettingsView()
                .tabItem {
                    Label(iOSTab.settings.rawValue, systemImage: iOSTab.settings.icon)
                }
                .tag(iOSTab.settings)
                .accessibilityIdentifier("iosTab-Settings")
        }
        .accessibilityIdentifier("iOSTabView")
        .overlay(alignment: .top) {
            if let toast = appState.toastMessage {
                ToastView(message: toast)
                    .padding(.top, 50)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: appState.toastMessage)
    }
}

// MARK: - Toast View

private struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.black.opacity(0.8))
            )
            .shadow(radius: 8)
    }
}

// MARK: - Settings View (Placeholder)

private struct iOSSettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Connection") {
                    Text("Server Settings")
                }
                Section("Appearance") {
                    Text("Theme Settings")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Preview

#Preview("Main View") {
    iOSMainView()
        .environment(iOSAppState.preview)
        .preferredColorScheme(.dark)
}

#Preview("Toast") {
    iOSMainView()
        .environment({
            let state = iOSAppState.preview
            state.showToast("Message sent successfully")
            return state
        }())
        .preferredColorScheme(.dark)
}
#endif
