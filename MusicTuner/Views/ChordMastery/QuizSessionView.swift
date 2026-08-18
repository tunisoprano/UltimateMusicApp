//
//  QuizSessionView.swift
//  MusicTuner
//
//  Quiz phase for Chord Mastery
//  Shows chord diagram, 4 answer buttons, feedback animations
//

import SwiftUI

struct QuizSessionView: View {
    let level: LevelDefinition

    @StateObject private var viewModel = ChordMasteryViewModel()
    @ObservedObject var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedAnswer: ChordDefinition? = nil
    @State private var showResults: Bool = false
    @State private var navigateToNextLevel: Bool = false
    @State private var pressedAnswer: ChordDefinition? = nil
    @State private var scoreAnimated: Bool = false

    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()

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
        .navigationTitle(L("quiz"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.background, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToNextLevel) {
            if let nextLevel = ChordCurriculum.nextLevel(after: level) {
                LearningSessionView(level: nextLevel)
            }
        }
        .onAppear {
            // Start quiz for this level
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.retryQuiz(level)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(theme.accent)

            Text(L("loading_quiz"))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Quiz Content

    private func quizContent(chord: ChordDefinition) -> some View {
        VStack(spacing: 20) {
            // Progress Header
            quizProgressHeader

            // Question
            Text(L("what_chord_is_this"))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textPrimary)

            // Chord Diagram (without name for quiz)
            quizChordDiagram(chord: chord)

            Spacer()

            // Answer Buttons
            if let question = viewModel.currentQuizQuestion {
                answerButtons(options: question.options, correctChord: chord)
            }

            Spacer().frame(height: 20)
        }
        .padding(.top, 16)
    }

    // MARK: - Progress Header

    private var quizProgressHeader: some View {
        VStack(spacing: 8) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.cardBackground)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: level.gradientColors, startPoint: .leading, endPoint: .trailing))
                        .frame(width: geometry.size.width * CGFloat(viewModel.questionNumber) / CGFloat(viewModel.totalQuestions))
                        .animation(.easeInOut, value: viewModel.questionNumber)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 20)

            // Question Counter
            Text(L("question_n_of_m", viewModel.questionNumber, viewModel.totalQuestions))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textSecondary)

            // Score
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("\(viewModel.score)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
            }
        }
    }

    // MARK: - Chord Diagram (Quiz mode - no name shown)

    private func quizChordDiagram(chord: ChordDefinition) -> some View {
        // Use a simplified diagram without the chord name
        ZStack {
            RoundedRectangle(cornerRadius: ThemeManager.radiusLarge)
                .fill(theme.cardBackground)
                .shadow(color: theme.shadow, radius: 10, y: 5)

            // We'll show the diagram but need to hide the name
            ChordDiagramView(chord: chord, showName: false) {
                // No tap action during quiz
            }
        }
        .frame(height: 320)
        .padding(.horizontal, 20)
        .overlay(
            feedbackOverlay
        )
    }

    // MARK: - Feedback Overlay

    @ViewBuilder
    private var feedbackOverlay: some View {
        if let isCorrect = viewModel.lastAnswerCorrect {
            ZStack {
                RoundedRectangle(cornerRadius: ThemeManager.radiusLarge)
                    .fill(isCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3))

                VStack(spacing: 12) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(isCorrect ? .green : .red)

                    if !isCorrect, let correctChord = viewModel.correctAnswerChord {
                        Text(L("correct_answer_was", correctChord.name))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.textPrimary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: viewModel.lastAnswerCorrect)
        }
    }

    // MARK: - Answer Buttons

    private func answerButtons(options: [ChordDefinition], correctChord: ChordDefinition) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(options) { option in
                answerButton(chord: option, correctChord: correctChord)
            }
        }
        .padding(.horizontal, 20)
        .disabled(viewModel.lastAnswerCorrect != nil)
    }

    private func answerButton(chord: ChordDefinition, correctChord: ChordDefinition) -> some View {
        let isSelected = selectedAnswer == chord
        let isCorrectAnswer = chord.rootNote == correctChord.rootNote && chord.type == correctChord.type
        let showFeedback = viewModel.lastAnswerCorrect != nil
        let isPressed = pressedAnswer == chord

        return Button {
            guard viewModel.lastAnswerCorrect == nil else { return }
            pressedAnswer = chord
            selectedAnswer = chord
            viewModel.submitAnswer(chord)
            // Reset press state quickly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                pressedAnswer = nil
            }
        } label: {
            Text(chord.name)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(buttonTextColor(isSelected: isSelected, isCorrect: isCorrectAnswer, showFeedback: showFeedback))
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(
                    RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                        .fill(buttonBackground(isSelected: isSelected, isCorrect: isCorrectAnswer, showFeedback: showFeedback))
                        .shadow(
                            color: showFeedback && isCorrectAnswer ? Color.green.opacity(0.35) :
                                   showFeedback && isSelected && !isCorrectAnswer ? Color.red.opacity(0.3) :
                                   theme.shadow,
                            radius: showFeedback && (isCorrectAnswer || (isSelected && !isCorrectAnswer)) ? 10 : 6
                        )
                )
                .scaleEffect(isPressed ? 0.94 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
                .animation(.easeInOut(duration: 0.2), value: showFeedback)
        }
    }

    private func buttonTextColor(isSelected: Bool, isCorrect: Bool, showFeedback: Bool) -> Color {
        if showFeedback && isCorrect {
            return .white
        } else if showFeedback && isSelected && !isCorrect {
            return .white
        }
        return theme.textPrimary
    }

    private func buttonBackground(isSelected: Bool, isCorrect: Bool, showFeedback: Bool) -> some ShapeStyle {
        if showFeedback && isCorrect {
            return AnyShapeStyle(Color.green)
        } else if showFeedback && isSelected && !isCorrect {
            return AnyShapeStyle(Color.red)
        }
        return AnyShapeStyle(theme.cardBackground)
    }

    // MARK: - Results View

    private func resultsView(score: Int, total: Int, passed: Bool) -> some View {
        let nextLevel = ChordCurriculum.nextLevel(after: level)
        let isLastLevel = nextLevel == nil
        let accentColor: Color = passed ? .green : .orange

        return VStack(spacing: 0) {
            Spacer()

            // Result Icon with outer glow rings
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 180, height: 180)
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: passed ? [.green, .teal] : [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: accentColor.opacity(0.4), radius: 20, x: 0, y: 8)

                Image(systemName: passed ? "trophy.fill" : "arrow.counterclockwise.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
            }
            .scaleEffect(scoreAnimated ? 1.0 : 0.6)
            .opacity(scoreAnimated ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.1), value: scoreAnimated)

            Spacer().frame(height: 24)

            // Title
            Text(passed ? L("level_complete") : L("level_failed"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
                .opacity(scoreAnimated ? 1.0 : 0.0)
                .offset(y: scoreAnimated ? 0 : 12)
                .animation(.easeOut(duration: 0.35).delay(0.25), value: scoreAnimated)

            Spacer().frame(height: 20)

            // Score Card
            VStack(spacing: 6) {
                Text("\(viewModel.scorePercentage)%")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
                    .contentTransition(.numericText())

                Text("\(score) / \(total) \(L("your_score").lowercased())")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textSecondary)

                Text(L("pass_threshold"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textSecondary.opacity(0.6))
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 32)
            .background(
                RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                    .fill(theme.cardBackground)
                    .shadow(color: theme.shadow, radius: 10, x: 0, y: 4)
            )
            .padding(.horizontal, 32)
            .opacity(scoreAnimated ? 1.0 : 0.0)
            .offset(y: scoreAnimated ? 0 : 16)
            .animation(.easeOut(duration: 0.35).delay(0.35), value: scoreAnimated)

            // Next Level Unlocked badge
            if passed, let next = nextLevel {
                Spacer().frame(height: 16)
                HStack(spacing: 8) {
                    Image(systemName: "lock.open.fill")
                    Text(L("next_level_unlocked", next.localizedTitle))
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.green)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.12))
                )
                .opacity(scoreAnimated ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.35).delay(0.45), value: scoreAnimated)
            }

            Spacer()

            // Action Buttons
            VStack(spacing: 12) {
                if !isLastLevel {
                    Button {
                        navigateToNextLevel = true
                    } label: {
                        HStack(spacing: 8) {
                            Text(L("next_level"))
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                                .fill(LinearGradient(
                                    colors: passed ? [.green, .teal] : [Color.gray.opacity(0.5), Color.gray.opacity(0.35)],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .shadow(color: passed ? Color.green.opacity(0.3) : .clear, radius: 10)
                        )
                    }
                    .disabled(!passed)
                    .opacity(passed ? 1.0 : 0.45)
                }

                Button {
                    selectedAnswer = nil
                    scoreAnimated = false
                    viewModel.retryQuiz(level)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scoreAnimated = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text(L("try_again"))
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(passed ? theme.textPrimary : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                            .fill(passed
                                ? AnyShapeStyle(theme.cardBackground)
                                : AnyShapeStyle(LinearGradient(colors: level.gradientColors, startPoint: .leading, endPoint: .trailing)))
                            .shadow(color: theme.shadow, radius: 6)
                    )
                }

                Button {
                    dismiss()
                } label: {
                    Text(L("back_to_levels"))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                scoreAnimated = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        QuizSessionView(level: ChordCurriculum.levels[0])
    }
}
