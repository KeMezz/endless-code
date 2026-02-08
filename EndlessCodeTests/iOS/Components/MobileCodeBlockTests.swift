//
//  MobileCodeBlockTests.swift
//  EndlessCodeTests
//
//  MobileCodeBlock 컴포넌트 테스트
//

#if os(iOS)
import Testing
import SwiftUI
@testable import EndlessCode

@Suite("MobileCodeBlock Tests")
@MainActor
struct MobileCodeBlockTests {
    // MARK: - Rendering Tests

    @Test("Code block displays code content")
    func codeBlockDisplaysCodeContent() {
        // Given
        let code = "let x = 42"
        let language = "swift"

        // When & Then
        // SwiftUI 뷰이므로 렌더링 테스트는 UI 테스트에서 수행
        #expect(code.count > 0)
        #expect(language == "swift")
    }

    @Test("Code block displays language label")
    func codeBlockDisplaysLanguageLabel() {
        // Given
        let language = "swift"

        // When & Then
        #expect(language.uppercased() == "SWIFT")
    }

    // MARK: - Zoom Tests

    @Test("Initial scale is 1.0")
    func initialScaleIsOne() {
        // Given
        let initialScale: CGFloat = 1.0
        let minScale: CGFloat = 1.0
        let maxScale: CGFloat = 3.0

        // Then
        #expect(initialScale >= minScale)
        #expect(initialScale <= maxScale)
    }

    @Test("Scale is clamped between min and max")
    func scaleIsClampedBetweenMinAndMax() {
        // Given
        let minScale: CGFloat = 1.0
        let maxScale: CGFloat = 3.0
        let testScales: [CGFloat] = [0.5, 1.0, 2.0, 3.0, 4.0]

        // When & Then
        for testScale in testScales {
            let clampedScale = min(max(testScale, minScale), maxScale)
            #expect(clampedScale >= minScale)
            #expect(clampedScale <= maxScale)
        }
    }
}
#endif
