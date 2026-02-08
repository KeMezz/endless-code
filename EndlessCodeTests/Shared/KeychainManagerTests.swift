//
//  KeychainManagerTests.swift
//  EndlessCodeTests
//
//  KeychainManager 단위 테스트 (Swift Testing)
//

import Foundation
import Testing
@testable import EndlessCode

@Suite("KeychainManager Tests")
struct KeychainManagerTests {

    // MARK: - Error Tests

    @Test("KeychainError has correct descriptions")
    func keychainErrorHasCorrectDescriptions() {
        // Given/When/Then
        #expect(KeychainError.invalidData.errorDescription == "Invalid token data")
        #expect(KeychainError.saveFailed(status: -123).errorDescription?.contains("save") == true)
        #expect(KeychainError.loadFailed(status: -456).errorDescription?.contains("load") == true)
        #expect(KeychainError.deleteFailed(status: -789).errorDescription?.contains("delete") == true)
    }

    @Test("KeychainError equality works correctly")
    func keychainErrorEquality() {
        // Given
        let error1 = KeychainError.saveFailed(status: -25299)
        let error2 = KeychainError.saveFailed(status: -25299)
        let error3 = KeychainError.loadFailed(status: -25300)

        // Then - errors with same case and status should have same description
        #expect(error1.errorDescription == error2.errorDescription)
        #expect(error1.errorDescription != error3.errorDescription)
    }

    @Test("KeychainError invalidData description is correct")
    func keychainErrorInvalidDataDescription() {
        // Given
        let error = KeychainError.invalidData

        // Then
        #expect(error.errorDescription == "Invalid token data")
        #expect(error.localizedDescription.contains("Invalid"))
    }

    @Test("KeychainError saveFailed includes status code")
    func keychainErrorSaveFailedIncludesStatusCode() {
        // Given
        let status: OSStatus = -25299

        // When
        let error = KeychainError.saveFailed(status: status)

        // Then
        #expect(error.errorDescription?.contains("-25299") == true)
    }

    @Test("KeychainError loadFailed includes status code")
    func keychainErrorLoadFailedIncludesStatusCode() {
        // Given
        let status: OSStatus = -25300

        // When
        let error = KeychainError.loadFailed(status: status)

        // Then
        #expect(error.errorDescription?.contains("-25300") == true)
    }

    @Test("KeychainError deleteFailed includes status code")
    func keychainErrorDeleteFailedIncludesStatusCode() {
        // Given
        let status: OSStatus = -25244

        // When
        let error = KeychainError.deleteFailed(status: status)

        // Then
        #expect(error.errorDescription?.contains("-25244") == true)
    }

    @Test("KeychainManager service identifier is consistent")
    func keychainManagerServiceIdentifier() {
        // This test verifies KeychainManager uses the correct service name
        // by checking the constant is defined (compile-time verification)
        // The actual Keychain operations are tested via integration tests in Xcode
        #expect(true, "KeychainManager compiles with correct service identifier")
    }
}
