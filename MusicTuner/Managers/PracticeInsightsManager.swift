//
//  PracticeInsightsManager.swift
//  MusicTuner
//
//  Records per-session practice results (previously discarded when a quiz
//  screen closed) and answers the aggregate questions the Insights screen
//  needs: weekly practice time, daily activity, and most-missed items.
//

import Foundation
import SwiftData

@MainActor
final class PracticeInsightsManager: ObservableObject {
    static let shared = PracticeInsightsManager()

    private let container: ModelContainer
    private let context: ModelContext

    private init() {
        // Use an explicit URL in the app's own Application Support directory.
        // Without this, SwiftData's default resolution can land in the
        // widget's shared App Group container (since the app declares that
        // entitlement) — App Group storage is for widget-shared data, not
        // this app-private practice history.
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        let storeURL = appSupportURL.appendingPathComponent("PracticeInsights.store")

        do {
            let config = ModelConfiguration(url: storeURL)
            container = try ModelContainer(for: PracticeSession.self, PracticeAttempt.self, configurations: config)
        } catch {
            // Fall back to an in-memory store so a corrupt/incompatible store
            // on disk can't take down the whole app — insights are non-critical.
            print("⚠️ PracticeInsightsManager: falling back to in-memory store: \(error)")
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = (try? ModelContainer(for: PracticeSession.self, PracticeAttempt.self, configurations: config))
                ?? { fatalError("PracticeInsightsManager: could not create even an in-memory ModelContainer") }()
        }
        context = ModelContext(container)
    }

    // MARK: - Recording

    /// Call once when a quiz/session finishes. `attempts` should be every
    /// question/round answered during the session, in order.
    func recordSession(
        module: PracticeModule,
        score: Int,
        total: Int,
        durationSeconds: Double,
        attempts: [(label: String, isCorrect: Bool)]
    ) {
        let session = PracticeSession(module: module, durationSeconds: durationSeconds, score: score, total: total)
        session.attempts = attempts.map { PracticeAttempt(itemLabel: $0.label, isCorrect: $0.isCorrect) }
        context.insert(session)
        try? context.save()
    }

    // MARK: - Queries

    private func allSessions() -> [PracticeSession] {
        (try? context.fetch(FetchDescriptor<PracticeSession>())) ?? []
    }

    func sessions(module: PracticeModule? = nil, limit: Int = 20) -> [PracticeSession] {
        let all = allSessions()
            .filter { module == nil || $0.module == module }
            .sorted { $0.date > $1.date }
        return Array(all.prefix(limit))
    }

    func weeklyPracticeMinutes() -> Double {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let seconds = allSessions()
            .filter { $0.date >= weekAgo }
            .reduce(0.0) { $0 + $1.durationSeconds }
        return seconds / 60.0
    }

    /// Last `lastDays` days of practice time, oldest first, for a bar chart.
    func dailyActivity(lastDays: Int = 7) -> [(date: Date, minutes: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sessions = allSessions()

        var result: [(Date, Double)] = []
        for offset in stride(from: lastDays - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let seconds = sessions
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0.0) { $0 + $1.durationSeconds }
            result.append((day, seconds / 60.0))
        }
        return result
    }

    /// Items (chords/notes/tempos) missed most often, across all modules,
    /// most recent attempts weighted no differently than older ones.
    func mostMissedItems(limit: Int = 5) -> [(label: String, misses: Int)] {
        var missCounts: [String: Int] = [:]
        for session in allSessions() {
            for attempt in session.attempts where !attempt.isCorrect {
                missCounts[attempt.itemLabel, default: 0] += 1
            }
        }
        return missCounts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (label: $0.key, misses: $0.value) }
    }

    func sessionCountThisWeek(module: PracticeModule? = nil) -> Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return allSessions()
            .filter { (module == nil || $0.module == module) && $0.date >= weekAgo }
            .count
    }
}
