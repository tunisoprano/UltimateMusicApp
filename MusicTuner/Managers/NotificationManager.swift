//
//  NotificationManager.swift
//  MusicTuner
//
//  Manages local notifications for daily practice reminders
//  2x daily: Morning (09:00), Evening (20:00)
//

import Foundation
import UserNotifications

/// Manages local notifications for daily practice reminders
@MainActor
final class NotificationManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = NotificationManager()
    
    // MARK: - Published Properties
    @Published private(set) var isAuthorized = false
    
    // MARK: - Notification Identifiers
    private let morningNotificationId = "daily_reminder_morning"
    private let eveningNotificationId = "daily_reminder_evening"
    
    // MARK: - Initialization
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Public Methods
    
    /// Request notification permission
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            
            if granted {
                scheduleDailyNotifications()
            }
            
            return granted
        } catch {
            print("❌ Notification permission error: \(error)")
            return false
        }
    }
    
    /// Schedule all daily notifications (2x: morning + evening)
    func scheduleDailyNotifications() {
        // Cancel existing first
        cancelAllNotifications()
        
        // Only schedule if user hasn't completed today's streak
        guard !StreakManager.shared.hasCompletedToday else {
            print("✅ Streak completed today, skipping notifications")
            return
        }
        
        // Schedule morning (09:00)
        scheduleNotification(
            id: morningNotificationId,
            hour: 9,
            minute: 0,
            titleEN: "Good morning! 🌅",
            bodyEN: "Start your day with music practice.",
            titleTR: "Günaydın! 🌅",
            bodyTR: "Güne müzik pratiğiyle başla."
        )
        
        // Schedule evening (20:00)
        scheduleNotification(
            id: eveningNotificationId,
            hour: 20,
            minute: 0,
            titleEN: "Don't break your streak! 🔥",
            bodyEN: "Just 30 seconds of practice keeps you going.",
            titleTR: "Serisini bozma! 🔥",
            bodyTR: "Sadece 30 saniyelik pratik yeter."
        )
        
        print("📅 Daily notifications scheduled")
    }
    
    /// Cancel today's remaining reminders (called when streak is completed)
    func cancelTodayReminders() {
        cancelAllNotifications()
        print("🔕 Today's reminders cancelled")
    }
    
    /// Cancel all scheduled notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            // Includes the legacy "afternoon" id so existing installs that already
            // scheduled it get it cleaned up after this update.
            withIdentifiers: [morningNotificationId, eveningNotificationId, "daily_reminder_afternoon"]
        )
    }
    
    // MARK: - Private Methods
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func scheduleNotification(
        id: String,
        hour: Int,
        minute: Int,
        titleEN: String,
        bodyEN: String,
        titleTR: String,
        bodyTR: String
    ) {
        // Get system language
        // Use app language setting (not system locale)
        let isTurkish = LanguageManager.shared.language == .turkish
        
        let content = UNMutableNotificationContent()
        content.title = isTurkish ? titleTR : titleEN
        content.body = isTurkish ? bodyTR : bodyEN
        content.sound = .default
        content.badge = 1
        
        // Create trigger for specific time, repeating daily
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule \(id): \(error)")
            } else {
                print("✅ Scheduled \(id) for \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
}
