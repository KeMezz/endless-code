//
//  iOSNavigationModels.swift
//  EndlessCode
//
//  iOS 네비게이션 및 서버 발견 관련 모델
//

#if os(iOS)
import Foundation

// MARK: - DiscoveredServer

/// Bonjour로 발견된 서버 정보
struct DiscoveredServer: Identifiable, Sendable, Equatable {
    let id: UUID
    let name: String
    let address: String
    let port: Int

    init(
        id: UUID = UUID(),
        name: String,
        address: String,
        port: Int
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.port = port
    }

    /// 전체 서버 URL
    var fullURL: String {
        "http://\(address):\(port)"
    }
}

// MARK: - QRCodeData

/// QR 코드로 전달되는 서버 정보
struct QRCodeData: Codable, Sendable, Equatable {
    let serverAddress: String
    let authToken: String?

    /// JSON 문자열로 인코딩
    func toJSON() throws -> String {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        guard let json = String(data: data, encoding: .utf8) else {
            throw QRCodeError.encodingFailed
        }
        return json
    }

    /// JSON 문자열에서 디코딩
    static func fromJSON(_ json: String) throws -> QRCodeData {
        guard let data = json.data(using: .utf8) else {
            throw QRCodeError.invalidJSON
        }
        let decoder = JSONDecoder()
        return try decoder.decode(QRCodeData.self, from: data)
    }
}

// MARK: - QRCodeError

/// QR 코드 관련 에러
enum QRCodeError: Error, LocalizedError {
    case invalidJSON
    case encodingFailed
    case scanningFailed

    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "Invalid QR code data format"
        case .encodingFailed:
            return "Failed to encode QR code data"
        case .scanningFailed:
            return "Failed to scan QR code"
        }
    }
}
#endif
