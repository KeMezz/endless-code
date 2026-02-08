//
//  MobileFileViewer.swift
//  EndlessCode
//
//  모바일 파일/Diff 뷰어 컴포넌트
//

#if os(iOS)
import SwiftUI

struct MobileFileViewer: View {
    @State private var selectedMode: ViewMode = .file
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    private let minScale: CGFloat = 0.8
    private let maxScale: CGFloat = 3.0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode Picker
                Picker("View Mode", selection: $selectedMode) {
                    ForEach(ViewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    contentView
                        .scaleEffect(scale)
                        .padding()
                }
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
            }
            .navigationTitle("Files")
            .accessibilityIdentifier("iosMobileFileViewer")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Reset Zoom") {
                            withAnimation {
                                scale = 1.0
                            }
                        }

                        Button("Zoom In") {
                            withAnimation {
                                scale = min(scale + 0.2, maxScale)
                            }
                        }

                        Button("Zoom Out") {
                            withAnimation {
                                scale = max(scale - 0.2, minScale)
                            }
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch selectedMode {
        case .file:
            FileContentView(content: sampleFileContent)
        case .diff:
            DiffContentView(diff: sampleDiff)
        }
    }

    // MARK: - View Mode

    private enum ViewMode: String, CaseIterable, Identifiable {
        case file = "File"
        case diff = "Diff"

        var id: String { rawValue }
    }
}

// MARK: - File Content View

private struct FileContentView: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // File Header
            HStack {
                Image(systemName: "doc.text")
                    .foregroundStyle(.blue)
                Text("ContentView.swift")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding()
            .background(Color(white: 0.15))

            Divider()

            // File Content
            ScrollView {
                Text(content)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(Color(white: 0.9))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .background(Color(white: 0.1))
        .cornerRadius(12)
    }
}

// MARK: - Diff Content View

private struct DiffContentView: View {
    let diff: [MobileDiffLine]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Diff Header
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.orange)
                Text("Package.swift")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()

                HStack(spacing: 12) {
                    Label("+\(addedCount)", systemImage: "plus.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)

                    Label("-\(removedCount)", systemImage: "minus.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .background(Color(white: 0.15))

            Divider()

            // Diff Content
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(diff) { line in
                        DiffLineView(line: line)
                    }
                }
            }
        }
        .background(Color(white: 0.1))
        .cornerRadius(12)
    }

    private var addedCount: Int {
        diff.filter { $0.type == .added }.count
    }

    private var removedCount: Int {
        diff.filter { $0.type == .removed }.count
    }
}

// MARK: - Diff Line View

private struct DiffLineView: View {
    let line: MobileDiffLine

    var body: some View {
        HStack(spacing: 8) {
            // Line Type Indicator
            Text(line.type.prefix)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(line.type.color)
                .frame(width: 20)

            // Line Content
            Text(line.content)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color(white: 0.9))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(line.type.backgroundColor)
    }
}

// MARK: - Diff Models

private struct MobileDiffLine: Identifiable {
    let id = UUID()
    let type: DiffLineType
    let content: String

    enum DiffLineType {
        case added
        case removed
        case context
        case header

        var prefix: String {
            switch self {
            case .added: return "+"
            case .removed: return "-"
            case .context: return " "
            case .header: return "@"
            }
        }

        var color: Color {
            switch self {
            case .added: return .green
            case .removed: return .red
            case .context: return .secondary
            case .header: return .blue
            }
        }

        var backgroundColor: Color {
            switch self {
            case .added: return .green.opacity(0.1)
            case .removed: return .red.opacity(0.1)
            case .context, .header: return .clear
            }
        }
    }
}

// MARK: - Sample Data

private let sampleFileContent = """
import SwiftUI

struct ContentView: View {
    @State private var items: [Item] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            List(items) { item in
                ItemRow(item: item)
            }
            .navigationTitle("Items")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        addItem()
                    }
                }
            }
        }
    }

    private func addItem() {
        let newItem = Item(name: "New Item")
        items.append(newItem)
    }
}
"""

private let sampleDiff: [MobileDiffLine] = [
    MobileDiffLine(type: .header, content: "@@ -10,7 +10,8 @@ let package = Package("),
    MobileDiffLine(type: .context, content: "    dependencies: ["),
    MobileDiffLine(type: .context, content: "        .package(url: \"https://github.com/vapor/vapor.git\", from: \"4.0.0\"),"),
    MobileDiffLine(type: .removed, content: "        .package(url: \"https://github.com/apple/swift-log.git\", from: \"1.0.0\")"),
    MobileDiffLine(type: .added, content: "        .package(url: \"https://github.com/apple/swift-log.git\", from: \"1.0.0\"),"),
    MobileDiffLine(type: .added, content: "        .package(url: \"https://github.com/apple/swift-nio.git\", from: \"2.0.0\")"),
    MobileDiffLine(type: .context, content: "    ],"),
    MobileDiffLine(type: .context, content: "    targets: ["),
]

// MARK: - Preview

#Preview("File Mode") {
    MobileFileViewer()
        .preferredColorScheme(.dark)
}

#Preview("Diff Mode") {
    MobileFileViewer()
        .preferredColorScheme(.dark)
        .onAppear {
            // Set to diff mode in preview
        }
}
#endif
