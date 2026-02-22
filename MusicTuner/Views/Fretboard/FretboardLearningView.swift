//
//  FretboardLearningView.swift
//  MusicTuner
//
//  Teaching phase for Fretboard Training
//  Shows notes to learn before quiz
//

import SwiftUI

struct FretboardLearningView: View {
    let level: FretboardLevel
    let instrument: Instrument
    
    @StateObject private var viewModel = ExerciseViewModel()
    @ObservedObject var theme = ThemeManager.shared
    @State private var currentPage: Int = 0
    @State private var showQuiz: Bool = false
    
    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Header
                progressHeader
                
                // Note TabView
                noteTabView
                
                // Navigation Buttons
                navigationButtons
                
                Spacer().frame(height: 20)
            }
        }
        .navigationTitle(level.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.background, for: .navigationBar)
        .navigationDestination(isPresented: $showQuiz) {
            FretboardQuizView(level: level, instrument: instrument)
        }
        .onAppear {
            viewModel.selectInstrument(instrument)
            viewModel.startLevel(level)
        }
    }
    
    private var teachingNotes: [ExerciseQuestion] {
        let strings = instrument.strings
        var notes: [ExerciseQuestion] = []
        let frets = Set([level.fretRange.lowerBound, level.fretRange.upperBound])
        for string in strings {
            for fret in frets.sorted() {
                notes.append(ExerciseQuestion(instrumentString: string, fret: fret))
            }
        }
        return notes
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(0..<teachingNotes.count, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentPage ?
                              LinearGradient(colors: level.gradientColors, startPoint: .leading, endPoint: .trailing) :
                              LinearGradient(colors: [theme.cardBackground], startPoint: .leading, endPoint: .trailing))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Text("\(currentPage + 1) / \(teachingNotes.count)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textSecondary)
        }
    }
    
    // MARK: - Note TabView
    
    private var noteTabView: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(teachingNotes.enumerated()), id: \.offset) { index, note in
                VStack(spacing: 24) {
                    // Instruction
                    Text(L("study_this_note"))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                    
                    Spacer()
                    
                    // Note Display
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: level.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 160, height: 160)
                            .shadow(color: level.gradientColors[0].opacity(0.3), radius: 16)
                        
                        VStack(spacing: 4) {
                            Text(note.noteName)
                                .font(.system(size: 60, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Text("\(note.noteOctave)")
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    
                    // String & Fret Info
                    VStack(spacing: 8) {
                        Text("\(note.instrumentString.name) " + L("string"))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.textPrimary)
                        
                        Text(L("fret") + " \(note.fret)")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(theme.textSecondary)
                        
                        // Frequency
                        Text(String(format: "%.1f Hz", note.targetFrequency))
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(theme.textSecondary.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
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
                    if currentPage < teachingNotes.count - 1 {
                        currentPage += 1
                    } else {
                        showQuiz = true
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentPage < teachingNotes.count - 1 ?
                         L("next") :
                         L("start_quiz"))
                    Image(systemName: currentPage < teachingNotes.count - 1 ? "chevron.right" : "play.fill")
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
        FretboardLearningView(level: FretboardCurriculum.levels[0], instrument: .guitar)
    }
}
