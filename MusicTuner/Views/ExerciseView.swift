//
//  ExerciseView.swift
//  MusicTuner
//
//  Level selection for Fretboard Training
//  Instrument picker at top, then level cards
//  Matches LevelSelectView pattern
//

import SwiftUI

/// Fretboard Training level selection
struct ExerciseView: View {
    @StateObject private var viewModel = ExerciseViewModel()
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
                        
                        // Instrument Picker
                        instrumentPicker
                        
                        // Level Cards
                        levelGrid
                    }
                    .padding(.vertical, 20)
                }
                
                // Banner Ad
                AdBannerContainer()
            }
        }
        .navigationTitle(L("fretboard"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.background, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                streakBadge
            }
        }
        .onAppear {
            viewModel.loadProgress()
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
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                    .shadow(color: .green.opacity(0.3), radius: 12, x: 0, y: 6)
                
                Image(systemName: "guitars.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }
            
            Text(L("fb_title"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
            
            Text(L("fb_subtitle"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 10)
    }
    
    // MARK: - Instrument Picker
    
    private var instrumentPicker: some View {
        VStack(spacing: 12) {
            Text(L("instrument"))
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
        .background(
            RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                .fill(theme.cardBackground)
                .shadow(color: theme.shadow, radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Level Grid
    
    private var levelGrid: some View {
        VStack(spacing: 16) {
            ForEach(FretboardCurriculum.levels) { level in
                levelCard(for: level)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Level Card
    
    @ViewBuilder
    private func levelCard(for level: FretboardLevel) -> some View {
        let isUnlocked = viewModel.isLevelUnlocked(level)
        let isCompleted = viewModel.isLevelCompleted(level)
        let isPremiumLevel = level.id >= premiumThreshold
        let canAccess = isUnlocked && (!isPremiumLevel || storeManager.isPremium)
        
        if canAccess {
            NavigationLink(destination: FretboardLearningView(level: level, instrument: viewModel.selectedInstrument)) {
                levelCardContent(level: level, isUnlocked: true, isCompleted: isCompleted, isPremiumLocked: false)
            }
        } else {
            levelCardContent(level: level, isUnlocked: isUnlocked, isCompleted: false, isPremiumLocked: isPremiumLevel && !storeManager.isPremium && isUnlocked)
        }
    }
    
    private func levelCardContent(level: FretboardLevel, isUnlocked: Bool, isCompleted: Bool, isPremiumLocked: Bool = false) -> some View {
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
                        Image(systemName: "music.note")
                            .font(.system(size: 10))
                        Text(L("frets") + " \(level.fretRange.lowerBound)-\(level.fretRange.upperBound)")
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
        ExerciseView()
    }
}
