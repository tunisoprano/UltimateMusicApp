//
//  ExerciseView.swift
//  MusicTuner
//
//  Exercise view with Daily Streak display
//

import SwiftUI

/// Gamified fretboard exercise view with streak tracking
struct ExerciseView: View {
    @StateObject private var viewModel = ExerciseViewModel()
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            
            if viewModel.showSuccess {
                theme.success.opacity(0.2)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    instrumentPicker
                    levelSelector
                    
                    if viewModel.isListening {
                        activeExerciseView
                    } else {
                        startPromptView
                    }
                    
                    actionButton
                    errorView
                }
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.background, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                streakBadge
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showSuccess)
        .onDisappear {
            viewModel.stopExercise()
        }
    }
    
    // MARK: - Streak Badge
    
    private var streakBadge: some View {
        HStack(spacing: 4) {
            Text("🔥")
            Text("\(viewModel.streakCount)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(theme.warning)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(theme.cardBackground)
                .shadow(color: theme.shadow, radius: 4)
        )
    }
    
    // MARK: - Subviews
    
    private var instrumentPicker: some View {
        VStack(spacing: 12) {
            Text("Instrument")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textSecondary)
            
            Picker("Instrument", selection: $viewModel.selectedInstrument) {
                ForEach(Instrument.exerciseInstruments) { instrument in
                    Text(instrument.rawValue).tag(instrument)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.selectedInstrument) { _, newValue in
                viewModel.selectInstrument(newValue)
            }
        }
        .padding(20)
        .themeCard()
        .padding(.horizontal, 20)
    }
    
    private var levelSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ExerciseLevel.allCases) { level in
                    LevelButton(
                        level: level,
                        isSelected: viewModel.selectedLevel == level,
                        theme: theme
                    ) {
                        viewModel.selectLevel(level)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var activeExerciseView: some View {
        VStack(spacing: 24) {
            scoreDisplay
            
            if let question = viewModel.currentQuestion {
                QuestionCard(
                    question: question,
                    isCorrect: viewModel.isCorrect,
                    isMatching: viewModel.isMatchingTarget,
                    theme: theme
                )
            }
            
            detectedNoteDisplay
            skipButton
        }
        .padding(.horizontal, 20)
    }
    
    private var scoreDisplay: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Score")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                Text("\(viewModel.score) / \(viewModel.totalQuestions)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
            }
            
            Spacer()
            
            if viewModel.totalQuestions > 0 {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Accuracy")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                    
                    let pct = viewModel.progressPercentage
                    Text(String(format: "%.0f%%", pct))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.success)
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var detectedNoteDisplay: some View {
        Group {
            if let note = viewModel.detectedNote {
                VStack(spacing: 8) {
                    Text("You're playing")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                    
                    Text(NoteFormatter.format(note.displayName))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(viewModel.isMatchingTarget ? theme.success : theme.textPrimary)
                }
                .padding(20)
                .themeCard()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "waveform")
                        .font(.system(size: 32))
                        .foregroundStyle(theme.inactive)
                    Text("Listening...")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                }
                .padding(20)
                .themeCard()
            }
        }
    }
    
    private var skipButton: some View {
        Button {
            viewModel.skipQuestion()
        } label: {
            Text("Skip this one")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textSecondary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(theme.cardBackground)
                        .shadow(color: theme.shadow, radius: 6, x: 0, y: 3)
                )
        }
    }
    
    private var startPromptView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(theme.success.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(theme.success)
            }
            
            VStack(spacing: 8) {
                Text("Fretboard Training")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
                
                Text("Play the notes shown on screen!")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .themeCard()
        .padding(.horizontal, 20)
    }
    
    private var actionButton: some View {
        Button {
            Task {
                if viewModel.isListening {
                    viewModel.stopExercise()
                } else {
                    await viewModel.startExercise()
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: viewModel.isListening ? "stop.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text(viewModel.isListening ? "Stop Practice" : "Start Practice")
            }
        }
        .buttonStyle(ThemeButtonStyle(isPrimary: !viewModel.isListening))
        .padding(.horizontal, 20)
    }
    
    private var errorView: some View {
        Group {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(theme.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}

// MARK: - Level Button

struct LevelButton: View {
    let level: ExerciseLevel
    let isSelected: Bool
    let theme: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(level.icon)
                    .font(.system(size: 24))
                Text(level.rawValue)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isSelected ? .white : theme.textSecondary)
            .frame(width: 85, height: 70)
            .background(
                RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                    .fill(isSelected ? theme.successGradient : LinearGradient(colors: [theme.cardBackground], startPoint: .top, endPoint: .bottom))
                    .shadow(color: isSelected ? theme.success.opacity(0.3) : theme.shadow, radius: 8, x: 0, y: 4)
            )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Question Card

struct QuestionCard: View {
    let question: ExerciseQuestion
    let isCorrect: Bool
    let isMatching: Bool
    let theme: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Play this note")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textSecondary)
            
            Text(question.promptText)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
                .multilineTextAlignment(.center)
            
            if isCorrect {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                    Text("Perfect!")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .foregroundStyle(theme.success)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: ThemeManager.radiusLarge)
                .fill(theme.cardBackground)
                .shadow(color: isCorrect ? theme.success.opacity(0.3) : theme.shadow, radius: 12, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: ThemeManager.radiusLarge)
                        .stroke(
                            isCorrect ? theme.success.opacity(0.5) :
                            isMatching ? theme.warning.opacity(0.5) : Color.clear,
                            lineWidth: 3
                        )
                )
        )
        .animation(.spring(response: 0.3), value: isCorrect)
    }
}

#Preview {
    NavigationStack {
        ExerciseView()
    }
}
