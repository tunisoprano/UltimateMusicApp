//
//  MainMenuView.swift
//  MusicTuner
//
//  Apple HIG-inspired dashboard with clean grouped layout
//

import SwiftUI

/// Main dashboard - Apple-standard grouped design
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
                ScrollView {
                    VStack(spacing: 28) {
                        headerSection
                        practiceSection
                        toolsSection
                        learnSection
                        
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
            ToolbarItem(placement: .topBarLeading) {
                StreakBadgeView()
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("2Jam")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
            
            Text(L("app_subtitle"))
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Practice Section (Tools)
    
    private var practiceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: L("tools"), icon: "wrench.and.screwdriver")
            
            HStack(spacing: 12) {
                // Tuner
                NavigationLink(destination: TunerView()) {
                    ToolTile(
                        icon: "tuningfork",
                        title: L("tuner"),
                        tint: .blue,
                        theme: theme
                    )
                }
                .simultaneousGesture(TapGesture().onEnded { _ in
                    adsManager.recordPageTransition()
                })
                
                // Metronome
                NavigationLink(destination: MetronomeView()) {
                    ToolTile(
                        icon: "metronome.fill",
                        title: L("metronome"),
                        tint: .orange,
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
    
    // MARK: - Tools Section → actually "Learn" features
    
    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: L("ear_training"), icon: "music.note.list")
            
            VStack(spacing: 2) {
                // Ear Training
                NavigationLink(destination: EarTrainingLevelSelectView()) {
                    MenuRow(
                        icon: "ear.fill",
                        title: L("ear_training"),
                        subtitle: L("ear_training_subtitle"),
                        tint: .purple,
                        theme: theme
                    )
                }
                .simultaneousGesture(TapGesture().onEnded { _ in
                    adsManager.recordPageTransition()
                })
                
                Divider().padding(.leading, 60)
                
                // Fretboard Training
                NavigationLink(destination: ExerciseView()) {
                    MenuRow(
                        icon: "guitars.fill",
                        title: L("fretboard"),
                        subtitle: L("fretboard_subtitle"),
                        tint: .green,
                        theme: theme
                    )
                }
                .simultaneousGesture(TapGesture().onEnded { _ in
                    adsManager.recordPageTransition()
                })
                
                Divider().padding(.leading, 60)
                
                // Tempo Trainer - Coming Soon
                MenuRow(
                    icon: "waveform.path",
                    title: L("tempo_trainer"),
                    subtitle: L("coming_soon"),
                    tint: .indigo,
                    theme: theme,
                    isLocked: true
                )
            }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackground)
            )
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Learn Section (Chords)
    
    private var learnSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: L("chord_library"), icon: "book.fill")
            
            VStack(spacing: 2) {
                // Chord Library
                NavigationLink(destination: ChordLibraryView()) {
                    MenuRow(
                        icon: "book.fill",
                        title: L("chord_library"),
                        subtitle: L("chord_library_subtitle"),
                        tint: .red,
                        theme: theme
                    )
                }
                .simultaneousGesture(TapGesture().onEnded { _ in
                    adsManager.recordPageTransition()
                })
                
                Divider().padding(.leading, 60)
                
                // Chord Mastery
                NavigationLink(destination: LevelSelectView()) {
                    MenuRow(
                        icon: "graduationcap.fill",
                        title: L("learn_chord_diagrams"),
                        subtitle: L("chord_mastery_subtitle"),
                        tint: .cyan,
                        theme: theme
                    )
                }
                .simultaneousGesture(TapGesture().onEnded { _ in
                    adsManager.recordPageTransition()
                })
            }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackground)
            )
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

// MARK: - Tool Tile (Square card for Tuner/Metronome)

struct ToolTile: View {
    let icon: String
    let title: String
    let tint: Color
    let theme: ThemeManager
    
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(tint.gradient)
                    .frame(width: 52, height: 52)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackground)
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
