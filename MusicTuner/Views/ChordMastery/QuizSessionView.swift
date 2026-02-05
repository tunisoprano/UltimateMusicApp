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
        .onAppear {
            // Start quiz for this level
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.startLevel(level)
                // Skip to quiz
                for _ in 0..<level.chords.count {
                    viewModel.nextChord()
                }
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
        
        return Button {
            selectedAnswer = chord
            viewModel.submitAnswer(chord)
        } label: {
            Text(chord.name)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(buttonTextColor(isSelected: isSelected, isCorrect: isCorrectAnswer, showFeedback: showFeedback))
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(
                    RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                        .fill(buttonBackground(isSelected: isSelected, isCorrect: isCorrectAnswer, showFeedback: showFeedback))
                        .shadow(color: theme.shadow, radius: 6)
                )
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
            
            // Action Buttons - Always show all 3
            VStack(spacing: 12) {
                // 1. Next Level Button (locked if not passed or last level)
                if !isLastLevel {
                    Button {
                        if passed, let next = nextLevel {
                            // Navigate to next level - dismiss and let user select
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if !passed {
                                Image(systemName: "lock.fill")
                            }
                            Text(L("next_level"))
                            if passed {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(passed ? .white : theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                                .fill(passed ? 
                                      LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing) :
                                      LinearGradient(colors: [theme.cardBackground], startPoint: .leading, endPoint: .trailing))
                                .shadow(color: passed ? .green.opacity(0.3) : .clear, radius: 10)
                        )
                    }
                    .disabled(!passed)
                    .opacity(passed ? 1.0 : 0.6)
                }
                
                // 2. Try Again Button
                Button {
                    // Retry quiz
                    viewModel.startLevel(level)
                    for _ in 0..<level.chords.count {
                        viewModel.nextChord()
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
        QuizSessionView(level: ChordCurriculum.levels[0])
    }
}
