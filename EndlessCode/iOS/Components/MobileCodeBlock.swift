//
//  MobileCodeBlock.swift
//  EndlessCode
//
//  모바일 코드 블록 컴포넌트 (가로 스크롤, 핀치 줌)
//

#if os(iOS)
import SwiftUI

struct MobileCodeBlock: View {
    let code: String
    let language: String?

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var isCopied = false

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 3.0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                if let language = language {
                    Text(language.uppercased())
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    copyToClipboard()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                        Text(isCopied ? "Copied" : "Copy")
                            .font(.caption)
                    }
                    .foregroundStyle(isCopied ? .green : .secondary)
                }
            }

            // Code Content
            ScrollView(.horizontal, showsIndicators: true) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.white)
                    .textSelection(.enabled)
                    .padding(12)
                    .scaleEffect(scale)
            }
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.12, green: 0.12, blue: 0.18))
            .cornerRadius(8)
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        let delta = value.magnification / lastScale
                        lastScale = value.magnification
                        let newScale = scale * delta
                        scale = min(max(newScale, minScale), maxScale)
                    }
                    .onEnded { _ in
                        lastScale = 1.0
                    }
            )
            .accessibilityIdentifier("iosMobileCodeBlock")
        }
        .padding(8)
        .background(Color(white: 0.15))
        .cornerRadius(12)
    }

    // MARK: - Copy to Clipboard

    private func copyToClipboard() {
        UIPasteboard.general.string = code
        isCopied = true

        // 2초 후 아이콘 리셋
        Task {
            try? await Task.sleep(for: .seconds(2))
            isCopied = false
        }
    }
}

// MARK: - Preview

#Preview("Swift Code") {
    MobileCodeBlock(
        code: """
struct ContentView: View {
    @State private var items: [Item] = []

    var body: some View {
        List(items) { item in
            ItemRow(item: item)
        }
        .navigationTitle("Items")
    }
}
""",
        language: "swift"
    )
    .padding()
    .background(Color(white: 0.1))
    .preferredColorScheme(.dark)
}

#Preview("Long Code") {
    MobileCodeBlock(
        code: """
func fetchData() async throws -> [Item] {
    let url = URL(string: "https://api.example.com/items")!
    let (data, _) = try await URLSession.shared.data(from: url)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode([Item].self, from: data)
}
""",
        language: "swift"
    )
    .padding()
    .background(Color(white: 0.1))
    .preferredColorScheme(.dark)
}

#Preview("No Language") {
    MobileCodeBlock(
        code: "npm install -g @anthropic/claude-cli",
        language: nil
    )
    .padding()
    .background(Color(white: 0.1))
    .preferredColorScheme(.dark)
}
#endif
