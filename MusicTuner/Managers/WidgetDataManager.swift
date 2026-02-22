//
//  WidgetDataManager.swift
//  MusicTuner
//
//  Shared data manager for Widget and Main App communication
//  Uses App Groups UserDefaults for cross-process data sharing
//

import Foundation

/// Manages shared data between Main App and Widget Extension
public final class WidgetDataManager {
    
    // MARK: - Singleton
    public static let shared = WidgetDataManager()
    
    // MARK: - App Group
    private let appGroupID = "group.tuni.2jam"
    private let userDefaults: UserDefaults
    
    // MARK: - Keys
    private let streakCountKey = "widget_streak_count"
    private let lastActivityDateKey = "widget_last_activity_date"
    private let hasCompletedTodayKey = "widget_has_completed_today"
    
    // MARK: - Initialization
    private init() {
        if let defaults = UserDefaults(suiteName: appGroupID) {
            self.userDefaults = defaults
        } else {
            // Fallback to standard (won't work for widget, but prevents crashes)
            self.userDefaults = .standard
            print("⚠️ WidgetDataManager: App Group not available, using standard UserDefaults")
        }
    }
    
    // MARK: - Streak Data
    
    /// Current streak count
    public var streakCount: Int {
        get { userDefaults.integer(forKey: streakCountKey) }
        set { userDefaults.set(newValue, forKey: streakCountKey) }
    }
    
    /// Last activity date string (yyyy-MM-dd)
    public var lastActivityDate: String {
        get { userDefaults.string(forKey: lastActivityDateKey) ?? "" }
        set { userDefaults.set(newValue, forKey: lastActivityDateKey) }
    }
    
    /// Whether user has completed daily activity today
    public var hasCompletedToday: Bool {
        get { userDefaults.bool(forKey: hasCompletedTodayKey) }
        set { userDefaults.set(newValue, forKey: hasCompletedTodayKey) }
    }
    
    // MARK: - Sync Methods
    
    /// Sync streak data from main app to widget
    public func syncFromMainApp(streak: Int, lastDate: String, completedToday: Bool) {
        streakCount = streak
        lastActivityDate = lastDate
        hasCompletedToday = completedToday
    }
}
