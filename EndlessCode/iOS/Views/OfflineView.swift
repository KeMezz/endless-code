//
//  OfflineView.swift
//  EndlessCode
//
//  오프라인 상태 전체 화면 뷰
//

#if os(iOS)
import SwiftUI

// MARK: - OfflineView

/// 오프라인 상태 전체 화면
struct OfflineView: View {

    // MARK: Properties

    let connectionState: ConnectionState
    let hasCachedMessages: Bool
    let onRetry: () -> Void
    let onViewCached: () -> Void

    // MARK: Body

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // 아이콘
            Image(systemName: "wifi.slash")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            // 메시지
            VStack(spacing: 8) {
                Text("서버에 연결할 수 없습니다")
                    .font(.title2)
                    .fontWeight(.semibold)

                if case .failed(let error) = connectionState {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }

            // 버튼들
            VStack(spacing: 12) {
                if hasCachedMessages {
                    Button {
                        onViewCached()
                    } label: {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("캐시된 메시지 보기")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(.secondary)
                    .accessibilityIdentifier("iosViewCachedButton")
                }

                Button {
                    onRetry()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("다시 시도")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("iosRetryButton")
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("iosOfflineView")
    }
}

// MARK: - Preview

#Preview("Offline with Cache") {
    OfflineView(
        connectionState: .failed(error: "연결 시간이 초과되었습니다"),
        hasCachedMessages: true,
        onRetry: {},
        onViewCached: {}
    )
}

#Preview("Offline without Cache") {
    OfflineView(
        connectionState: .failed(error: "서버를 찾을 수 없습니다"),
        hasCachedMessages: false,
        onRetry: {},
        onViewCached: {}
    )
}

#Preview("Dark Mode") {
    OfflineView(
        connectionState: .failed(error: "네트워크 오류가 발생했습니다"),
        hasCachedMessages: true,
        onRetry: {},
        onViewCached: {}
    )
    .preferredColorScheme(.dark)
}
#endif
