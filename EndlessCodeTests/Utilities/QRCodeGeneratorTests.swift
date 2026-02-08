//
//  QRCodeGeneratorTests.swift
//  EndlessCodeTests
//
//  QRCodeGenerator 테스트
//

import Testing
import Foundation
import AppKit
@testable import EndlessCode

// MARK: - QRCodeGenerator Tests

@Suite("QRCodeGenerator Tests")
struct QRCodeGeneratorTests {
    // MARK: - Generation Tests

    @Test("유효한 문자열로 QR 코드 생성")
    func generateReturnsImageForValidString() async throws {
        // Given
        let input = "https://example.com"

        // When
        let result = QRCodeGenerator.generate(from: input)

        // Then
        #expect(result != nil)
    }

    @Test("생성된 QR 코드의 크기 확인")
    func generatedImageHasCorrectSize() async throws {
        // Given
        let input = "test data"
        let size: CGFloat = 300

        // When
        let result = QRCodeGenerator.generate(from: input, size: size)

        // Then
        #expect(result != nil)
        #expect(result?.size.width == size)
        #expect(result?.size.height == size)
    }

    @Test("기본 크기로 QR 코드 생성")
    func generateUsesDefaultSize() async throws {
        // Given
        let input = "test"

        // When
        let result = QRCodeGenerator.generate(from: input)

        // Then
        #expect(result != nil)
        #expect(result?.size.width == 200)
        #expect(result?.size.height == 200)
    }

    @Test("JSON 데이터로 QR 코드 생성")
    func generateHandlesJSONData() async throws {
        // Given
        let json = #"{"host":"localhost","port":"8080","token":"abc123"}"#

        // When
        let result = QRCodeGenerator.generate(from: json)

        // Then
        #expect(result != nil)
    }

    @Test("한글 문자열로 QR 코드 생성")
    func generateHandlesKoreanText() async throws {
        // Given
        let korean = "안녕하세요"

        // When
        let result = QRCodeGenerator.generate(from: korean)

        // Then
        #expect(result != nil)
    }

    @Test("긴 문자열로 QR 코드 생성")
    func generateHandlesLongString() async throws {
        // Given
        let longString = String(repeating: "A", count: 1000)

        // When
        let result = QRCodeGenerator.generate(from: longString)

        // Then
        #expect(result != nil)
    }

    @Test("빈 문자열로 QR 코드 생성")
    func generateHandlesEmptyString() async throws {
        // Given
        let empty = ""

        // When
        let result = QRCodeGenerator.generate(from: empty)

        // Then
        // 빈 문자열도 유효한 QR 코드를 생성할 수 있음
        #expect(result != nil)
    }

    @Test("다양한 크기로 QR 코드 생성")
    func generateHandlesVariousSizes() async throws {
        // Given
        let input = "test"
        let sizes: [CGFloat] = [50, 100, 200, 400, 800]

        // When & Then
        for size in sizes {
            let result = QRCodeGenerator.generate(from: input, size: size)
            #expect(result != nil)
            #expect(result?.size.width == size)
            #expect(result?.size.height == size)
        }
    }
}
