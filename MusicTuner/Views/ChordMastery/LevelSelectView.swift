//
//  LevelSelectView.swift
//  MusicTuner
//
//  Level selection grid for Chord Mastery
//  Shows 4 levels with lock/unlock states
//

import SwiftUI

struct LevelSelectView: View {
    @StateObject private var viewModel = ChordMasteryViewModel()
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Level Cards
                        levelGrid
                    }
                    .padding(.vertical, 20)
                }
                
                // Banner Ad
                AdBannerContainer()
            }
        }
        .navigationTitle(L("learn_chord_diagrams"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.background, for: .navigationBar)
        .onAppear {
            viewModel.loadProgress()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                    .shadow(color: .cyan.opacity(0.3), radius: 12, x: 0, y: 6)
                
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }
            
            Text(L("chord_mastery_title"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
            
            Text(L("chord_mastery_subtitle"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 10)
    }
    
    // MARK: - Level Grid
    
    private var levelGrid: some View {
        VStack(spacing: 16) {
            ForEach(ChordCurriculum.levels) { level in
                levelCard(for: level)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Level Card
    
    @ViewBuilder
    private func levelCard(for level: LevelDefinition) -> some View {
        let isUnlocked = viewModel.isLevelUnlocked(level)
        let isCompleted = viewModel.isLevelCompleted(level)
        
        if isUnlocked {
            NavigationLink(destination: LearningSessionView(level: level)) {
                levelCardContent(level: level, isUnlocked: true, isCompleted: isCompleted)
            }
        } else {
            levelCardContent(level: level, isUnlocked: false, isCompleted: false)
        }
    }
    
    private func levelCardContent(level: LevelDefinition, isUnlocked: Bool, isCompleted: Bool) -> some View {
        HStack(spacing: 16) {
            // Level Icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? 
                          LinearGradient(colors: level.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [Color.gray.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 56, height: 56)
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white)
                } else if isUnlocked {
                    Image(systemName: level.icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            
            // Title & Subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(level.localizedTitle)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(isUnlocked ? theme.textPrimary : theme.textSecondary)
                
                Text(level.localizedSubtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(2)
                
                // Chord count
                HStack(spacing: 4) {
                    Image(systemName: "music.note")
                        .font(.system(size: 10))
                    Text("\(level.chordIdentifiers.count) chords")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundStyle(theme.textSecondary.opacity(0.8))
                .padding(.top, 2)
            }
            
            Spacer()
            
            // Arrow or Lock
            if isUnlocked {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                .fill(theme.cardBackground)
                .shadow(color: theme.shadow, radius: 8, x: 0, y: 4)
        )
        .opacity(isUnlocked ? 1.0 : 0.7)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LevelSelectView()
    }
}
