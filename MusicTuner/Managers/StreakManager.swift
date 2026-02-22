//
//  StreakManager.swift
//  MusicTuner
//
//  Centralized streak management for gamification
//  Tracks daily user activities: Tuner usage, Quiz completion, Exercise completion
//

import Foundation
import SwiftUI

/// Centralized manager for daily streak tracking
@MainActor
final class StreakManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = StreakManager()
    
    // MARK: - Published Properties
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var hasCompletedToday: Bool = false
    
    // MARK: - UserDefaults Keys
    private let streakCountKey = "streak_count"
    private let lastActivityDateKey = "streak_last_activity_date"
    
    // MARK: - Initialization
    private init() {
        loadStreak()
        checkAndUpdateStreak()
    }
    
    // MARK: - Public Methods
    
    /// Mark that user completed a daily activity (tuner 30s, quiz, exercise)
    /// Call this from ViewModels when user completes an activity
    func markDailyActivity() {
        guard !hasCompletedToday else { return }
        
        let today = dateString(for: Date())
        let yesterday = dateString(for: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        let lastDate = UserDefaults.standard.string(forKey: lastActivityDateKey) ?? ""
        
        if lastDate == today {
            // Already recorded today
            return
        } else if lastDate == yesterday || lastDate.isEmpty {
            // Consecutive day or first activity - increment streak
            currentStreak += 1
        } else {
            // Missed days - start fresh
            currentStreak = 1
        }
        
        hasCompletedToday = true
        UserDefaults.standard.set(currentStreak, forKey: streakCountKey)
        UserDefaults.standard.set(today, forKey: lastActivityDateKey)
        
        // Sync to Widget
        syncToWidget()
        
        // Notify NotificationManager to cancel today's reminders
        NotificationManager.shared.cancelTodayReminders()
        
        print("🔥 Streak updated: \(currentStreak)")
    }
    
    // MARK: - Widget Sync
    
    /// Sync streak data to Widget via App Groups
    private func syncToWidget() {
        WidgetDataManager.shared.syncFromMainApp(
            streak: currentStreak,
            lastDate: UserDefaults.standard.string(forKey: lastActivityDateKey) ?? "",
            completedToday: hasCompletedToday
        )
    }
    
    /// Reset streak (for testing or if user wants to restart)
    func resetStreak() {
        currentStreak = 0
        hasCompletedToday = false
        UserDefaults.standard.set(0, forKey: streakCountKey)
        UserDefaults.standard.removeObject(forKey: lastActivityDateKey)
    }
    
    // MARK: - Private Methods
    
    private func loadStreak() {
        currentStreak = UserDefaults.standard.integer(forKey: streakCountKey)
    }
    
    private func checkAndUpdateStreak() {
        let today = dateString(for: Date())
        let yesterday = dateString(for: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        let lastDate = UserDefaults.standard.string(forKey: lastActivityDateKey) ?? ""
        
        if lastDate == today {
            // Already completed today
            hasCompletedToday = true
        } else if lastDate == yesterday {
            // Consecutive day - streak continues, waiting for activity
            hasCompletedToday = false
        } else if !lastDate.isEmpty {
            // Missed a day - reset streak
            currentStreak = 0
            UserDefaults.standard.set(0, forKey: streakCountKey)
            hasCompletedToday = false
        }
    }
    
    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
