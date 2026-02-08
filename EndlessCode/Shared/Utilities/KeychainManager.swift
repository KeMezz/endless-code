//
//  KeychainManager.swift
//  EndlessCode
//
//  Keychain을 통한 인증 토큰 관리
//

import Foundation
import Security

// MARK: - KeychainManager

/// Keychain을 통한 인증 토큰 관리
enum KeychainManager {
    /// 서비스 이름 (앱 식별자)
    private static let service = "com.endlesscode.auth-token"

    /// 계정 이름 (토큰 키)
    private static let account = "auth-token"

    // MARK: - Public Methods

    /// 인증 토큰 저장
    /// - Parameter token: 저장할 토큰
    /// - Throws: KeychainError
    static func saveToken(_ token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        // 기존 토큰 삭제 (있을 경우)
        try? deleteToken()

        // 새 토큰 저장
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }
    }

    /// 인증 토큰 로드
    /// - Returns: 저장된 토큰 (없으면 nil)
    /// - Throws: KeychainError
    static func loadToken() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        // 토큰이 없는 경우 nil 반환
        guard status != errSecItemNotFound else {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.loadFailed(status: status)
        }

        guard let data = item as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return token
    }

    /// 인증 토큰 삭제
    /// - Throws: KeychainError
    static func deleteToken() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        // 토큰이 없는 경우는 에러가 아님
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: status)
        }
    }
}

// MARK: - KeychainError

/// Keychain 에러
enum KeychainError: Error, LocalizedError {
    case invalidData
    case saveFailed(status: OSStatus)
    case loadFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid token data"
        case .saveFailed(let status):
            return "Failed to save token (status: \(status))"
        case .loadFailed(let status):
            return "Failed to load token (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete token (status: \(status))"
        }
    }
}
