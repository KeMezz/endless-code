//
//  FormatHelpers.swift
//  EndlessCode
//
//  공유 포맷팅 유틸리티 - 코드 중복 제거용
//

import SwiftUI

// MARK: - AnyCodableValue Formatter

/// AnyCodableValue 포맷팅 유틸리티
enum AnyCodableValueFormatter {
    static func format(_ value: AnyCodableValue?) -> String {
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

// MARK: - SessionState Color Extension

extension SessionState {
    /// 세션 상태에 대응하는 색상
    var color: Color {
        switch self {
        case .active: return .green
        case .paused: return .orange
        case .terminated: return .gray
        }
    }
}

// MARK: - DiffFileStatus Color Extension

extension DiffFileStatus {
    /// Diff 파일 상태에 대응하는 색상
    var color: Color {
        switch self {
        case .added: return .green
        case .deleted: return .red
        case .modified: return .orange
        case .renamed: return .blue
        case .copied: return .purple
        }
    }
}

// MARK: - FileSizeFormatter

/// 파일 크기 포맷팅 유틸리티
enum FileSizeFormatter {
    static func format(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - RelativeTimestampFormatter

/// 상대 시간 포맷터 (스레드 안전)
final class RelativeTimestampFormatter: @unchecked Sendable {
    static let shared = RelativeTimestampFormatter()

    private let lock = NSLock()
    private let relativeFormatter: RelativeDateTimeFormatter
    private let timeFormatter: DateFormatter
    private let dateTimeFormatter: DateFormatter

    private init() {
        relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .short

        timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        dateTimeFormatter = DateFormatter()
        dateTimeFormatter.dateFormat = "MMM d, HH:mm"
    }

    func string(from date: Date) -> String {
        lock.lock()
        defer { lock.unlock() }

        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        } else {
            let calendar = Calendar.current
            if calendar.isDateInToday(date) {
                return "Today \(timeFormatter.string(from: date))"
            } else if calendar.isDateInYesterday(date) {
                return "Yesterday \(timeFormatter.string(from: date))"
            } else {
                return dateTimeFormatter.string(from: date)
            }
        }
    }
}
