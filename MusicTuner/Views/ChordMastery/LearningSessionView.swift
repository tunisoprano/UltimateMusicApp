//
//  LearningSessionView.swift
//  MusicTuner
//
//  Teaching phase for Chord Mastery
//  PageTabView with ChordDiagramView, auto-plays chords
//

import SwiftUI

struct LearningSessionView: View {
    let level: LevelDefinition
    
    @StateObject private var viewModel = ChordMasteryViewModel()
    @ObservedObject var theme = ThemeManager.shared
    @State private var currentPage: Int = 0
    @State private var showQuiz: Bool = false
    
    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Header
                progressHeader
                
                // Chord TabView
                chordTabView
                
                // Navigation Buttons
                navigationButtons
                
                Spacer().frame(height: 20)
            }
        }
        .navigationTitle(level.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.background, for: .navigationBar)
        .navigationDestination(isPresented: $showQuiz) {
            QuizSessionView(level: level)
        }
        .onAppear {
            viewModel.startLevel(level)
            // Initialize audio and play first chord
            Task {
                await ChordEngine.shared.initialize()
                // Play first chord after a short delay
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                if level.chords.indices.contains(0) {
                    ChordEngine.shared.playChord(level.chords[0])
                }
            }
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: 8) {
            // Progress Indicator
            HStack(spacing: 8) {
                ForEach(0..<level.chords.count, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentPage ? 
                              LinearGradient(colors: level.gradientColors, startPoint: .leading, endPoint: .trailing) :
                              LinearGradient(colors: [theme.cardBackground], startPoint: .leading, endPoint: .trailing))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Counter
            Text("\(currentPage + 1) / \(level.chords.count)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textSecondary)
        }
    }
    
    // MARK: - Chord TabView
    
    private var chordTabView: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(level.chords.enumerated()), id: \.offset) { index, chord in
                VStack(spacing: 16) {
                    // Study instruction
                    Text(L("study_this_chord"))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                    
                    // Chord Diagram
                    ChordDiagramView(chord: chord) {
                        ChordEngine.shared.playChord(chord)
                    }
                    .frame(height: 380)
                    .padding(.horizontal, 20)
                    .shadow(color: theme.shadow, radius: 10, y: 5)
                    
                    // Tap to play hint
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap.fill")
                        Text(L("tap_to_play"))
                    }
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textSecondary.opacity(0.7))
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onChange(of: currentPage) { oldValue, newValue in
            // Play chord when page changes
            if level.chords.indices.contains(newValue) {
                ChordEngine.shared.playChord(level.chords[newValue])
            }
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Previous Button
            Button {
                withAnimation {
                    if currentPage > 0 {
                        currentPage -= 1
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text(L("previous"))
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(currentPage > 0 ? theme.textPrimary : theme.textSecondary.opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                        .fill(theme.cardBackground)
                )
            }
            .disabled(currentPage == 0)
            
            // Next / Start Quiz Button
            Button {
                withAnimation {
                    if currentPage < level.chords.count - 1 {
                        currentPage += 1
                    } else {
                        // Last chord - start quiz
                        showQuiz = true
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentPage < level.chords.count - 1 ? 
                         L("next") : 
                         L("start_quiz"))
                    Image(systemName: currentPage < level.chords.count - 1 ? "chevron.right" : "play.fill")
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                        .fill(LinearGradient(colors: level.gradientColors, startPoint: .leading, endPoint: .trailing))
                        .shadow(color: level.gradientColors[0].opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LearningSessionView(level: ChordCurriculum.levels[0])
    }
}
