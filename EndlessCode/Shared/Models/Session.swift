//
//  Session.swift
//  EndlessCode
//
//  세션 관련 모델 정의
//

import Foundation

// MARK: - Session

/// 세션 정보
struct Session: Codable, Sendable, Identifiable, Equatable, Hashable {
    let id: String
    let projectId: String
    var state: SessionState
    let createdAt: Date
    var lastActiveAt: Date
    var messageCount: Int

    nonisolated init(
        id: String = UUID().uuidString,
        projectId: String,
        state: SessionState = .active,
        createdAt: Date = Date(),
        lastActiveAt: Date = Date(),
        messageCount: Int = 0
    ) {
        self.id = id
        self.projectId = projectId
        self.state = state
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.messageCount = messageCount
    }
}

// MARK: - SessionState

/// 세션 상태
enum SessionState: String, Codable, Sendable, Equatable, Hashable {
    case active
    case paused
    case terminated
}

// MARK: - SessionSummary

/// 세션 요약 정보 (목록 표시용)
struct SessionSummary: Codable, Sendable, Identifiable, Equatable {
    let id: String
    let projectId: String
    let projectName: String
    let state: SessionState
    let lastMessage: String?
    let lastActiveAt: Date
    let messageCount: Int
}
