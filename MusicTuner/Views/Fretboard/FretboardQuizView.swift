//
//  FretboardQuizView.swift
//  MusicTuner
//
//  Quiz phase for Fretboard Training
//  Microphone listens for correct note, auto-detects match
//  Matches QuizSessionView pattern
//

import SwiftUI

struct FretboardQuizView: View {
    let level: FretboardLevel
    let instrument: Instrument
    
    @StateObject private var viewModel = ExerciseViewModel()
    @ObservedObject var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @AppStorage("handsFreeModeEnabled") private var handsFreeModeEnabled: Bool = false
    
    var body: some View {
        ZStack {
            Color(hex: "131313").ignoresSafeArea()

            if viewModel.showSuccess {
                LearningPath.acid.opacity(0.12)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            VStack(spacing: 0) {
                switch viewModel.state {
                case .idle:
                    loadingView
                case .quizzing(_, _, let question):
                    quizContent(question: question)
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
        .animation(.easeInOut(duration: 0.3), value: viewModel.showSuccess)
        .onAppear {
            viewModel.selectInstrument(instrument)
            Task {
                await viewModel.startQuiz(for: level)
            }
        }
        .onDisappear {
            viewModel.stopExercise()
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

    private func quizContent(question: ExerciseQuestion) -> some View {
        let progress = viewModel.totalQuestions > 0 ? CGFloat(viewModel.questionNumber - 1) / CGFloat(viewModel.totalQuestions) : 0

        return VStack(spacing: 20) {
            QuizTopBar(progress: progress) {
                viewModel.stopExercise()
                dismiss()
            }

            Spacer()

            // Question Card
            questionCard(question: question)

            // Detected Note Display
            detectedNoteDisplay

            // Skip Button
            skipButton

            Spacer()

            // Error
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Spacer().frame(height: 20)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Question Card
    
    private func questionCard(question: ExerciseQuestion) -> some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                Text(L("play_this_note"))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "C8C8AB"))

                if handsFreeModeEnabled {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(LearningPath.acid)
                }
            }

            // Note Circle
            ZStack {
                Circle()
                    .fill(viewModel.isCorrect ?
                          LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [LearningPath.acid, LearningPath.acidDim], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 140, height: 140)
                    .shadow(color: viewModel.isCorrect ? .green.opacity(0.4) : LearningPath.acid.opacity(0.4), radius: 16)

                VStack(spacing: 4) {
                    Text(question.noteName)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "303300"))

                    Text("\(question.noteOctave)")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "303300").opacity(0.8))
                }
            }

            // String & Fret
            VStack(spacing: 4) {
                Text(question.promptText)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "E2E2E2"))

                if !handsFreeModeEnabled {
                    Text(L("fret") + " \(question.fret)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "C8C8AB"))
                }
            }

            // Correct Feedback
            if viewModel.isCorrect {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                    Text(L("correct"))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.green)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: ThemeManager.radiusLarge)
                .fill(Color(hex: "1F1F1F"))
                .overlay(
                    RoundedRectangle(cornerRadius: ThemeManager.radiusLarge)
                        .stroke(
                            viewModel.isCorrect ? Color.green.opacity(0.5) :
                            viewModel.isMatchingTarget ? Color.orange.opacity(0.5) : Color.clear,
                            lineWidth: 3
                        )
                )
        )
        .padding(.horizontal, 20)
        .animation(.spring(response: 0.3), value: viewModel.isCorrect)
    }

    // MARK: - Detected Note Display

    private var detectedNoteDisplay: some View {
        Group {
            if let note = viewModel.detectedNote {
                VStack(spacing: 8) {
                    Text(L("you_are_playing"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "C8C8AB"))

                    Text(NoteFormatter.format(note.displayName))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(viewModel.isMatchingTarget ? LearningPath.acid : Color(hex: "E2E2E2"))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                        .fill(Color(hex: "1F1F1F"))
                )
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "waveform")
                        .font(.system(size: 28))
                        .foregroundStyle(Color(hex: "929277"))
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                    Text(L("listening"))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "C8C8AB"))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                        .fill(Color(hex: "1F1F1F"))
                )
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Skip Button

    private var skipButton: some View {
        Button {
            viewModel.skipQuestion()
        } label: {
            Text(L("skip"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "C8C8AB"))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color(hex: "1F1F1F"))
                )
        }
    }
    
    // MARK: - Results View
    
    private func resultsView(score: Int, total: Int, passed: Bool) -> some View {
        let nextLevel = FretboardCurriculum.nextLevel(after: level)
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
                // Next Level Button (only shown when passed)
                if passed, !isLastLevel {
                    Button {
                        dismiss()
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
                                .fill(LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing))
                                .shadow(color: .green.opacity(0.3), radius: 10)
                        )
                    }
                }
                
                // Try Again
                Button {
                    Task {
                        await viewModel.startQuiz(for: level)
                    }
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
                
                // Back to Levels
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
        FretboardQuizView(level: FretboardCurriculum.levels[0], instrument: .guitar)
    }
}
