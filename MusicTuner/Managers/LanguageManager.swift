//
//  LanguageManager.swift
//  2Jam
//
//  Manages app language independently of iOS system settings
//

import SwiftUI

// MARK: - Language Enum

/// Supported languages in the app
enum Language: String, CaseIterable, Identifiable {
    case turkish = "tr"
    case english = "en"
    
    var id: String { rawValue }
    
    /// Display name in native language
    var displayName: String {
        switch self {
        case .turkish: return "Türkçe"
        case .english: return "English"
        }
    }
    
    /// Flag emoji for visual representation
    var flag: String {
        switch self {
        case .turkish: return "🇹🇷"
        case .english: return "🇬🇧"
        }
    }
}

// MARK: - Language Manager

/// Singleton manager for app-wide language settings
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    /// Current language selection, persisted in UserDefaults
    @AppStorage("appLanguage") var language: Language = .turkish {
        didSet {
            // Update bundle and trigger UI refresh
            updateBundle()
            objectWillChange.send()
        }
    }
    
    /// Bundle for the currently selected language
    private(set) var bundle: Bundle = Bundle.main
    
    private init() {
        updateBundle()
    }
    
    private func updateBundle() {
        if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            bundle = langBundle
        } else {
            bundle = Bundle.main
        }
    }
    
    /// Get localized string from the selected language bundle
    func localizedString(for key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
    
    /// Get localized string with format arguments
    func localizedString(for key: String, arguments: CVarArg...) -> String {
        let format = bundle.localizedString(forKey: key, value: nil, table: nil)
        return String(format: format, arguments: arguments)
    }
}

// MARK: - Global Localization Function

/// Shorthand function for localization - use L("key") instead of "key".localized
func L(_ key: String) -> String {
    LanguageManager.shared.bundle.localizedString(forKey: key, value: nil, table: nil)
}

/// Shorthand function for localization with arguments
func L(_ key: String, _ arguments: CVarArg...) -> String {
    let format = LanguageManager.shared.bundle.localizedString(forKey: key, value: nil, table: nil)
    return String(format: format, arguments: arguments)
}

