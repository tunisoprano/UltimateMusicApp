//
//  MusicTunerApp.swift
//  MusicTuner
//
//  Main entry point with onboarding and theme support
//

import SwiftUI

@main
struct MusicTunerApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @ObservedObject private var themeManager = ThemeManager.shared
    
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
