//
//  ConnectionStatusBadge.swift
//  EndlessCode
//
//  연결 상태 배지 컴포넌트
//

#if os(iOS)
import SwiftUI

// MARK: - ConnectionStatusBadge

/// 연결 상태 표시 배지
struct ConnectionStatusBadge: View {
    // MARK: - Properties

    let state: ConnectionState

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            statusIcon
            statusText
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .cornerRadius(12)
        .accessibilityIdentifier("iosConnectionStatusBadge")
    }

    // MARK: - Private Views

    @ViewBuilder
    private var statusIcon: some View {
        Image(systemName: iconName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(iconColor)
            .accessibilityHidden(true)
    }

    private var statusText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Connection Status")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(statusMessage)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(textColor)
        }
        .accessibilityLabel("Connection status: \(statusMessage)")
    }

    // MARK: - Computed Properties

    private var iconName: String {
        switch state {
        case .disconnected:
            return "xmark.circle.fill"
        case .connecting:
            return "arrow.clockwise.circle.fill"
        case .connected:
            return "checkmark.circle.fill"
        case .reconnecting:
            return "arrow.triangle.2.circlepath.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch state {
        case .disconnected:
            return .gray
        case .connecting:
            return .orange
        case .connected:
            return .green
        case .reconnecting:
            return .yellow
        case .failed:
            return .red
        }
    }

    private var textColor: Color {
        switch state {
        case .disconnected:
            return .secondary
        case .connecting:
            return .orange
        case .connected:
            return .green
        case .reconnecting:
            return .yellow
        case .failed:
            return .red
        }
    }

    private var backgroundColor: Color {
        Color(.systemBackground)
            .opacity(0.8)
    }

    private var statusMessage: String {
        switch state {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected to Claude Code"
        case .reconnecting(let attempt):
            return "Reconnecting (attempt \(attempt))..."
        case .failed(let error):
            return "Failed: \(error)"
        }
    }
}

// MARK: - Preview

#Preview("Connected") {
    ConnectionStatusBadge(state: .connected)
        .padding()
}

#Preview("Connecting") {
    ConnectionStatusBadge(state: .connecting)
        .padding()
}

#Preview("Disconnected") {
    ConnectionStatusBadge(state: .disconnected)
        .padding()
}

#Preview("Failed") {
    ConnectionStatusBadge(state: .failed(error: "Network timeout"))
        .padding()
}
#endif
