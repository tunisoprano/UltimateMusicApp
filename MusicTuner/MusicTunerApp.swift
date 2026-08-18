//
//  MusicTunerApp.swift
//  2Jam
//
//  Main entry point with onboarding, notifications, and adaptive layout
//

import SwiftUI
import UserNotifications

@main
struct MusicTunerApp: App {
    @Environment(\.scenePhase) private var scenePhase
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                UNUserNotificationCenter.current().setBadgeCount(0)
            }
        }
    }
    
    private func initializeServices() {
        // ATT permission + AdMob initialization is handled in ContentView.onAppear
        // to ensure the UIWindowScene is fully ready on both iPhone and iPad.

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
