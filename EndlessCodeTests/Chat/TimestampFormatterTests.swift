//
//  TimestampFormatterTests.swift
//  EndlessCodeTests
//
//  RelativeTimestampFormatter 단위 테스트 (Swift Testing)
//

import Foundation
import Testing
@testable import EndlessCode

@Suite("RelativeTimestampFormatter Tests")
struct TimestampFormatterTests {

    // MARK: - Recent Time Tests

    @Test("Formats as 'Just now' for very recent times")
    func formatsAsJustNowForVeryRecentTimes() {
        // Given
        let formatter = RelativeTimestampFormatter.shared
        let date = Date()

        // When
        let result = formatter.string(from: date)

        // Then
        #expect(result == "Just now")
    }

    @Test("Formats as relative time for within an hour")
    func formatsAsRelativeTimeWithinAnHour() {
        // Given
        let formatter = RelativeTimestampFormatter.shared
        let date = Date().addingTimeInterval(-300) // 5 minutes ago

        // When
        let result = formatter.string(from: date)

        // Then
        #expect(result.contains("min") || result.contains("ago"))
    }

    // MARK: - Today/Yesterday Tests

    @Test("Formats with 'Today' for times over an hour ago today")
    func formatsWithTodayForTimesOverAnHour() {
        // Given
        let formatter = RelativeTimestampFormatter.shared
        let calendar = Calendar.current

        // Create a time earlier today (more than an hour ago)
        guard let startOfToday = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date()),
              let twoHoursAgo = calendar.date(byAdding: .hour, value: -2, to: Date()),
              twoHoursAgo > startOfToday else {
            // If it's too early in the day, skip this test
            return
        }

        // When
        let result = formatter.string(from: twoHoursAgo)

        // Then
        #expect(result.contains("Today") || result.contains(":"))
    }

    @Test("Formats with 'Yesterday' for yesterday's times")
    func formatsWithYesterdayForYesterdayTimes() {
        // Given
        let formatter = RelativeTimestampFormatter.shared
        let calendar = Calendar.current

        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()),
              let yesterdayMidDay = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: yesterday) else {
            return
        }

        // When
        let result = formatter.string(from: yesterdayMidDay)

        // Then
        #expect(result.contains("Yesterday"))
    }

    // MARK: - Older Dates Tests

    @Test("Formats with date for older times")
    func formatsWithDateForOlderTimes() {
        // Given
        let formatter = RelativeTimestampFormatter.shared
        let calendar = Calendar.current

        guard let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date()) else {
            return
        }

        // When
        let result = formatter.string(from: twoDaysAgo)

        // Then
        // Should contain month abbreviation or date format
        #expect(!result.contains("Today"))
        #expect(!result.contains("Yesterday"))
        #expect(!result.contains("Just now"))
    }

    // MARK: - Singleton Tests

    @Test("Shared instance is same object")
    func sharedInstanceIsSameObject() {
        // Given/When
        let instance1 = RelativeTimestampFormatter.shared
        let instance2 = RelativeTimestampFormatter.shared

        // Then
        #expect(instance1 === instance2)
    }
}
