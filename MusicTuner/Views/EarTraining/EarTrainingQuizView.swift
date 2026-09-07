//
//  EarTrainingQuizView.swift
//  MusicTuner
//
//  Quiz phase for Ear Training
//  Plays chord audio, 4 answer buttons, feedback animations
//  Matches QuizSessionView pattern
//

import SwiftUI

struct EarTrainingQuizView: View {
    let level: LevelDefinition

    @StateObject private var viewModel = EarTrainingViewModel()
    @ObservedObject var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedAnswer: ChordDefinition? = nil
    @State private var showResults: Bool = false
    @State private var navigateToNextLevel: Bool = false
    @AppStorage("showLessonPreview") private var showLessonPreview: Bool = true

    var body: some View {
        ZStack {
            Color(hex: "131313").ignoresSafeArea()

            VStack(spacing: 0) {
                switch viewModel.state {
                case .idle:
                    loadingView
                case .quizzing(_, _, let chord):
                    quizContent(chord: chord)
                case .completed(_, let score, let total, let passed):
                    resultsView(score: score, total: total, passed: passed)
                default:
                    loadingView
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .environment(\.colorScheme, .dark)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $navigateToNextLevel) {
            if let nextLevel = EarTrainingCurriculum.nextLevel(after: level) {
                if showLessonPreview {
                    EarTrainingLearningView(level: nextLevel)
                } else {
                    EarTrainingQuizView(level: nextLevel)
                }
            }
        }
        .onAppear {
            // Start quiz for this level
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.retryQuiz(level)
            }
        }
        .onChange(of: viewModel.questionNumber) { _, _ in
            selectedAnswer = nil
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(LearningPath.acid)

            Text(L("loading_quiz"))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "C8C8AB"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Quiz Content

    private func quizContent(chord: ChordDefinition) -> some View {
        let progress = viewModel.totalQuestions > 0 ? CGFloat(viewModel.questionNumber - 1) / CGFloat(viewModel.totalQuestions) : 0

        return VStack(spacing: 28) {
            QuizTopBar(progress: progress) { AppRouter.shared.goHome() }

            Text(L("what_chord_sounds"))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "C8C8AB"))

            playAudioSection(chord: chord)

            Spacer()

            if let question = viewModel.currentQuizQuestion {
                answerGrid(options: question.options, correctChord: chord)
            }

            Spacer().frame(height: 12)
        }
        .padding(.top, 8)
    }

    // MARK: - Play Audio Section (big glowing tap-to-listen button)

    private func playAudioSection(chord: ChordDefinition) -> some View {
        VStack(spacing: 14) {
            Button {
                viewModel.replayQuizChord()
            } label: {
                ZStack {
                    Circle()
                        .fill(LearningPath.acid.opacity(0.18))
                        .frame(width: 150, height: 150)

                    Circle()
                        .fill(LearningPath.acid)
                        .frame(width: 96, height: 96)
                        .shadow(color: LearningPath.acid.opacity(0.6), radius: 24)

                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Color(hex: "303300"))
                }
            }

            Text(L("tap_to_listen").uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(Color(hex: "929277"))
        }
    }

    // MARK: - Answer Grid

    private func answerGrid(options: [ChordDefinition], correctChord: ChordDefinition) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(options) { option in
                QuizChoiceCard(
                    title: option.rootNote.displayName,
                    subtitle: option.type.localizedName,
                    isSelected: selectedAnswer == option,
                    result: choiceResult(for: option, correctChord: correctChord)
                ) {
                    guard viewModel.lastAnswerCorrect == nil else { return }
                    selectedAnswer = option
                    viewModel.submitAnswer(option)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func choiceResult(for option: ChordDefinition, correctChord: ChordDefinition) -> QuizChoiceResult {
        guard viewModel.lastAnswerCorrect != nil else { return .none }
        let isCorrectAnswer = option.rootNote == correctChord.rootNote && option.type == correctChord.type
        if isCorrectAnswer { return .correct }
        if selectedAnswer == option { return .incorrect }
        return .none
    }

    // MARK: - Results View

    private func resultsView(score: Int, total: Int, passed: Bool) -> some View {
        let nextLevel = EarTrainingCurriculum.nextLevel(after: level)
        let isLastLevel = nextLevel == nil

        return VStack(spacing: 24) {
            Spacer()

            // Result Icon
            ZStack {
                Circle()
                    .fill(passed ?
                          LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 120, height: 120)
                    .shadow(color: passed ? .green.opacity(0.3) : .red.opacity(0.3), radius: 20)

                Image(systemName: passed ? "trophy.fill" : "xmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
            }

            // Title
            Text(passed ? L("level_complete") : L("level_failed"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)

            // Score
            VStack(spacing: 8) {
                Text(L("your_score"))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textSecondary)

                Text("\(viewModel.scorePercentage)%")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(passed ? .green : .orange)

                Text("\(score) / \(total)")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textSecondary)

                // Pass threshold info
                Text(L("pass_threshold"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textSecondary.opacity(0.7))
            }

            // Next Level Unlocked Message
            if passed, let next = nextLevel {
                HStack(spacing: 8) {
                    Image(systemName: "lock.open.fill")
                    Text(L("next_level_unlocked", next.localizedTitle))
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.green)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: ThemeManager.radiusSmall)
                        .fill(Color.green.opacity(0.15))
                )
            }

            Spacer()

            // Action Buttons
            VStack(spacing: 12) {
                // 1. Next Level Button (always shown if not last level, disabled when not passed)
                if !isLastLevel {
                    Button {
                        navigateToNextLevel = true
                    } label: {
                        HStack(spacing: 8) {
                            Text(L("next_level"))
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                                .fill(LinearGradient(
                                    colors: passed ? [.green, .teal] : [.gray, .gray.opacity(0.7)],
                                    startPoint: .leading, endPoint: .trailing))
                                .shadow(color: passed ? .green.opacity(0.3) : .clear, radius: 10)
                        )
                    }
                    .disabled(!passed)
                    .opacity(passed ? 1.0 : 0.5)
                }

                // 2. Try Again Button
                Button {
                    selectedAnswer = nil
                    viewModel.retryQuiz(level)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text(L("try_again"))
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(passed ? theme.textPrimary : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                            .fill(passed ?
                                  AnyShapeStyle(theme.cardBackground) :
                                  AnyShapeStyle(LinearGradient(colors: level.gradientColors, startPoint: .leading, endPoint: .trailing)))
                            .shadow(color: theme.shadow, radius: 6)
                    )
                }

                // 3. Back to Levels Button
                Button {
                    dismiss()
                } label: {
                    Text(L("back_to_levels"))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EarTrainingQuizView(level: EarTrainingCurriculum.levels[0])
    }
}
