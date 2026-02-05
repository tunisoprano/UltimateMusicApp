//
//  String+Localization.swift
//  2Jam
//
//  Helper extension for dynamic localization with LanguageManager
//

import Foundation

extension String {
    /// Returns localized string from the user-selected language bundle
    var localized: String {
        LanguageManager.shared.bundle.localizedString(forKey: self, value: nil, table: nil)
    }
    
    /// Returns localized string with format arguments
    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}

// MARK: - Localization Keys

/// Type-safe localization keys using computed properties for dynamic language switching
enum L10n {
    // Navigation
    static var earTraining: String { "ear_training".localized }
    static var fretboard: String { "fretboard".localized }
    static var tuner: String { "tuner".localized }
    static var metronome: String { "metronome".localized }
    static var settings: String { "settings".localized }
    static var chordLibrary: String { "chord_library".localized }
    
    // Actions
    static var start: String { "start".localized }
    static var stop: String { "stop".localized }
    static var continueAction: String { "continue".localized }
    static var skip: String { "skip".localized }
    static var next: String { "next".localized }
    static var getStarted: String { "get_started".localized }
    
    // Game
    static func score(_ value: Int) -> String {
        "score_format".localized(with: value)
    }
    static var levelLocked: String { "level_locked".localized }
    static var completePrevious: String { "complete_previous".localized }
    static var comingSoon: String { "coming_soon".localized }
    
    // Theme
    static var themeSystem: String { "theme_system".localized }
    static var themeLight: String { "theme_light".localized }
    static var themeDark: String { "theme_dark".localized }
    static var appearance: String { "appearance".localized }
    
    // Language
    static var language: String { "language".localized }
    
    // Settings
    static var noteNaming: String { "note_naming".localized }
    static var displayStyle: String { "display_style".localized }
    static var preview: String { "preview".localized }
    static var soundFeedback: String { "sound_feedback".localized }
    static var successSound: String { "success_sound".localized }
    static var playDingWhenTuned: String { "play_ding_when_tuned".localized }
    static var hapticFeedback: String { "haptic_feedback".localized }
    static var vibrateWhenTuned: String { "vibrate_when_tuned".localized }
    static var purchases: String { "purchases".localized }
    static var premiumStatus: String { "premium_status".localized }
    static var adsRemoved: String { "ads_removed".localized }
    static var freeVersion: String { "free_version".localized }
    static var active: String { "active".localized }
    static var restorePurchases: String { "restore_purchases".localized }
    static var about: String { "about".localized }
    static var version: String { "version".localized }
    static var build: String { "build".localized }
    static var theme: String { "theme".localized }
    
    // Onboarding
    static var onboardingWelcomeTitle: String { "onboarding_welcome_title".localized }
    static var onboardingWelcomeSubtitle: String { "onboarding_welcome_subtitle".localized }
    static var onboardingFeaturesTitle: String { "onboarding_features_title".localized }
    static var onboardingFeaturesSubtitle: String { "onboarding_features_subtitle".localized }
    static var onboardingStartTitle: String { "onboarding_start_title".localized }
    static var onboardingStartSubtitle: String { "onboarding_start_subtitle".localized }
}

