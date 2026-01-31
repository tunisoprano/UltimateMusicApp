//
//  String+Localization.swift
//  MusicTuner
//
//  Helper extension for type-safe localization
//

import Foundation

extension String {
    /// Returns localized string using NSLocalizedString
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    /// Returns localized string with format arguments
    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}

// MARK: - Localization Keys

/// Type-safe localization keys
enum L10n {
    // Navigation
    static let earTraining = String(localized: "ear_training")
    static let fretboard = String(localized: "fretboard")
    static let tuner = String(localized: "tuner")
    static let metronome = String(localized: "metronome")
    static let settings = String(localized: "settings")
    
    // Actions
    static let start = String(localized: "start")
    static let stop = String(localized: "stop")
    static let continueAction = String(localized: "continue")
    static let skip = String(localized: "skip")
    
    // Game
    static func score(_ value: Int) -> String {
        String(localized: "score_format", defaultValue: "Score: \(value)")
    }
    static let levelLocked = String(localized: "level_locked")
    static let completePrevious = String(localized: "complete_previous")
    static let comingSoon = String(localized: "coming_soon")
    
    // Theme
    static let themeSystem = String(localized: "theme_system")
    static let themeLight = String(localized: "theme_light")
    static let themeDark = String(localized: "theme_dark")
    static let appearance = String(localized: "appearance")
}
