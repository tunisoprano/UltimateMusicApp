//
//  PracticeInsightsView.swift
//  MusicTuner
//
//  Shows practice history the app previously threw away: weekly practice
//  time, current streak, and which chords/notes/tempos get missed most.
//

import SwiftUI
import Charts

private enum InsightsTheme {
    static let background = Color(hex: "131313")
    static let card = Color(hex: "1F1F1F")
    static let acid = Color(hex: "F2FE08")
    static let cyan = Color(hex: "3FE0E0")
    static let violet = Color(hex: "C77DFF")
    static let amber = Color(hex: "FFB454")
    static let textPrimary = Color(hex: "E2E2E2")
    static let textSecondary = Color(hex: "929277")
}

struct PracticeInsightsView: View {
    @ObservedObject private var streakManager = StreakManager.shared
    @State private var dailyActivity: [(date: Date, minutes: Double)] = []
    @State private var weeklyMinutes: Double = 0
    @State private var mostMissed: [(label: String, misses: Int)] = []
    @State private var moduleSummaries: [(module: PracticeModule, sessions: Int, lastScore: String?)] = []

    var body: some View {
        ZStack {
            InsightsTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerCard
                    weeklyChartCard
                    if !mostMissed.isEmpty {
                        needsPracticeCard
                    }
                    moduleBreakdownCard
                }
                .padding(20)
            }
        }
        .navigationTitle(L("practice_insights"))
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.colorScheme, .dark)
        .toolbarBackground(InsightsTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear(perform: loadData)
    }

    // MARK: - Header (streak + weekly minutes)

    private var headerCard: some View {
        HStack(spacing: 16) {
            statTile(icon: "flame.fill", tint: .orange, value: "\(streakManager.currentStreak)", label: L("day_streak"))
            statTile(icon: "clock.fill", tint: InsightsTheme.cyan, value: formattedMinutes(weeklyMinutes), label: L("this_week"))
        }
    }

    private func statTile(icon: String, tint: Color, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(InsightsTheme.textPrimary)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(InsightsTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(InsightsTheme.card))
    }

    // MARK: - Weekly chart

    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("practice_this_week"))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(InsightsTheme.textPrimary)

            if dailyActivity.allSatisfy({ $0.minutes == 0 }) {
                emptyState(message: L("no_practice_yet"))
            } else {
                Chart(dailyActivity, id: \.date) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Minutes", day.minutes)
                    )
                    .foregroundStyle(InsightsTheme.acid)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                            .foregroundStyle(InsightsTheme.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(InsightsTheme.textSecondary.opacity(0.2))
                        AxisValueLabel().foregroundStyle(InsightsTheme.textSecondary)
                    }
                }
                .frame(height: 140)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(InsightsTheme.card))
    }

    // MARK: - Needs practice

    private var needsPracticeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("needs_practice"))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(InsightsTheme.textPrimary)

            VStack(spacing: 10) {
                ForEach(mostMissed, id: \.label) { item in
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(InsightsTheme.amber)
                        Text(item.label)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(InsightsTheme.textPrimary)
                        Spacer()
                        Text(L("missed_count", item.misses))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(InsightsTheme.textSecondary)
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(InsightsTheme.card))
    }

    // MARK: - Per-module breakdown

    private var moduleBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("by_module")).font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(InsightsTheme.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(moduleSummaries.enumerated()), id: \.offset) { index, summary in
                    if index > 0 {
                        Divider().background(InsightsTheme.textSecondary.opacity(0.2))
                    }
                    HStack {
                        Text(summary.module.displayName)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(InsightsTheme.textPrimary)
                        Spacer()
                        if summary.sessions > 0 {
                            Text(L("sessions_this_week", summary.sessions))
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(InsightsTheme.textSecondary)
                        } else {
                            Text(L("no_sessions_this_week"))
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(InsightsTheme.textSecondary.opacity(0.6))
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(InsightsTheme.card))
    }

    private func emptyState(message: String) -> some View {
        Text(message)
            .font(.system(size: 13, design: .rounded))
            .foregroundStyle(InsightsTheme.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 100)
    }

    // MARK: - Data

    private func loadData() {
        let manager = PracticeInsightsManager.shared
        dailyActivity = manager.dailyActivity(lastDays: 7)
        weeklyMinutes = manager.weeklyPracticeMinutes()
        mostMissed = manager.mostMissedItems(limit: 5)
        moduleSummaries = PracticeModule.allCases.map { module in
            (module: module, sessions: manager.sessionCountThisWeek(module: module), lastScore: nil)
        }
    }

    private func formattedMinutes(_ minutes: Double) -> String {
        let rounded = Int(minutes.rounded())
        return L("minutes_short", rounded)
    }
}

#Preview {
    NavigationStack {
        PracticeInsightsView()
    }
}
