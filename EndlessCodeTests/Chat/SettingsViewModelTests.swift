//
//  SettingsViewModelTests.swift
//  EndlessCodeTests
//
//  SettingsViewModel 단위 테스트 (Swift Testing)
//

#if canImport(AppKit)
import Foundation
import Testing
@testable import EndlessCode

@Suite("SettingsViewModel Tests")
struct SettingsViewModelTests {

    // MARK: - Initialization Tests

    @Test("Init creates view model with default config")
    @MainActor
    func initCreatesViewModelWithDefaultConfig() {
        // Given/When
        let viewModel = SettingsViewModel()

        // Then
        #expect(viewModel.config.host == "127.0.0.1")
        #expect(viewModel.config.port == 8080)
        #expect(!viewModel.hasChanges)
        #expect(viewModel.isValid)
    }

    @Test("Init creates view model with custom config")
    @MainActor
    func initCreatesViewModelWithCustomConfig() {
        // Given
        var config = ServerConfiguration()
        config.host = "custom.host"
        config.port = 9090

        // When
        let viewModel = SettingsViewModel(config: config)

        // Then
        #expect(viewModel.config.host == "custom.host")
        #expect(viewModel.config.port == 9090)
        #expect(!viewModel.hasChanges)
    }

    // MARK: - hasChanges Tests

    @Test("hasChanges is false initially")
    @MainActor
    func hasChangesIsFalseInitially() {
        // Given
        let viewModel = SettingsViewModel()

        // When/Then
        #expect(!viewModel.hasChanges)
    }

    @Test("hasChanges is true after modifying config")
    @MainActor
    func hasChangesIsTrueAfterModifyingConfig() {
        // Given
        let viewModel = SettingsViewModel()

        // When
        viewModel.config.host = "modified.host"

        // Then
        #expect(viewModel.hasChanges)
    }

    @Test("hasChanges is true after modifying token")
    @MainActor
    func hasChangesIsTrueAfterModifyingToken() {
        // Given
        let viewModel = SettingsViewModel()

        // When
        viewModel.displayToken = "new-token"

        // Then
        #expect(viewModel.hasChanges)
    }

    // MARK: - isValid Tests

    @Test("isValid is true for default config")
    @MainActor
    func isValidIsTrueForDefaultConfig() {
        // Given
        let viewModel = SettingsViewModel()

        // When/Then
        #expect(viewModel.isValid)
    }

    @Test("isValid is false when host is empty")
    @MainActor
    func isValidIsFalseWhenHostIsEmpty() {
        // Given
        let viewModel = SettingsViewModel()

        // When
        viewModel.config.host = ""

        // Then
        #expect(!viewModel.isValid)
    }

    @Test("isValid is false when port is out of range")
    @MainActor
    func isValidIsFalseWhenPortIsOutOfRange() {
        // Given
        let viewModel = SettingsViewModel()

        // When
        viewModel.config.port = 0

        // Then
        #expect(!viewModel.isValid)

        // When
        viewModel.config.port = 65536

        // Then
        #expect(!viewModel.isValid)
    }

    @Test("isValid is false when CLI path is empty")
    @MainActor
    func isValidIsFalseWhenCLIPathIsEmpty() {
        // Given
        let viewModel = SettingsViewModel()

        // When
        viewModel.config.cliPath = ""

        // Then
        #expect(!viewModel.isValid)
    }

    @Test("isValid is false when CLI path has error")
    @MainActor
    func isValidIsFalseWhenCLIPathHasError() {
        // Given
        let viewModel = SettingsViewModel()
        viewModel.config.cliPath = "/nonexistent/path"

        // When
        viewModel.validateCLIPath()

        // Then
        #expect(!viewModel.isValid)
        #expect(viewModel.cliPathError != nil)
    }

    @Test("isValid is false when max sessions is zero")
    @MainActor
    func isValidIsFalseWhenMaxSessionsIsZero() {
        // Given
        let viewModel = SettingsViewModel()

        // When
        viewModel.config.maxConcurrentSessions = 0

        // Then
        #expect(!viewModel.isValid)
    }

    // MARK: - validateCLIPath Tests

    @Test("validateCLIPath sets error for nonexistent path")
    @MainActor
    func validateCLIPathSetsErrorForNonexistentPath() {
        // Given
        let viewModel = SettingsViewModel()
        viewModel.config.cliPath = "/nonexistent/path/to/cli"

        // When
        viewModel.validateCLIPath()

        // Then
        #expect(viewModel.cliPathError == "File does not exist")
    }

    @Test("validateCLIPath sets error for directory")
    @MainActor
    func validateCLIPathSetsErrorForDirectory() {
        // Given
        let viewModel = SettingsViewModel()
        viewModel.config.cliPath = "/tmp"

        // When
        viewModel.validateCLIPath()

        // Then
        #expect(viewModel.cliPathError == "Path is a directory, not a file")
    }

    @Test("validateCLIPath clears error for valid path")
    @MainActor
    func validateCLIPathClearsErrorForValidPath() {
        // Given
        let viewModel = SettingsViewModel()
        viewModel.config.cliPath = "/bin/ls" // Known executable

        // When
        viewModel.validateCLIPath()

        // Then
        #expect(viewModel.cliPathError == nil)
    }

    // MARK: - reset Tests

    @Test("reset restores default config")
    @MainActor
    func resetRestoresDefaultConfig() {
        // Given
        let viewModel = SettingsViewModel()
        viewModel.config.host = "modified.host"
        viewModel.config.port = 9999
        viewModel.displayToken = "test-token"

        // When
        viewModel.reset()

        // Then
        #expect(viewModel.config.host == "127.0.0.1")
        #expect(viewModel.config.port == 8080)
        #expect(viewModel.displayToken.isEmpty)
        #expect(!viewModel.hasChanges)
    }

    @Test("reset clears errors")
    @MainActor
    func resetClearsErrors() {
        // Given
        let viewModel = SettingsViewModel()
        viewModel.config.cliPath = "/nonexistent"
        viewModel.validateCLIPath()
        #expect(viewModel.cliPathError != nil)

        // When
        viewModel.reset()

        // Then
        #expect(viewModel.cliPathError == nil)
        #expect(viewModel.saveError == nil)
    }

    // MARK: - cancel Tests

    @Test("cancel restores original config")
    @MainActor
    func cancelRestoresOriginalConfig() {
        // Given
        var config = ServerConfiguration()
        config.host = "original.host"
        config.port = 8888
        let viewModel = SettingsViewModel(config: config)
        viewModel.config.host = "modified.host"
        viewModel.config.port = 9999

        // When
        viewModel.cancel()

        // Then
        #expect(viewModel.config.host == "original.host")
        #expect(viewModel.config.port == 8888)
        #expect(!viewModel.hasChanges)
    }

    // MARK: - generateToken Tests

    @Test("generateToken creates UUID token")
    @MainActor
    func generateTokenCreatesUUIDToken() {
        // Given
        let viewModel = SettingsViewModel()

        // When
        viewModel.generateToken()

        // Then
        #expect(!viewModel.displayToken.isEmpty)
        #expect(UUID(uuidString: viewModel.displayToken) != nil)
    }

    @Test("generateToken creates unique tokens")
    @MainActor
    func generateTokenCreatesUniqueTokens() {
        // Given
        let viewModel = SettingsViewModel()

        // When
        viewModel.generateToken()
        let token1 = viewModel.displayToken

        viewModel.generateToken()
        let token2 = viewModel.displayToken

        // Then
        #expect(token1 != token2)
    }

    // MARK: - toggleTokenVisibility Tests

    @Test("toggleTokenVisibility changes visibility state")
    @MainActor
    func toggleTokenVisibilityChangesVisibilityState() {
        // Given
        let viewModel = SettingsViewModel()
        let initial = viewModel.isTokenVisible

        // When
        viewModel.toggleTokenVisibility()

        // Then
        #expect(viewModel.isTokenVisible != initial)

        // When (again)
        viewModel.toggleTokenVisibility()

        // Then
        #expect(viewModel.isTokenVisible == initial)
    }

    // MARK: - save Tests

    @Test("save updates config auth token from display token")
    @MainActor
    func saveUpdatesConfigAuthTokenFromDisplayToken() {
        // Given
        let viewModel = SettingsViewModel()
        viewModel.displayToken = "test-token-123"

        // When
        viewModel.save()

        // Then
        #expect(viewModel.config.authToken == "test-token-123")
    }

    @Test("save sets auth token to nil when display token is empty")
    @MainActor
    func saveSetsAuthTokenToNilWhenDisplayTokenIsEmpty() {
        // Given
        var config = ServerConfiguration()
        config.authToken = "existing-token"
        let viewModel = SettingsViewModel(config: config)
        viewModel.displayToken = ""

        // When
        viewModel.save()

        // Then
        #expect(viewModel.config.authToken == nil)
    }

    @Test("save sets error when config is invalid")
    @MainActor
    func saveSetsErrorWhenConfigIsInvalid() {
        // Given
        let viewModel = SettingsViewModel()
        viewModel.config.host = "" // Invalid

        // When
        viewModel.save()

        // Then
        #expect(viewModel.saveError != nil)
    }

    // MARK: - clearError Tests

    @Test("clearError removes save error")
    @MainActor
    func clearErrorRemovesSaveError() {
        // Given
        let viewModel = SettingsViewModel()
        viewModel.config.host = ""
        viewModel.save()
        #expect(viewModel.saveError != nil)

        // When
        viewModel.clearError()

        // Then
        #expect(viewModel.saveError == nil)
    }

    // MARK: - Keychain Integration Tests

    @Test("saveTokenToKeychain stores token in Keychain")
    @MainActor
    func saveTokenToKeychainStoresTokenInKeychain() throws {
        // Given
        let viewModel = SettingsViewModel()
        viewModel.displayToken = "test-keychain-token"

        // When
        try viewModel.saveTokenToKeychain()

        // Then
        let loaded = try KeychainManager.loadToken()
        #expect(loaded == "test-keychain-token")

        // Cleanup
        try KeychainManager.deleteToken()
    }

    @Test("saveTokenToKeychain deletes token when display token is empty")
    @MainActor
    func saveTokenToKeychainDeletesTokenWhenDisplayTokenIsEmpty() throws {
        // Given
        try KeychainManager.saveToken("existing-token")
        let viewModel = SettingsViewModel()
        viewModel.displayToken = ""

        // When
        try viewModel.saveTokenToKeychain()

        // Then
        let loaded = try KeychainManager.loadToken()
        #expect(loaded == nil)
    }

    @Test("loadTokenFromKeychain loads token into display token")
    @MainActor
    func loadTokenFromKeychainLoadsTokenIntoDisplayToken() throws {
        // Given
        try KeychainManager.saveToken("keychain-token-123")
        let viewModel = SettingsViewModel()

        // When
        try viewModel.loadTokenFromKeychain()

        // Then
        #expect(viewModel.displayToken == "keychain-token-123")
        #expect(viewModel.config.authToken == "keychain-token-123")

        // Cleanup
        try KeychainManager.deleteToken()
    }

    @Test("loadTokenFromKeychain does not throw when no token exists")
    @MainActor
    func loadTokenFromKeychainDoesNotThrowWhenNoTokenExists() throws {
        // Given
        try? KeychainManager.deleteToken()
        let viewModel = SettingsViewModel()

        // When/Then (should not throw)
        try viewModel.loadTokenFromKeychain()
        #expect(viewModel.displayToken.isEmpty)
    }
}
#endif
