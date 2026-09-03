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
            Color(hex: "131313").ignoresSafeArea()

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
        .environment(\.colorScheme, .dark)
        .navigationTitle(level.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex: "131313"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $showQuiz) {
            QuizSessionView(level: level)
        }
        .onAppear {
            viewModel.startLevel(level)
            // Initialize audio and play first chord only after engine is ready
            Task {
                await ChordEngine.shared.initialize()
                guard ChordEngine.shared.isInitialized else { return }
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
                        .fill(index <= currentPage ? LearningPath.acid : Color(hex: "353534"))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Counter
            Text("\(currentPage + 1) / \(level.chords.count)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "C8C8AB"))
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
                        .foregroundStyle(Color(hex: "C8C8AB"))

                    // Chord Diagram
                    ChordDiagramView(chord: chord) {
                        ChordEngine.shared.playChord(chord)
                    }
                    .frame(height: 380)
                    .padding(.horizontal, 20)

                    // Tap to play hint
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap.fill")
                        Text(L("tap_to_play"))
                    }
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "C8C8AB").opacity(0.7))
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
                .foregroundStyle(currentPage > 0 ? Color(hex: "E2E2E2") : Color(hex: "929277").opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                        .fill(Color(hex: "1F1F1F"))
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
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "303300"))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                        .fill(LearningPath.acid)
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
