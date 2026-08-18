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
    @ObservedObject var storeManager = StoreKitManager.shared
    
    /// Dynamic premium threshold — last 2 levels require premium
    private var premiumThreshold: Int { ChordCurriculum.premiumThreshold }

    @State private var showPaywall = false
    @State private var showAllLevels = false

    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Overall progress
                        progressSummary

                        // Current level hero card
                        currentLevelSection

                        // Expandable full level list
                        showAllLevelsToggle

                        if showAllLevels {
                            levelGrid
                        }
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
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
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
    
    // MARK: - Progress Summary

    private var completedCount: Int {
        ChordCurriculum.levels.filter { viewModel.isLevelCompleted($0) }.count
    }

    private var progressSummary: some View {
        VStack(spacing: 8) {
            HStack {
                Text(String(format: L("levels_completed_format"), completedCount, ChordCurriculum.totalLevels))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                Spacer()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.inactive.opacity(0.3))
                    Capsule()
                        .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(completedCount) / CGFloat(max(ChordCurriculum.totalLevels, 1)))
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Current Level

    /// First unlocked-but-uncompleted level; falls back to the last level when everything is done
    private var currentLevel: LevelDefinition? {
        ChordCurriculum.levels.first { viewModel.isLevelUnlocked($0) && !viewModel.isLevelCompleted($0) }
            ?? ChordCurriculum.levels.last
    }

    @ViewBuilder
    private var currentLevelSection: some View {
        if let level = currentLevel {
            let isCompleted = viewModel.isLevelCompleted(level)
            let isPremiumLocked = level.id >= premiumThreshold && !storeManager.isPremium

            VStack(alignment: .leading, spacing: 10) {
                Text(L("current_level_label").uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                    .tracking(1.2)

                if isPremiumLocked {
                    Button {
                        showPaywall = true
                    } label: {
                        currentLevelHero(level: level, isCompleted: isCompleted, isPremiumLocked: true)
                    }
                } else {
                    NavigationLink(destination: LearningSessionView(level: level)) {
                        currentLevelHero(level: level, isCompleted: isCompleted, isPremiumLocked: false)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func currentLevelHero(level: LevelDefinition, isCompleted: Bool, isPremiumLocked: Bool) -> some View {
        let heroGradient = isPremiumLocked
            ? LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
            : LinearGradient(colors: level.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)

        return VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(heroGradient)
                        .frame(width: 64, height: 64)
                        .shadow(color: (isPremiumLocked ? Color.orange : level.gradientColors[0]).opacity(0.35), radius: 10, x: 0, y: 5)

                    Image(systemName: isPremiumLocked ? "crown.fill" : level.icon)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(level.localizedTitle)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textPrimary)

                    Text(level.localizedSubtitle)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 4) {
                        Image(systemName: "music.note").font(.system(size: 9))
                        Text("\(level.chordIdentifiers.count) chords")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(theme.textSecondary.opacity(0.7))
                    .padding(.top, 2)
                }

                Spacer()
            }

            HStack(spacing: 6) {
                if isPremiumLocked {
                    Image(systemName: "crown.fill").font(.system(size: 14))
                    Text("Premium")
                } else {
                    Text(isCompleted ? L("replay_level") : L("continue_level"))
                    Image(systemName: "arrow.right").font(.system(size: 14, weight: .bold))
                }
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(Capsule().fill(heroGradient))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                .fill(theme.cardBackground)
                .shadow(color: theme.shadow, radius: 10, x: 0, y: 5)
        )
    }

    // MARK: - Show All Toggle

    private var showAllLevelsToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                showAllLevels.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Text(L(showAllLevels ? "hide_all_levels" : "show_all_levels"))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Image(systemName: showAllLevels ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(theme.accent)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(
                Capsule()
                    .fill(theme.cardBackground)
                    .shadow(color: theme.shadow, radius: 5, x: 0, y: 2)
            )
        }
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
        let isPremiumLevel = level.id >= premiumThreshold
        let canAccess = isUnlocked && (!isPremiumLevel || storeManager.isPremium)
        
        let isPremiumLocked = isPremiumLevel && !storeManager.isPremium && isUnlocked

        if canAccess {
            NavigationLink(destination: LearningSessionView(level: level)) {
                levelCardContent(level: level, isUnlocked: true, isCompleted: isCompleted, isPremiumLocked: false)
            }
        } else if isPremiumLocked {
            // Premium-gated: tapping opens the paywall
            Button {
                showPaywall = true
            } label: {
                levelCardContent(level: level, isUnlocked: isUnlocked, isCompleted: false, isPremiumLocked: true)
            }
        } else {
            levelCardContent(level: level, isUnlocked: isUnlocked, isCompleted: false, isPremiumLocked: false)
        }
    }
    
    private func levelCardContent(level: LevelDefinition, isUnlocked: Bool, isCompleted: Bool, isPremiumLocked: Bool = false) -> some View {
        let isActive = isUnlocked && !isPremiumLocked

        return VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Level Icon
                ZStack {
                    Circle()
                        .fill(
                            isActive
                                ? LinearGradient(colors: level.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                : isPremiumLocked
                                    ? LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.25)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: isActive ? level.gradientColors[0].opacity(0.3) : .clear, radius: 8, x: 0, y: 4)

                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white)
                    } else if isPremiumLocked {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    } else if isUnlocked {
                        Image(systemName: level.icon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                // Title & Subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.localizedTitle)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(isActive ? theme.textPrimary : theme.textSecondary)

                    Text(level.localizedSubtitle)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(1)

                    // Chord count or badge
                    HStack(spacing: 4) {
                        if isPremiumLocked {
                            Image(systemName: "crown.fill").font(.system(size: 9))
                            Text("Premium")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        } else {
                            Image(systemName: "music.note").font(.system(size: 9))
                            Text("\(level.chordIdentifiers.count) chords")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                    }
                    .foregroundStyle(isPremiumLocked ? Color.orange : theme.textSecondary.opacity(0.7))
                    .padding(.top, 2)
                }

                Spacer()

                // Trailing indicator
                Group {
                    if isPremiumLocked {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.orange)
                    } else if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(theme.textSecondary.opacity(0.4))
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.textSecondary.opacity(0.5))
                    }
                }
            }
            .padding(16)

            // Completed progress bar strip at bottom of card
            if isCompleted {
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(colors: level.gradientColors, startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geo.size.width, height: 3)
                }
                .frame(height: 3)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                .fill(theme.cardBackground)
                .shadow(color: theme.shadow, radius: isActive ? 10 : 5, x: 0, y: isActive ? 5 : 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: ThemeManager.radiusMedium))
        .opacity(isActive ? 1.0 : 0.65)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LevelSelectView()
    }
}
