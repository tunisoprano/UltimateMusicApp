//
//  QuizChrome.swift
//  MusicTuner
//
//  Shared "Playful Premium" quiz UI (top bar, choice cards, check button)
//  used by Ear Training and Chord Mastery quiz screens — select an answer,
//  then confirm with a single bottom "Check" button (Duolingo-style).
//

import SwiftUI

// MARK: - Top Bar (close + progress + streak)

struct QuizTopBar: View {
    let progress: CGFloat
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "929277"))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(hex: "353534"))
                    Capsule()
                        .fill(LearningPath.acid)
                        .frame(width: max(10, geo.size.width * progress))
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 10)

            StreakBadgeView()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}

// MARK: - Choice Card

enum QuizChoiceResult {
    case none
    case correct
    case incorrect
}

struct QuizChoiceCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let result: QuizChoiceResult
    let action: () -> Void

    private var fill: Color {
        switch result {
        case .correct: return Color(hex: "1F3A0E")
        case .incorrect: return Color(hex: "3A0E0E")
        case .none: return Color(hex: "1F1F1F")
        }
    }

    private var borderColor: Color {
        switch result {
        case .correct: return .green
        case .incorrect: return .red
        case .none: return isSelected ? LearningPath.acid : .clear
        }
    }

    private var textColor: Color {
        switch result {
        case .correct: return .green
        case .incorrect: return .red
        case .none: return isSelected ? LearningPath.acid : Color(hex: "E2E2E2")
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .opacity(0.75)
            }
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 84)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(borderColor, lineWidth: 2.5)
                    .shadow(color: borderColor.opacity(borderColor == .clear ? 0 : 0.5), radius: 10)
            )
        }
    }
}

// MARK: - Check Button

struct QuizCheckButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(isEnabled ? Color(hex: "303300") : Color(hex: "929277"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(isEnabled ? LearningPath.acid : Color(hex: "2A2A2A"))
                )
        }
        .disabled(!isEnabled)
    }
}
