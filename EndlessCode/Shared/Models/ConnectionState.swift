//
//  ConnectionState.swift
//  EndlessCode
//
//  연결 상태 열거형 - UI와 Client 모두에서 사용
//

import Foundation

// MARK: - ConnectionState

/// 연결 상태
enum ConnectionState: Sendable, Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)
    case failed(error: String)
}
