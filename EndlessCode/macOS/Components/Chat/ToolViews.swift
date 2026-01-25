//
//  ToolViews.swift
//  EndlessCode
//
//  도구 사용 및 결과 표시 컴포넌트
//

import SwiftUI

// MARK: - ToolUseView

/// 도구 사용 표시 뷰
struct ToolUseView: View {
    let toolName: String
    let toolUseId: String
    let input: [String: AnyCodableValue]
    let timestamp: Date

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if isExpanded {
                Divider()
                    .padding(.horizontal, 12)

                inputContent
            }
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .accessibilityIdentifier("toolUseView-\(toolUseId)")
    }

    // MARK: - Subviews

    @ViewBuilder
    private var header: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))

                    Image(systemName: toolIcon)
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                }
                .frame(width: 28, height: 28)

                // 도구 이름
                VStack(alignment: .leading, spacing: 2) {
                    Text(toolName)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(summaryText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // 확장 아이콘
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))

                // 타임스탬프
                Text(RelativeTimestampFormatter.shared.string(from: timestamp))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var inputContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(input.keys.sorted()), id: \.self) { key in
                HStack(alignment: .top, spacing: 8) {
                    Text(key)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .trailing)

                    Text(formatValue(input[key]))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .lineLimit(5)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Computed Properties

    private var toolIcon: String {
        switch toolName.lowercased() {
        case "read": return "doc.text"
        case "write": return "square.and.pencil"
        case "edit": return "pencil"
        case "bash": return "terminal"
        case "glob": return "folder"
        case "grep": return "magnifyingglass"
        case "task": return "gearshape"
        default: return "wrench"
        }
    }

    private var summaryText: String {
        if let path = input["file_path"] ?? input["path"],
           case .string(let pathString) = path {
            return pathString.components(separatedBy: "/").last ?? pathString
        }
        if let command = input["command"], case .string(let cmd) = command {
            return cmd.prefix(50) + (cmd.count > 50 ? "..." : "")
        }
        return "\(input.count) parameters"
    }

    private func formatValue(_ value: AnyCodableValue?) -> String {
        guard let value = value else { return "nil" }
        switch value {
        case .string(let s): return s
        case .int(let i): return String(i)
        case .double(let d): return String(format: "%.2f", d)
        case .bool(let b): return String(b)
        case .array(let arr): return "[\(arr.count) items]"
        case .dictionary(let dict): return "{\(dict.count) keys}"
        case .null: return "null"
        }
    }
}

// MARK: - ToolResultView

/// 도구 결과 표시 뷰
struct ToolResultView: View {
    let toolUseId: String
    let output: String
    let isError: Bool
    let timestamp: Date

    @State private var isExpanded = false

    private let maxCollapsedLines = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if isExpanded || outputLines.count <= maxCollapsedLines {
                Divider()
                    .padding(.horizontal, 12)

                outputContent
            }
        }
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, lineWidth: 1)
        )
        .accessibilityIdentifier("toolResultView-\(toolUseId)")
    }

    // MARK: - Subviews

    @ViewBuilder
    private var header: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                // 상태 아이콘
                ZStack {
                    Circle()
                        .fill(isError ? Color.red.opacity(0.15) : Color.green.opacity(0.15))

                    Image(systemName: isError ? "xmark" : "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isError ? .red : .green)
                }
                .frame(width: 28, height: 28)

                // 상태 텍스트
                VStack(alignment: .leading, spacing: 2) {
                    Text(isError ? "Error" : "Success")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(isError ? .red : .primary)

                    Text("\(outputLines.count) lines")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // 확장 아이콘 (긴 출력일 경우만)
                if outputLines.count > maxCollapsedLines {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }

                // 타임스탬프
                Text(RelativeTimestampFormatter.shared.string(from: timestamp))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(outputLines.count <= maxCollapsedLines)
    }

    @ViewBuilder
    private var outputContent: some View {
        ScrollView {
            Text(displayOutput)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(isError ? .red : .primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
        }
        .frame(maxHeight: isExpanded ? 300 : nil)
    }

    // MARK: - Computed Properties

    private var backgroundColor: some ShapeStyle {
        if isError {
            return AnyShapeStyle(Color.red.opacity(0.05))
        } else {
            return AnyShapeStyle(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        }
    }

    private var borderColor: Color {
        isError ? Color.red.opacity(0.3) : Color.green.opacity(0.3)
    }

    private var outputLines: [String] {
        output.components(separatedBy: "\n")
    }

    private var displayOutput: String {
        if isExpanded || outputLines.count <= maxCollapsedLines {
            return output
        } else {
            return outputLines.prefix(maxCollapsedLines).joined(separator: "\n") + "\n..."
        }
    }
}

// MARK: - Preview

#Preview("Tool Use - Read") {
    VStack(spacing: 16) {
        ToolUseView(
            toolName: "Read",
            toolUseId: "tool-1",
            input: [
                "file_path": .string("/Users/demo/project/ContentView.swift")
            ],
            timestamp: Date()
        )

        ToolUseView(
            toolName: "Bash",
            toolUseId: "tool-2",
            input: [
                "command": .string("git status"),
                "description": .string("Check git status")
            ],
            timestamp: Date()
        )
    }
    .frame(width: 400)
    .padding()
}

#Preview("Tool Result - Success") {
    VStack(spacing: 16) {
        ToolResultView(
            toolUseId: "tool-1",
            output: """
            struct ContentView: View {
                var body: some View {
                    Text("Hello, World!")
                }
            }
            """,
            isError: false,
            timestamp: Date()
        )

        ToolResultView(
            toolUseId: "tool-2",
            output: "On branch main\nnothing to commit, working tree clean",
            isError: false,
            timestamp: Date()
        )
    }
    .frame(width: 400)
    .padding()
}

#Preview("Tool Result - Error") {
    ToolResultView(
        toolUseId: "tool-3",
        output: "Error: File not found at path /Users/demo/missing.swift",
        isError: true,
        timestamp: Date()
    )
    .frame(width: 400)
    .padding()
}
