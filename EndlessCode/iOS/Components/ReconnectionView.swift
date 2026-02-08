//
//  ReconnectionView.swift
//  EndlessCode
//
//  재연결 진행 상태 표시 뷰
//

#if os(iOS)
import SwiftUI

// MARK: - ReconnectionView

/// 재연결 진행 상태 표시
struct ReconnectionView: View {

    // MARK: Properties

    let attempt: Int
    let maxAttempts: Int
    let remainingSeconds: Int?
    let onCancel: () -> Void
    let onManualRetry: () -> Void

    @State private var isRotating = false

    // MARK: Body

    var body: some View {
        VStack(spacing: 24) {
            // 진행률 표시
            VStack(spacing: 16) {
                // 회전하는 아이콘
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
                    .animation(
                        .linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: isRotating
                    )
                    .onAppear {
                        isRotating = true
                    }

                // 진행 상태 텍스트
                VStack(spacing: 4) {
                    Text("재연결 시도 중...")
                        .font(.headline)

                    Text("(\(attempt)/\(maxAttempts))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // 대기 시간 표시
                if let seconds = remainingSeconds {
                    Text("\(seconds)초 후 재시도")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // 진행률 바
                ProgressView(value: Double(attempt), total: Double(maxAttempts))
                    .progressViewStyle(.linear)
                    .frame(width: 200)
                    .accessibilityIdentifier("iosReconnectionProgress")
            }

            // 버튼들
            HStack(spacing: 12) {
                Button("취소") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityIdentifier("iosReconnectionCancel")

                Button("지금 재시도") {
                    onManualRetry()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("iosManualRetryButton")
            }
        }
        .padding(32)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.1), radius: 10)
        }
        .accessibilityIdentifier("iosReconnectionView")
    }
}

// MARK: - ReconnectionOverlay

/// 재연결 오버레이 (전체 화면 중앙)
struct ReconnectionOverlay: View {

    // MARK: Properties

    let attempt: Int
    let maxAttempts: Int
    let remainingSeconds: Int?
    let onCancel: () -> Void
    let onManualRetry: () -> Void

    // MARK: Body

    var body: some View {
        ZStack {
            // 반투명 배경
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // 재연결 뷰
            ReconnectionView(
                attempt: attempt,
                maxAttempts: maxAttempts,
                remainingSeconds: remainingSeconds,
                onCancel: onCancel,
                onManualRetry: onManualRetry
            )
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Preview

#Preview("Reconnection View") {
    ReconnectionView(
        attempt: 3,
        maxAttempts: 10,
        remainingSeconds: 5,
        onCancel: {},
        onManualRetry: {}
    )
}

#Preview("Reconnection Overlay") {
    ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()

        ReconnectionOverlay(
            attempt: 5,
            maxAttempts: 10,
            remainingSeconds: 8,
            onCancel: {},
            onManualRetry: {}
        )
    }
}

#Preview("Dark Mode") {
    ReconnectionOverlay(
        attempt: 7,
        maxAttempts: 10,
        remainingSeconds: nil,
        onCancel: {},
        onManualRetry: {}
    )
    .preferredColorScheme(.dark)
}
#endif
