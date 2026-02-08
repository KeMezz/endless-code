//
//  FileContentView.swift
//  EndlessCode
//
//  파일 내용 뷰 - 텍스트 표시, 라인 번호, 신택스 하이라이팅
//

import SwiftUI

// MARK: - FileContentView

/// 파일 내용 뷰
struct FileContentView: View {
    let file: FileSystemItem
    let fileSystemService: FileSystemServiceProtocol

    @State private var content: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isBinary = false
    @State private var isTruncated = false

    /// 최대 파일 크기 (1MB)
    private let maxFileSize = 1_024 * 1_024

    /// 신택스 하이라이터
    private let highlighter = SyntaxHighlighter.shared

    init(file: FileSystemItem, fileSystemService: FileSystemServiceProtocol = FileSystemService()) {
        self.file = file
        self.fileSystemService = fileSystemService
    }

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            FileContentHeader(
                file: file,
                isBinary: isBinary,
                isTruncated: isTruncated
            )

            Divider()

            // 콘텐츠
            if isLoading {
                loadingView
            } else if let error = errorMessage {
                errorView(error)
            } else if isBinary {
                binaryFileView
            } else if let content = content {
                codeView(content)
            } else {
                emptyView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("fileContentView")
        .task(id: file.id) {
            await loadContent()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading file...")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text("Failed to load file")
                .font(.headline)
            Text(error)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var binaryFileView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Binary File")
                .font(.headline)
            Text("This file cannot be displayed as text.")
                .font(.callout)
                .foregroundStyle(.secondary)

            if let size = file.size {
                Text("Size: \(FileSizeFormatter.format(size))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func codeView(_ content: String) -> some View {
        let lines = content.components(separatedBy: "\n")
        let language = detectLanguage()

        return GeometryReader { geometry in
            ScrollView([.horizontal, .vertical]) {
                HStack(alignment: .top, spacing: 0) {
                    // 라인 번호
                    LineNumbersView(lineCount: lines.count)

                    Divider()

                    // 코드 콘텐츠
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                            highlightedLine(line, language: language)
                                .frame(height: 20)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .font(.system(size: 12, design: .monospaced))
                .frame(minWidth: geometry.size.width, minHeight: geometry.size.height, alignment: .topLeading)
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .accessibilityIdentifier("codeScrollView")
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Empty File")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func highlightedLine(_ line: String, language: String?) -> some View {
        if let language = language {
            Text(highlighter.highlight(line, language: language))
                .textSelection(.enabled)
        } else {
            Text(line)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
    }

    private func loadContent() async {
        isLoading = true
        errorMessage = nil
        content = nil
        isBinary = false
        isTruncated = false

        // 바이너리 파일 체크
        if file.fileType == .binary || file.fileType == .image ||
            file.fileType == .video || file.fileType == .audio ||
            file.fileType == .archive {
            isBinary = true
            isLoading = false
            return
        }

        do {
            let fileContent = try await fileSystemService.readFileContent(
                at: file.path,
                maxSize: maxFileSize
            )

            // 바이너리 콘텐츠 체크 (null 바이트 포함)
            if fileContent.contains("\0") {
                isBinary = true
            } else {
                content = fileContent
                isTruncated = fileContent.contains("[... truncated")
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func detectLanguage() -> String? {
        guard let ext = file.fileExtension else { return nil }
        return extensionToLanguage(ext)
    }

    private func extensionToLanguage(_ ext: String) -> String? {
        switch ext {
        case "swift": return "swift"
        case "js", "jsx", "mjs": return "javascript"
        case "ts", "tsx": return "typescript"
        case "py", "pyw": return "python"
        case "rs": return "rust"
        case "go": return "go"
        case "java": return "java"
        case "kt", "kts": return "kotlin"
        case "rb": return "ruby"
        case "php": return "php"
        case "html", "htm": return "html"
        case "css", "scss": return "css"
        case "json": return "json"
        case "yaml", "yml": return "yaml"
        case "md", "markdown": return "markdown"
        case "sh", "bash", "zsh": return "bash"
        case "sql": return "sql"
        case "c", "h": return "c"
        case "cpp", "hpp", "cc": return "cpp"
        default: return nil
        }
    }

}

// MARK: - FileContentHeader

/// 파일 콘텐츠 헤더
struct FileContentHeader: View {
    let file: FileSystemItem
    let isBinary: Bool
    let isTruncated: Bool

    var body: some View {
        HStack(spacing: 8) {
            // 파일 아이콘
            FileTypeIcon(item: file)

            // 파일명
            Text(file.name)
                .font(.headline)
                .lineLimit(1)

            Spacer()

            // 경고 아이콘
            if isTruncated {
                Label("Truncated", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if isBinary {
                Label("Binary", systemImage: "doc.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 파일 크기
            if let size = file.size {
                Text(FileSizeFormatter.format(size))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

// MARK: - LineNumbersView

/// 라인 번호 뷰
struct LineNumbersView: View {
    let lineCount: Int

    /// 라인 번호 너비 계산
    private var lineNumberWidth: CGFloat {
        let digits = String(lineCount).count
        return CGFloat(digits * 10 + 16)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(1...max(lineCount, 1), id: \.self) { lineNumber in
                Text("\(lineNumber)")
                    .foregroundStyle(.secondary)
                    .frame(height: 20)
            }
        }
        .frame(width: lineNumberWidth)
        .padding(.horizontal, 8)
        .background(Color(nsColor: .controlBackgroundColor))
        .accessibilityIdentifier("lineNumbers")
    }
}

// MARK: - Preview

#Preview {
    let file = FileSystemItem(
        name: "test.swift",
        path: "/tmp/test.swift",
        isDirectory: false,
        size: 1024
    )
    return FileContentView(file: file)
        .frame(width: 600, height: 400)
}
