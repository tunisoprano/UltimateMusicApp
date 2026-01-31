//
//  EarTrainingView.swift
//  MusicTuner
//
//  Gamified ear training with chord recognition and intro flow
//

import SwiftUI

struct EarTrainingView: View {
    @StateObject private var viewModel = EarTrainingViewModel()
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Content based on game state
                        switch viewModel.gameState {
                        case .selectingLevel:
                            levelSelector
                            modeSelector
                            
                            if viewModel.currentMode == .learn {
                                learnModeView
                            } else {
                                quizStartView
                            }
                            
                        case .learningIntro:
                            learningIntroView
                            
                        case .quizzing:
                            quizView
                            
                        case .summary:
                            // Handled by sheet
                            EmptyView()
                        }
                    }
                    .padding(.vertical, 20)
                }
                
                // Banner Ad
                AdBannerContainer()
            }
        }
        .navigationTitle(String(localized: "ear_training"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.background, for: .navigationBar)
        .toolbar {
            if viewModel.gameState != .selectingLevel {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.backToLevelSelection()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.textSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showResult) {
            resultSheet
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
    
    // MARK: - Level Selector
    
    private var levelSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(EarTrainingLevel.allLevels) { level in
                    LevelCard(
                        level: level,
                        isSelected: viewModel.selectedLevel.id == level.id,
                        isUnlocked: viewModel.isLevelUnlocked(level),
                        theme: theme
                    ) {
                        if viewModel.isLevelUnlocked(level) {
                            viewModel.selectLevel(level)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Mode Selector
    
    private var modeSelector: some View {
        HStack(spacing: 0) {
            ForEach(EarTrainingMode.allCases, id: \.rawValue) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.currentMode = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(viewModel.currentMode == mode ? .white : theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(viewModel.currentMode == mode ? theme.accent : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.cardBackground)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Learn Mode
    
    private var learnModeView: some View {
        VStack(spacing: 20) {
            Text("Tap a chord to hear it")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textSecondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(viewModel.availableChords) { chord in
                    ChordButton(
                        chord: chord,
                        isPlaying: viewModel.currentChord == chord,
                        theme: theme
                    ) {
                        viewModel.playChord(chord)
                    }
                }
            }
        }
        .padding(20)
        .themeCard()
        .padding(.horizontal, 20)
    }
    
    // MARK: - Quiz Start View
    
    private var quizStartView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(theme.accent.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "ear.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(theme.accent)
            }
            
            VStack(spacing: 8) {
                Text("Ready for the Quiz?")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
                
                Text("First, listen to each chord, then test yourself")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 6) {
                Text("⏱ 30 seconds")
                Text("🎯 \(Int(viewModel.selectedLevel.requiredAccuracy * 100))% to pass")
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(theme.textSecondary)
            
            Button {
                viewModel.startLearningIntro()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                    Text(String(localized: "start"))
                }
            }
            .buttonStyle(ThemeButtonStyle())
            .padding(.horizontal, 40)
        }
        .padding(32)
        .themeCard()
        .padding(.horizontal, 20)
    }
    
    // MARK: - Learning Intro View (NEW - Yousician Style)
    
    private var learningIntroView: some View {
        VStack(spacing: 32) {
            // Progress indicator
            Text(viewModel.introProgress)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textSecondary)
            
            // Large speaker icon with animation
            ZStack {
                Circle()
                    .fill(theme.accent.opacity(0.15))
                    .frame(width: 140, height: 140)
                
                Circle()
                    .fill(theme.accent.opacity(0.1))
                    .frame(width: 180, height: 180)
                
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(theme.accent)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
            }
            
            // Chord name
            if let chord = viewModel.currentIntroChord {
                VStack(spacing: 8) {
                    Text(chord.name)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                    
                    Text(chord.displayName)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                }
            }
            
            // Replay button
            Button {
                viewModel.replayIntroChord()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.counterclockwise")
                    Text(String(localized: "listen"))
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.accent)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                        .stroke(theme.accent, lineWidth: 2)
                )
            }
            
            Spacer().frame(height: 20)
            
            // Next / Start Quiz button
            if viewModel.isLastIntroChord {
                Button {
                    viewModel.finishIntroAndStartQuiz()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                        Text(String(localized: "start_quiz"))
                    }
                }
                .buttonStyle(ThemeButtonStyle())
                .padding(.horizontal, 40)
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.nextIntroChord()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(String(localized: "next"))
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(ThemeButtonStyle())
                .padding(.horizontal, 40)
            }
        }
        .padding(32)
        .themeCard()
        .padding(.horizontal, 20)
    }
    
    // MARK: - Quiz View
    
    private var quizView: some View {
        VStack(spacing: 24) {
            // Timer & Score
            HStack {
                // Timer
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .foregroundStyle(viewModel.timeRemaining <= 10 ? theme.error : theme.accent)
                    Text("\(viewModel.timeRemaining)s")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(viewModel.timeRemaining <= 10 ? theme.error : theme.textPrimary)
                        .contentTransition(.numericText())
                }
                
                Spacer()
                
                // Score
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(localized: "score_format", defaultValue: "Score: \(viewModel.score)"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                    Text("\(viewModel.accuracyPercentage)%")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            
            // Replay Button
            Button {
                viewModel.replayCurrentChord()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 24))
                    Text("Play Again")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                        .fill(theme.accentGradient)
                )
            }
            .padding(.horizontal, 20)
            
            // Answer Buttons
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(viewModel.availableChords) { chord in
                    AnswerButton(
                        chord: chord,
                        lastAnswerCorrect: viewModel.lastAnswerCorrect,
                        isCurrentAnswer: viewModel.currentChord == chord,
                        theme: theme
                    ) {
                        viewModel.submitAnswer(chord)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .themeCard()
        .padding(.horizontal, 20)
    }
    
    // MARK: - Result Sheet
    
    private var resultSheet: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if let result = viewModel.quizResult {
                // Icon
                ZStack {
                    Circle()
                        .fill((result.passed ? theme.success : theme.error).opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(result.passed ? theme.success : theme.error)
                }
                
                // Title
                Text(result.passed ? "Great Job!" : "Keep Practicing!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
                
                // Stats
                VStack(spacing: 12) {
                    HStack {
                        Text("Correct")
                        Spacer()
                        Text("\(result.correctAnswers) / \(result.totalQuestions)")
                    }
                    HStack {
                        Text("Accuracy")
                        Spacer()
                        Text("\(Int(result.accuracy * 100))%")
                            .foregroundStyle(result.passed ? theme.success : theme.error)
                    }
                }
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textPrimary)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                        .fill(theme.cardBackground)
                )
                
                // Unlock Message
                if result.unlockedNextLevel {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.open.fill")
                        Text("Level \(viewModel.unlockedLevel) Unlocked!")
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.success)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                            .fill(theme.success.opacity(0.15))
                    )
                }
            }
            
            Spacer()
            
            Button {
                viewModel.dismissResult()
            } label: {
                Text("Continue")
            }
            .buttonStyle(ThemeButtonStyle())
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .padding(20)
        .background(theme.backgroundGradient.ignoresSafeArea())
    }
}

// MARK: - Level Card

struct LevelCard: View {
    let level: EarTrainingLevel
    let isSelected: Bool
    let isUnlocked: Bool
    let theme: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if isUnlocked {
                    Text("\(level.id)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                }
                
                Text(level.name)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isSelected ? .white : (isUnlocked ? theme.textPrimary : theme.inactive))
            .frame(width: 80, height: 70)
            .background(
                RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                    .fill(isSelected ? theme.accentGradient : LinearGradient(colors: [theme.cardBackground], startPoint: .top, endPoint: .bottom))
                    .shadow(color: isSelected ? theme.accent.opacity(0.3) : theme.shadow, radius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                    .stroke(isUnlocked ? Color.clear : theme.inactive.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(!isUnlocked)
    }
}

// MARK: - Chord Button

struct ChordButton: View {
    let chord: ChordDefinition
    let isPlaying: Bool
    let theme: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(chord.name)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text(chord.displayName)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundStyle(isPlaying ? .white : theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(
                RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                    .fill(isPlaying ? theme.accentGradient : LinearGradient(colors: [theme.cardBackground], startPoint: .top, endPoint: .bottom))
            )
            .scaleEffect(isPlaying ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isPlaying)
        }
    }
}

// MARK: - Answer Button

struct AnswerButton: View {
    let chord: ChordDefinition
    let lastAnswerCorrect: Bool?
    let isCurrentAnswer: Bool
    let theme: ThemeManager
    let action: () -> Void
    
    private var buttonColor: Color {
        guard let correct = lastAnswerCorrect, isCurrentAnswer else {
            return theme.cardBackground
        }
        return correct ? theme.success : theme.error
    }
    
    var body: some View {
        Button(action: action) {
            Text(chord.name)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(lastAnswerCorrect != nil && isCurrentAnswer ? .white : theme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(
                    RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                        .fill(buttonColor)
                        .shadow(color: theme.shadow, radius: 6)
                )
        }
    }
}

#Preview {
    NavigationStack {
        EarTrainingView()
    }
}
