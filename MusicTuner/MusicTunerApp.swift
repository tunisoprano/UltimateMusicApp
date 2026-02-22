//
//  MusicTunerApp.swift
//  2Jam
//
//  Main entry point with onboarding, notifications, and adaptive layout
//

import SwiftUI

@main
struct MusicTunerApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var streakManager = StreakManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    ContentView()
                } else {
                    OnboardingView()
                }
            }
            .id(languageManager.language) // Force full UI refresh when language changes
            .environmentObject(languageManager)
            .preferredColorScheme(themeManager.colorScheme)
            .onAppear {
                initializeServices()
            }
        }
    }
    
    private func initializeServices() {
        // Initialize AdMob after app is fully loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            AdsManager.shared.initializeAdMob()
        }
        
        // Request notification permission and schedule reminders
        Task {
            let granted = await NotificationManager.shared.requestPermission()
            if granted {
                await MainActor.run {
                    NotificationManager.shared.scheduleDailyNotifications()
                }
            }
        }
        
        // Trigger streak manager initialization (checks for missed days)
        _ = streakManager.currentStreak
    }
}
