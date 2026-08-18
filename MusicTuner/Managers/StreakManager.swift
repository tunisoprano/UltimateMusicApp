//
//  StreakManager.swift
//  MusicTuner
//
//  Centralized streak management for gamification
//  Tracks daily user activities: Tuner usage, Quiz completion, Exercise completion
//
//  Reset rule: 36 hours of inactivity resets the streak.
//  Same calendar day activities don't double-count.
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

    // MARK: - Config
    /// Inactivity window after which the streak resets.
    private let inactivityWindow: TimeInterval = 36 * 60 * 60 // 36 hours

    // MARK: - UserDefaults Keys
    private let streakCountKey = "streak_count"
    private let lastActivityDateKey = "streak_last_activity_date"       // yyyy-MM-dd (for widget compat)
    private let lastActivityTimestampKey = "streak_last_activity_ts"    // Double (Date.timeIntervalSince1970)

    // MARK: - Initialization
    private init() {
        loadStreak()
        checkAndUpdateStreak()
    }

    // MARK: - Public Methods

    /// Mark that user completed a daily activity (tuner, quiz, exercise).
    /// Increments streak at most once per calendar day.
    /// Resets streak to 1 if more than 36 hours have passed since last activity.
    func markDailyActivity() {
        let now = Date()
        let today = dateString(for: now)
        let lastTs = UserDefaults.standard.double(forKey: lastActivityTimestampKey)
        let lastDateStr = UserDefaults.standard.string(forKey: lastActivityDateKey) ?? ""

        if lastTs == 0 {
            // First activity ever
            currentStreak = 1
        } else {
            let elapsed = now.timeIntervalSince1970 - lastTs
            if elapsed > inactivityWindow {
                // Missed the 36h window — reset
                currentStreak = 1
            } else if lastDateStr == today {
                // Same calendar day — already counted, just refresh timestamp
                UserDefaults.standard.set(now.timeIntervalSince1970, forKey: lastActivityTimestampKey)
                hasCompletedToday = true
                syncToWidget()
                return
            } else {
                // Within 36h but new calendar day — increment
                currentStreak += 1
            }
        }

        hasCompletedToday = true
        UserDefaults.standard.set(currentStreak, forKey: streakCountKey)
        UserDefaults.standard.set(today, forKey: lastActivityDateKey)
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: lastActivityTimestampKey)

        syncToWidget()
        NotificationManager.shared.cancelTodayReminders()

        print("🔥 Streak updated: \(currentStreak)")
    }

    /// Reset streak (for testing or user-initiated restart).
    func resetStreak() {
        currentStreak = 0
        hasCompletedToday = false
        UserDefaults.standard.set(0, forKey: streakCountKey)
        UserDefaults.standard.removeObject(forKey: lastActivityDateKey)
        UserDefaults.standard.removeObject(forKey: lastActivityTimestampKey)
        syncToWidget()
    }

    // MARK: - Widget Sync

    private func syncToWidget() {
        WidgetDataManager.shared.syncFromMainApp(
            streak: currentStreak,
            lastDate: UserDefaults.standard.string(forKey: lastActivityDateKey) ?? "",
            completedToday: hasCompletedToday
        )
    }

    // MARK: - Private Methods

    private func loadStreak() {
        currentStreak = UserDefaults.standard.integer(forKey: streakCountKey)
    }

    /// Called on app launch. Enforces the 36h inactivity rule and updates `hasCompletedToday`.
    private func checkAndUpdateStreak() {
        let now = Date()
        let today = dateString(for: now)
        let lastTs = UserDefaults.standard.double(forKey: lastActivityTimestampKey)
        let lastDateStr = UserDefaults.standard.string(forKey: lastActivityDateKey) ?? ""

        // Migration: old installs have lastDate string but no timestamp.
        // Treat them as fresh but preserve streak count if lastDate is today or yesterday.
        if lastTs == 0 && !lastDateStr.isEmpty {
            let yesterday = dateString(for: Calendar.current.date(byAdding: .day, value: -1, to: now)!)
            if lastDateStr == today {
                hasCompletedToday = true
                // Seed timestamp to now so future checks work
                UserDefaults.standard.set(now.timeIntervalSince1970, forKey: lastActivityTimestampKey)
            } else if lastDateStr == yesterday {
                // Seed timestamp at midnight yesterday
                if let yDate = Calendar.current.date(byAdding: .day, value: -1, to: now) {
                    UserDefaults.standard.set(yDate.timeIntervalSince1970, forKey: lastActivityTimestampKey)
                }
                hasCompletedToday = false
            } else {
                // Too old — reset
                currentStreak = 0
                UserDefaults.standard.set(0, forKey: streakCountKey)
                hasCompletedToday = false
            }
            syncToWidget()
            return
        }

        if lastTs == 0 {
            // No history at all
            hasCompletedToday = false
            return
        }

        let elapsed = now.timeIntervalSince1970 - lastTs
        if elapsed > inactivityWindow {
            // Inactivity window exceeded — reset
            currentStreak = 0
            hasCompletedToday = false
            UserDefaults.standard.set(0, forKey: streakCountKey)
        } else if lastDateStr == today {
            hasCompletedToday = true
        } else {
            // Still within window, new day — streak intact, waiting for today's activity
            hasCompletedToday = false
        }

        syncToWidget()
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter
    }()

    private func dateString(for date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }
}
