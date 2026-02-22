//
//  EarTrainingLevelSelectView.swift
//  MusicTuner
//
//  Level selection for Ear Training
//  Shows 8 levels with lock/unlock states - matches ChordMastery LevelSelectView
//

import SwiftUI

struct EarTrainingLevelSelectView: View {
    @StateObject private var viewModel = EarTrainingViewModel()
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var storeManager = StoreKitManager.shared
    
    /// Levels with id >= this value require premium
    private let premiumThreshold = 8
    
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
        .navigationTitle(L("ear_training"))
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
                    .fill(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                    .shadow(color: .purple.opacity(0.3), radius: 12, x: 0, y: 6)
                
                Image(systemName: "ear.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }
            
            Text(L("et_title"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
            
            Text(L("et_subtitle"))
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
            ForEach(EarTrainingCurriculum.levels) { level in
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
        let isPremiumLevel = level.id >= premiumThreshold
        let canAccess = isUnlocked && (!isPremiumLevel || storeManager.isPremium)
        
        if canAccess {
            NavigationLink(destination: EarTrainingLearningView(level: level)) {
                levelCardContent(level: level, isUnlocked: true, isCompleted: isCompleted, isPremiumLocked: false)
            }
        } else {
            levelCardContent(level: level, isUnlocked: isUnlocked, isCompleted: false, isPremiumLocked: isPremiumLevel && !storeManager.isPremium && isUnlocked)
        }
    }
    
    private func levelCardContent(level: LevelDefinition, isUnlocked: Bool, isCompleted: Bool, isPremiumLocked: Bool = false) -> some View {
        HStack(spacing: 16) {
            // Level Icon
            ZStack {
                Circle()
                    .fill(isUnlocked && !isPremiumLocked ?
                          LinearGradient(colors: level.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing) :
                          isPremiumLocked ?
                          LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [Color.gray.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 56, height: 56)
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white)
                } else if isPremiumLocked {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 24, weight: .bold))
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
                    .foregroundStyle(isUnlocked && !isPremiumLocked ? theme.textPrimary : theme.textSecondary)
                
                Text(level.localizedSubtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(2)
                
                if isPremiumLocked {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                        Text("Premium")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.orange)
                    .padding(.top, 2)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 10))
                        Text("\(level.chordIdentifiers.count) chords")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(theme.textSecondary.opacity(0.8))
                    .padding(.top, 2)
                }
            }
            
            Spacer()
            
            if isPremiumLocked {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.orange)
            } else if isUnlocked {
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
        .opacity(isUnlocked && !isPremiumLocked ? 1.0 : 0.7)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EarTrainingLevelSelectView()
    }
}
