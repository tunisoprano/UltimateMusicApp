//
//  MainMenuView.swift
//  MusicTuner
//
//  Apple HIG-inspired dashboard with clean grouped layout
//

import SwiftUI

/// Gamified brand accent used for progress/streak elements (see DESIGN.md redesign)
private enum Gamify {
    static let acid = Color(hex: "F2FE08")
    static let acidDim = Color(hex: "C5CF00")
    static let cyan = Color(hex: "3FE0E0")
    static let violet = Color(hex: "C77DFF")
    static let amber = Color(hex: "FFB454")
}

/// Main dashboard - gamified, exercises-first layout
struct MainMenuView: View {
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var storeManager = StoreKitManager.shared
    @ObservedObject var adsManager = AdsManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("2Jam")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: "F2FE08")) // Acid Yellow
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 28) {
                        dailyExercisesSection
                        studioToolsSection

                        if !storeManager.isPremium {
                            premiumSection
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }

                // Banner Ad at bottom
                AdBannerContainer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                StreakBadgeView()
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
    }
    
    
    // MARK: - Daily Exercises Section (gamified progress cards, shown first)

    private var dailyExercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: L("daily_exercises"), icon: "flame.fill")

            VStack(spacing: 12) {
                NavigationLink(destination: EarTrainingLevelSelectView()) {
                    GamifiedExerciseCard(
                        icon: "ear.fill",
                        title: L("ear_training"),
                        level: LocalProgressService.shared.getEarTrainingUnlockedLevel(),
                        totalLevels: EarTrainingCurriculum.totalLevels,
                        tint: Gamify.acid,
                        theme: theme
                    )
                }
                .simultaneousGesture(TapGesture().onEnded { _ in
                    adsManager.recordPageTransition()
                })

                NavigationLink(destination: ExerciseView()) {
                    GamifiedExerciseCard(
                        icon: "guitars.fill",
                        title: L("fretboard"),
                        level: LocalProgressService.shared.getFretboardUnlockedLevel(),
                        totalLevels: FretboardCurriculum.totalLevels,
                        tint: Gamify.cyan,
                        theme: theme
                    )
                }
                .simultaneousGesture(TapGesture().onEnded { _ in
                    adsManager.recordPageTransition()
                })

                NavigationLink(destination: LevelSelectView()) {
                    GamifiedExerciseCard(
                        icon: "music.note",
                        title: L("learn_chord_diagrams"),
                        level: LocalProgressService.shared.getUnlockedLevel(),
                        totalLevels: ChordCurriculum.totalLevels,
                        tint: Gamify.violet,
                        theme: theme
                    )
                }
                .simultaneousGesture(TapGesture().onEnded { _ in
                    adsManager.recordPageTransition()
                })

                NavigationLink(destination: TempoTrainingSignatureSelectView()) {
                    SimpleExerciseCard(
                        icon: "metronome.fill",
                        title: L("tempo_training"),
                        subtitle: L("tempo_training_subtitle"),
                        tint: Gamify.amber,
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

    // MARK: - Studio Tools Section (Tuner / Metronome)

    private var studioToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: L("tools"), icon: "wrench.and.screwdriver")

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    NavigationLink(destination: ChordMakerView()) {
                        ToolTile(
                            icon: "wand.and.stars.inverse",
                            title: L("chord_maker"),
                            tint: Gamify.violet,
                            theme: theme
                        )
                    }
                    .simultaneousGesture(TapGesture().onEnded { _ in
                        adsManager.recordPageTransition()
                    })

                    NavigationLink(destination: ChordLibraryView()) {
                        ToolTile(
                            icon: "book.fill",
                            title: L("chord_library"),
                            tint: Gamify.amber,
                            theme: theme
                        )
                    }
                    .simultaneousGesture(TapGesture().onEnded { _ in
                        adsManager.recordPageTransition()
                    })
                }

                HStack(spacing: 12) {
                    NavigationLink(destination: TunerView()) {
                        ToolTile(
                            icon: "tuningfork",
                            title: L("tuner"),
                            tint: Gamify.acid,
                            theme: theme
                        )
                    }
                    .simultaneousGesture(TapGesture().onEnded { _ in
                        adsManager.recordPageTransition()
                    })

                    NavigationLink(destination: MetronomeView()) {
                        ToolTile(
                            icon: "metronome.fill",
                            title: L("metronome"),
                            tint: Gamify.cyan,
                            theme: theme
                        )
                    }
                    .simultaneousGesture(TapGesture().onEnded { _ in
                        adsManager.recordPageTransition()
                    })
                }

                NavigationLink(destination: PracticeInsightsView()) {
                    ToolTile(
                        icon: "chart.bar.fill",
                        title: L("practice_insights"),
                        tint: Gamify.acid,
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

    // MARK: - Premium Section

    private var premiumSection: some View {
        VStack(spacing: 12) {
            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.yellow.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.orange.opacity(0.3), radius: 6, x: 0, y: 3)
                            .frame(width: 40, height: 40)

                        if storeManager.isPurchasing || storeManager.isLoadingProducts {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("iap_subscribe"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)

                        if storeManager.isLoadingProducts {
                            Text(L("loading"))
                                .font(.system(size: 13))
                                .foregroundStyle(theme.textSecondary)
                        } else if let product = storeManager.subscriptionProduct {
                            Text(product.displayPrice + " " + L("iap_per_month"))
                                .font(.system(size: 13))
                                .foregroundStyle(theme.textSecondary)
                        } else {
                            Text(L("unavailable_try_later"))
                                .font(.system(size: 13))
                                .foregroundStyle(theme.textSecondary)
                        }
                    }

                    Spacer()

                    if !storeManager.isPurchasing && !storeManager.isLoadingProducts {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.cardBackground)
                )
            }
            .disabled(storeManager.isPurchasing)
            .padding(.horizontal, 20)

            // Error message when purchase fails
            if let error = storeManager.errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.error)
                    .padding(.horizontal, 24)
            }
            
            // Subscription legal text
            VStack(spacing: 8) {
                Text(L("iap_subscription_terms"))
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(theme.textSecondary.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    Link(L("terms_of_use"), destination: URL(string: "https://tunisoprano.github.io/2jam-terms/")!)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.accent)
                    
                    Link(L("privacy_policy"), destination: URL(string: "https://tunisoprano.github.io/2jam-privacy/")!)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.accent)
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.textSecondary)
            
            Text(title.uppercased())
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.textSecondary)
                .tracking(0.8)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Gamified Exercise Card (Home screen "Daily Exercises")

struct GamifiedExerciseCard: View {
    let icon: String
    let title: String
    let level: Int
    let totalLevels: Int
    let tint: Color
    let theme: ThemeManager

    private var progress: CGFloat {
        guard totalLevels > 0 else { return 0 }
        return CGFloat(min(level - 1, totalLevels)) / CGFloat(totalLevels)
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(tint.opacity(0.15))
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)

                Text(L("level_n", level))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textSecondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(theme.inactive.opacity(0.25))
                        Capsule()
                            .fill(tint)
                            .frame(width: max(6, geo.size.width * progress))
                    }
                }
                .frame(height: 8)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.inactive)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(tint.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Simple Exercise Card (no level/progress — for single-round exercises)

struct SimpleExerciseCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let theme: ThemeManager

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(tint.opacity(0.15))
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)

                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.inactive)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(tint.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Tool Tile (Square card for Tuner/Metronome)

struct ToolTile: View {
    let icon: String
    let title: String
    let tint: Color
    let theme: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(tint.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(tint)
            }
            
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(theme.cardBackground)
                
                // 3D bottom shadow effect
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.black.opacity(0.3))
                        .frame(height: 4)
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(hex: "2a2a2a"), lineWidth: 1.5)
        )
    }
}

// MARK: - Menu Row (Grouped list item)

struct MenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let theme: ThemeManager
    var isLocked: Bool = false
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(tint.gradient)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isLocked ? theme.textSecondary : theme.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if isLocked {
                Text(L("coming_soon"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(uiColor: .tertiarySystemFill))
                    )
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        MainMenuView()
    }
}
