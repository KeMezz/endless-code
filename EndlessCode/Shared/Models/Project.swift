//
//  Project.swift
//  EndlessCode
//
//  프로젝트 관련 모델 정의
//

import Foundation

// MARK: - Project

/// 프로젝트 정보
struct Project: Codable, Sendable, Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let path: String
    var sessionCount: Int
    var lastUsed: Date?

    nonisolated init(
        id: String,
        name: String,
        path: String,
        sessionCount: Int = 0,
        lastUsed: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.sessionCount = sessionCount
        self.lastUsed = lastUsed
    }

    /// 프로젝트 경로에서 이름 추출
    nonisolated static func nameFromPath(_ path: String) -> String {
        URL(fileURLWithPath: path).lastPathComponent
    }
}

// MARK: - ProjectSummary

/// 프로젝트 요약 정보 (목록 표시용)
struct ProjectSummary: Codable, Sendable, Identifiable, Equatable {
    let id: String
    let name: String
    let path: String
    let sessionCount: Int
    let activeSessions: Int
    let lastUsed: Date?
}
