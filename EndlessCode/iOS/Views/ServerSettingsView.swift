//
//  ServerSettingsView.swift
//  EndlessCode
//
//  서버 설정 화면
//

#if os(iOS)
import SwiftUI

// MARK: - ServerSettingsView

/// 서버 설정 화면
struct ServerSettingsView: View {
    // MARK: - Properties

    @State private var viewModel = ServerSettingsViewModel()
    @State private var discoveryViewModel = BonjourDiscoveryViewModel()
    @State private var showQRScanner = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 연결 상태
                    connectionStatusSection

                    // 수동 설정
                    manualConfigurationSection

                    // 발견된 서버
                    discoveredServersSection
                }
                .padding()
            }
            .navigationTitle("Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        // 뒤로 가기
                    }
                    .accessibilityIdentifier("backButton")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveSettings()
                    }
                    .accessibilityIdentifier("saveButton")
                }
            }
            .sheet(isPresented: $showQRScanner) {
                QRScannerView(
                    onScanComplete: { qrData in
                        viewModel.updateFromQRCode(qrData)
                        showQRScanner = false
                    },
                    onDismiss: {
                        showQRScanner = false
                    }
                )
            }
        }
        .accessibilityIdentifier("serverSettingsView")
    }

    // MARK: - Private Views

    private var connectionStatusSection: some View {
        ConnectionStatusBadge(state: viewModel.connectionState)
    }

    private var manualConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            Text("MANUAL CONFIGURATION")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            // 서버 주소
            VStack(alignment: .leading, spacing: 8) {
                Text("SERVER ADDRESS")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("https://api.endlesscode.dev", text: $viewModel.serverAddress)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("iosServerAddressField")
            }

            // API 토큰
            VStack(alignment: .leading, spacing: 8) {
                Text("API TOKEN")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Group {
                        if viewModel.isTokenVisible {
                            TextField("Enter your API token", text: $viewModel.apiToken)
                        } else {
                            SecureField("Enter your API token", text: $viewModel.apiToken)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("apiTokenField")

                    Button(action: {
                        viewModel.isTokenVisible.toggle()
                    }) {
                        Image(systemName: viewModel.isTokenVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.blue)
                    }
                    .frame(width: 44, height: 44)
                    .accessibilityLabel(viewModel.isTokenVisible ? "Hide token" : "Show token")
                    .accessibilityIdentifier("toggleTokenVisibilityButton")
                }
            }

            // 테스트 연결 버튼
            Button(action: {
                Task {
                    await viewModel.testConnection()
                }
            }) {
                HStack {
                    if viewModel.isTesting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 16))
                    }

                    Text("Test Connection")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(viewModel.isTesting)
            .accessibilityIdentifier("iosConnectButton")

            // 테스트 결과 메시지
            if let message = viewModel.lastTestMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(viewModel.connectionState == .connected ? .green : .red)
                    .accessibilityIdentifier("testResultMessage")
            }

            // QR 스캔 버튼
            Button(action: {
                showQRScanner = true
            }) {
                HStack {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Scan QR Code")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(.blue)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                )
            }
            .accessibilityIdentifier("iosQRScanButton")
        }
    }

    private var discoveredServersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            HStack {
                Text("DISCOVERED SERVERS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    if discoveryViewModel.isScanning {
                        discoveryViewModel.stopScanning()
                    } else {
                        discoveryViewModel.startScanning()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                        .rotationEffect(discoveryViewModel.isScanning ? .degrees(360) : .degrees(0))
                        .animation(
                            discoveryViewModel.isScanning ?
                                .linear(duration: 1).repeatForever(autoreverses: false) :
                                .default,
                            value: discoveryViewModel.isScanning
                        )
                }
                .frame(width: 44, height: 44)
                .accessibilityLabel(discoveryViewModel.isScanning ? "Stop scanning" : "Start scanning")
                .accessibilityIdentifier("toggleScanButton")
            }

            // 서버 목록
            if discoveryViewModel.discoveredServers.isEmpty {
                emptyServerListView
            } else {
                ForEach(discoveryViewModel.discoveredServers) { server in
                    DiscoveredServerRow(server: server) {
                        viewModel.updateFromDiscoveredServer(server)
                        discoveryViewModel.stopScanning()
                    }
                }
            }

            // 안내 텍스트
            Text("EndlessCode automatically discovers Claude Code servers on your local network")
                .font(.caption2)
                .foregroundColor(.secondary)
                .accessibilityIdentifier("discoveryHint")
        }
    }

    private var emptyServerListView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text(discoveryViewModel.isScanning ? "Searching for servers..." : "No servers found")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if discoveryViewModel.isScanning {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .accessibilityIdentifier("emptyServerList")
    }
}

// MARK: - Preview

#Preview {
    ServerSettingsView()
}
#endif
