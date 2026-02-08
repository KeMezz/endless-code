//
//  OfflineBanner.swift
//  EndlessCode
//
//  오프라인 상태 배너 - 화면 상단에 표시
//

#if os(iOS)
import SwiftUI

// MARK: - OfflineBanner

/// 오프라인 상태 배너
struct OfflineBanner: View {

    // MARK: Properties

    let isOffline: Bool

    // MARK: Body

    var body: some View {
        if isOffline {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.caption)
                    .foregroundStyle(.white)

                Text("인터넷 연결이 없습니다")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.red.gradient)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityIdentifier("iosOfflineBanner")
        }
    }
}

// MARK: - ServerConnectionBanner

/// 서버 연결 실패 배너
struct ServerConnectionBanner: View {

    // MARK: Properties

    let connectionState: ConnectionState

    // MARK: Body

    var body: some View {
        if case .failed = connectionState {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.white)

                Text("서버에 연결할 수 없습니다")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.orange.gradient)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityIdentifier("iosServerConnectionBanner")
        }
    }
}

// MARK: - Preview

#Preview("Offline Banner") {
    VStack(spacing: 0) {
        OfflineBanner(isOffline: true)

        Spacer()
    }
}

#Preview("Server Connection Banner") {
    VStack(spacing: 0) {
        ServerConnectionBanner(connectionState: .failed(error: "Connection timeout"))

        Spacer()
    }
}

#Preview("Dark Mode") {
    VStack(spacing: 0) {
        OfflineBanner(isOffline: true)
        ServerConnectionBanner(connectionState: .failed(error: "Network error"))

        Spacer()
    }
    .preferredColorScheme(.dark)
}
#endif
