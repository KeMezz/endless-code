//
//  SettingsView.swift
//  EndlessCode
//
//  설정 화면 - 서버, CLI, 세션, 인증, 로그 설정
//

import SwiftUI

// MARK: - SettingsView

/// 설정 화면
struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            serverSection
            cliSection
            sessionSection
            authenticationSection
            loggingSection
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .accessibilityIdentifier("settingsView")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Reset") {
                    viewModel.reset()
                }
                .accessibilityIdentifier("settingsResetButton")
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    viewModel.save()
                    if viewModel.saveError == nil {
                        // 저장 성공 시 Keychain에도 저장 시도
                        try? viewModel.saveTokenToKeychain()
                    }
                }
                .disabled(!viewModel.hasChanges || !viewModel.isValid)
                .accessibilityIdentifier("settingsSaveButton")
            }
        }
        .alert("Save Error", isPresented: .constant(viewModel.saveError != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.saveError {
                Text(error)
            }
        }
        .task {
            // Keychain에서 토큰 로드 시도
            try? viewModel.loadTokenFromKeychain()
        }
    }

    // MARK: - Server Section

    private var serverSection: some View {
        Section("Server") {
            TextField("Host", text: $viewModel.config.host)
                .accessibilityIdentifier("settingsServerHost")

            HStack {
                TextField("Port", value: $viewModel.config.port, format: .number)
                    .accessibilityIdentifier("settingsServerPort")
                #if canImport(UIKit)
                    .keyboardType(.numberPad)
                #endif

                if viewModel.config.port < 1 || viewModel.config.port > 65535 {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .help("Port must be between 1 and 65535")
                }
            }

            Toggle("Enable TLS", isOn: $viewModel.config.tlsEnabled)
                .accessibilityIdentifier("settingsTLSToggle")
        }
    }

    // MARK: - CLI Section

    private var cliSection: some View {
        Section("Claude CLI") {
            HStack {
                TextField("CLI Path", text: $viewModel.config.cliPath)
                    .accessibilityIdentifier("settingsCLIPath")
                    .onChange(of: viewModel.config.cliPath) { _, _ in
                        viewModel.validateCLIPath()
                    }

                Button {
                    viewModel.selectCLIPath()
                } label: {
                    Image(systemName: "folder")
                }
                .help("Browse...")
            }

            if let error = viewModel.cliPathError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    // MARK: - Session Section

    private var sessionSection: some View {
        Section("Sessions") {
            Stepper(
                "Max Concurrent Sessions: \(viewModel.config.maxConcurrentSessions)",
                value: $viewModel.config.maxConcurrentSessions,
                in: 1...10
            )
            .accessibilityIdentifier("settingsMaxSessions")

            Picker("Session Timeout", selection: $viewModel.config.sessionTimeoutSeconds) {
                Text("10 seconds").tag(10)
                Text("30 seconds").tag(30)
                Text("60 seconds").tag(60)
                Text("120 seconds").tag(120)
            }
            .accessibilityIdentifier("settingsSessionTimeout")

            Picker("Prompt Timeout", selection: $viewModel.config.promptTimeoutSeconds) {
                Text("10 minutes").tag(600)
                Text("30 minutes").tag(1800)
                Text("60 minutes").tag(3600)
            }
            .accessibilityIdentifier("settingsPromptTimeout")
        }
    }

    // MARK: - Authentication Section

    private var authenticationSection: some View {
        Section("Authentication") {
            HStack {
                if viewModel.isTokenVisible {
                    TextField("Auth Token", text: $viewModel.displayToken)
                        .accessibilityIdentifier("settingsAuthToken")
                } else {
                    SecureField("Auth Token", text: $viewModel.displayToken)
                        .accessibilityIdentifier("settingsAuthToken")
                }

                Button {
                    viewModel.toggleTokenVisibility()
                } label: {
                    Image(systemName: viewModel.isTokenVisible ? "eye.slash" : "eye")
                }
                .buttonStyle(.plain)
                .help(viewModel.isTokenVisible ? "Hide Token" : "Show Token")
            }

            Button("Generate New Token") {
                viewModel.generateToken()
            }
            .accessibilityIdentifier("settingsGenerateToken")

            if !viewModel.displayToken.isEmpty {
                Text("Token will be stored securely in Keychain")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Logging Section

    private var loggingSection: some View {
        Section("Logging") {
            Picker("Log Level", selection: $viewModel.config.logLevel) {
                ForEach(LogLevel.allCases, id: \.self) { level in
                    Text(level.rawValue.capitalized).tag(level)
                }
            }
            .accessibilityIdentifier("settingsLogLevel")

            Text("Higher log levels include more detailed information")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
}
