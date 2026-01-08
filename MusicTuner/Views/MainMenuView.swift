//
//  MainMenuView.swift
//  MusicTuner
//
//  Created by MusicTuner
//

import SwiftUI

/// Main menu with theme support, ads, and premium button
struct MainMenuView: View {
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var storeManager = StoreKitManager.shared
    @ObservedObject var adsManager = AdsManager.shared
    
    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 28) {
                        headerSection
                        menuCards
                        
                        if !storeManager.isPremium {
                            premiumButton
                        }
                    }
                    .padding(.top, 32)
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
    
    // MARK: - Header
    
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
            
            Text("Tune with confidence ✨")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textSecondary)
        }
    }
    
    // MARK: - Menu Cards
    
    private var menuCards: some View {
        VStack(spacing: 14) {
            NavigationLink(destination: TunerView()) {
                MenuCard(icon: "tuningfork", title: "Tuner", subtitle: "Tune your instrument", color: theme.accent)
            }
            .simultaneousGesture(TapGesture().onEnded { _ in
                adsManager.recordPageTransition()
            })
            
            NavigationLink(destination: MetronomeView()) {
                MenuCard(icon: "metronome.fill", title: "Metronome", subtitle: "Keep perfect tempo", color: theme.warning)
            }
            .simultaneousGesture(TapGesture().onEnded { _ in
                adsManager.recordPageTransition()
            })
            
            NavigationLink(destination: ExerciseView()) {
                MenuCard(icon: "gamecontroller.fill", title: "Exercises", subtitle: "Train your fretboard", color: theme.success)
            }
            .simultaneousGesture(TapGesture().onEnded { _ in
                adsManager.recordPageTransition()
            })
        }
        .padding(.horizontal, 20)
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

// MARK: - Menu Card

struct MenuCard: View {
    @ObservedObject var theme = ThemeManager.shared
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 54, height: 54)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.inactive)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                .fill(theme.cardBackground)
                .shadow(color: theme.shadow, radius: 10, x: 0, y: 5)
        )
    }
}

#Preview {
    NavigationStack {
        MainMenuView()
    }
}
