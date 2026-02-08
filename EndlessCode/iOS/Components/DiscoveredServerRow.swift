//
//  DiscoveredServerRow.swift
//  EndlessCode
//
//  발견된 서버 행 컴포넌트
//

#if os(iOS)
import SwiftUI

// MARK: - DiscoveredServerRow

/// 발견된 서버 목록 행
struct DiscoveredServerRow: View {
    // MARK: - Properties

    let server: DiscoveredServer
    let onSelect: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // 서버 아이콘
            serverIcon

            // 서버 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(server.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(server.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 선택 버튼
            selectButton
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Server \(server.name) at \(server.address)")
        .accessibilityHint("Tap to use this server")
        .accessibilityIdentifier("discoveredServerRow-\(server.id)")
    }

    // MARK: - Private Views

    private var serverIcon: some View {
        Image(systemName: "desktopcomputer")
            .font(.system(size: 32))
            .foregroundColor(.blue)
            .frame(width: 44, height: 44)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .accessibilityHidden(true)
    }

    private var selectButton: some View {
        Button(action: onSelect) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.blue)
        }
        .frame(width: 44, height: 44)
        .accessibilityLabel("Use this server")
        .accessibilityIdentifier("selectServerButton-\(server.id)")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        DiscoveredServerRow(
            server: DiscoveredServer(
                name: "MacBook-Pro.local",
                address: "192.168.1.45",
                port: 8080
            ),
            onSelect: {}
        )

        DiscoveredServerRow(
            server: DiscoveredServer(
                name: "Dev-Cluster-01",
                address: "10.0.0.12",
                port: 8080
            ),
            onSelect: {}
        )

        DiscoveredServerRow(
            server: DiscoveredServer(
                name: "Claude-Bridge-Local",
                address: "127.0.0.1",
                port: 8080
            ),
            onSelect: {}
        )
    }
    .padding()
}
#endif
