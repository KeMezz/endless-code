//
//  OverlayViews.swift
//  EndlessCode
//
//  오버레이 뷰 컴포넌트들 - 연결 상태, 토스트, 에러 배너
//

import SwiftUI

// MARK: - ConnectionStatusIndicator

/// 연결 상태 인디케이터
struct ConnectionStatusIndicator: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .accessibilityIdentifier("connectionStatus")
    }

    private var statusColor: Color {
        switch appState.connectionState {
        case .connected:
            return .green
        case .connecting, .reconnecting:
            return .orange
        case .disconnected:
            return .gray
        case .failed:
            return .red
        }
    }

    private var statusText: String {
        switch appState.connectionState {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .reconnecting(let attempt):
            return "Reconnecting (\(attempt))"
        case .disconnected:
            return "Disconnected"
        case .failed(let error):
            return "Error: \(error)"
        }
    }
}

// MARK: - ToastOverlay

/// 토스트 오버레이
struct ToastOverlay: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if let message = appState.toastMessage {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                Text(message)
                    .font(.callout)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 4)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(duration: 0.3), value: message)
        }
    }
}

// MARK: - ErrorBannerOverlay

/// 에러 배너 오버레이
struct ErrorBannerOverlay: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if let error = appState.errorMessage {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)

                Text(error)
                    .font(.callout)

                Spacer()

                Button {
                    appState.dismissError()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 0))
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
