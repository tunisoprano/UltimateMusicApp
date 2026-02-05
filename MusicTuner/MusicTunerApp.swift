//
//  MusicTunerApp.swift
//  2Jam
//
//  Main entry point with onboarding and theme support
//

import SwiftUI

@main
struct MusicTunerApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    NavigationStack {
                        MainMenuView()
                    }
                } else {
                    OnboardingView()
                }
            }
            .id(languageManager.language) // Force full UI refresh when language changes
            .environmentObject(languageManager)
            .preferredColorScheme(themeManager.colorScheme)
            .onAppear {
                // Initialize AdMob after app is fully loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    AdsManager.shared.initializeAdMob()
                }
            }
        }
    }
}
