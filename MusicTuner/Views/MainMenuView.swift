//
//  MainMenuView.swift
//  MusicTuner
//
//  Modern dashboard with hero cards and tool buttons
//

import SwiftUI

/// Main dashboard with hero section and tools
struct MainMenuView: View {
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var storeManager = StoreKitManager.shared
    @ObservedObject var adsManager = AdsManager.shared
    
    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        heroSection
                        toolsSection
                        
                        if !storeManager.isPremium {
                            premiumButton
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                }
                
                // Banner Ad at bottom
                AdBannerContainer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.background, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(theme.accentGradient)
                    .frame(width: 72, height: 72)
                    .shadow(color: theme.accent.opacity(0.3), radius: 12, x: 0, y: 6)
                
                Image(systemName: "music.note")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Text("MusicTuner")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
            
            Text("Your music education companion")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textSecondary)
        }
    }
    
    // MARK: - Hero Section (Main Features)
    
    private var heroSection: some View {
        VStack(spacing: 14) {
            // Ear Training - Large Card
            NavigationLink(destination: EarTrainingView()) {
                HeroCard(
                    icon: "ear.fill",
                    title: String(localized: "ear_training"),
                    subtitle: "Train your ear with chord recognition",
                    gradientColors: [Color.purple, Color.pink],
                    theme: theme
                )
            }
            .simultaneousGesture(TapGesture().onEnded { _ in
                adsManager.recordPageTransition()
            })
            
            // Chord Library - Large Card (NEW)
            NavigationLink(destination: ChordLibraryView()) {
                HeroCard(
                    icon: "book.fill",
                    title: String(localized: "chord_library"),
                    subtitle: "Learn chords with interactive diagrams",
                    gradientColors: [Color.orange, Color.red],
                    theme: theme
                )
            }
            .simultaneousGesture(TapGesture().onEnded { _ in
                adsManager.recordPageTransition()
            })
            
            // Fretboard Training - Large Card
            NavigationLink(destination: ExerciseView()) {
                HeroCard(
                    icon: "guitars.fill",
                    title: String(localized: "fretboard"),
                    subtitle: "Master the fretboard with exercises",
                    gradientColors: [Color.green, Color.teal],
                    theme: theme
                )
            }
            .simultaneousGesture(TapGesture().onEnded { _ in
                adsManager.recordPageTransition()
            })
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Tools Section
    
    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tools")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 20)
            
            HStack(spacing: 14) {
                NavigationLink(destination: TunerView()) {
                    ToolCard(
                        icon: "tuningfork",
                        title: String(localized: "tuner"),
                        color: theme.accent,
                        theme: theme
                    )
                }
                .simultaneousGesture(TapGesture().onEnded { _ in
                    adsManager.recordPageTransition()
                })
                
                NavigationLink(destination: MetronomeView()) {
                    ToolCard(
                        icon: "metronome.fill",
                        title: String(localized: "metronome"),
                        color: theme.warning,
                        theme: theme
                    )
                }
                .simultaneousGesture(TapGesture().onEnded { _ in
                    adsManager.recordPageTransition()
                })
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Premium Button
    
    private var premiumButton: some View {
        Button {
            Task {
                await storeManager.purchaseRemoveAds()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.system(size: 18))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Remove Ads")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    
                    if let product = storeManager.removeAdsProduct {
                        Text(product.displayPrice)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .opacity(0.8)
                    }
                }
                
                Spacer()
                
                if storeManager.isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                    .fill(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                    .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
            )
        }
        .disabled(storeManager.isPurchasing)
        .padding(.horizontal, 20)
    }
}

// MARK: - Hero Card

struct HeroCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradientColors: [Color]
    let theme: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: ThemeManager.radiusLarge)
                .fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: gradientColors[0].opacity(0.3), radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - Tool Card

struct ToolCard: View {
    let icon: String
    let title: String
    let color: Color
    let theme: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(color)
            }
            
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                .fill(theme.cardBackground)
                .shadow(color: theme.shadow, radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    NavigationStack {
        MainMenuView()
    }
}
