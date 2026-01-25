//
//  ProjectCard.swift
//  EndlessCode
//
//  프로젝트 카드 컴포넌트
//

import SwiftUI

// MARK: - ProjectCard

/// 프로젝트 카드 컴포넌트
struct ProjectCard: View {
    let project: Project
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 프로젝트 아이콘
                ProjectIcon(name: project.name)

                // 프로젝트 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(project.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                // 세션 수 뱃지
                if project.sessionCount > 0 {
                    SessionCountBadge(count: project.sessionCount)
                }

                // 화살표
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("projectCard-\(project.id)")
    }
}

// MARK: - ProjectIcon

/// 프로젝트 아이콘
struct ProjectIcon: View {
    let name: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(iconColor.gradient)
                .frame(width: 40, height: 40)

            Text(iconLetter)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
    }

    private var iconLetter: String {
        String(name.prefix(1)).uppercased()
    }

    private var iconColor: Color {
        // 이름 기반으로 색상 결정 (일관성 유지)
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .teal, .indigo]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - SessionCountBadge

/// 세션 수 뱃지
struct SessionCountBadge: View {
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.caption2)

            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.secondary.opacity(0.1))
        )
    }
}

// MARK: - ProjectCardCompact

/// 컴팩트 프로젝트 카드 (목록용)
struct ProjectCardCompact: View {
    let project: Project
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            ProjectIcon(name: project.name)
                .scaleEffect(0.8)

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(lastAccessedText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if project.sessionCount > 0 {
                Text("\(project.sessionCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
    }

    private var lastAccessedText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: project.lastAccessedAt, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview("Project Card") {
    VStack(spacing: 8) {
        ProjectCard(
            project: Project.sampleProjects[0],
            isSelected: false,
            onTap: {}
        )

        ProjectCard(
            project: Project.sampleProjects[1],
            isSelected: true,
            onTap: {}
        )
    }
    .padding()
    .frame(width: 350)
}

#Preview("Project Card Compact") {
    VStack(spacing: 4) {
        ForEach(Project.sampleProjects) { project in
            ProjectCardCompact(
                project: project,
                isSelected: project.id == "project-1"
            )
        }
    }
    .padding()
    .frame(width: 280)
}
