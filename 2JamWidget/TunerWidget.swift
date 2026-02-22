//
//  TunerWidget.swift
//  2JamWidget
//
//  Quick launch widget for Tuner with streak display
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct TunerWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TunerWidgetEntry {
        TunerWidgetEntry(date: Date(), streakCount: 5)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TunerWidgetEntry) -> Void) {
        let entry = TunerWidgetEntry(date: Date(), streakCount: getStreakCount())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TunerWidgetEntry>) -> Void) {
        let entry = TunerWidgetEntry(date: Date(), streakCount: getStreakCount())
        
        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func getStreakCount() -> Int {
        guard let defaults = UserDefaults(suiteName: "group.tuni.2jam") else { return 0 }
        return defaults.integer(forKey: "widget_streak_count")
    }
}

// MARK: - Entry

struct TunerWidgetEntry: TimelineEntry {
    let date: Date
    let streakCount: Int
}

// MARK: - Widget View

struct TunerWidgetView: View {
    var entry: TunerWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Full gradient background
                LinearGradient(
                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Content
                VStack(spacing: 0) {
                    // Top: Streak badge
                    HStack {
                        Spacer()
                        streakBadge
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 12)
                    
                    Spacer()
                    
                    // Center: Icon
                    Image(systemName: "tuningfork")
                        .font(.system(size: iconSize, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 4)
                    
                    Spacer()
                    
                    // Bottom: Title
                    Text("Tuner")
                        .font(.system(size: titleSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.bottom, 14)
                }
            }
        }
        .widgetURL(URL(string: "jam2://tuner"))
    }
    
    private var streakBadge: some View {
        HStack(spacing: 3) {
            Text("🔥")
                .font(.system(size: 11))
            Text("\(entry.streakCount)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.white.opacity(0.25))
        )
    }
    
    private var iconSize: CGFloat {
        family == .systemSmall ? 42 : 52
    }
    
    private var titleSize: CGFloat {
        family == .systemSmall ? 15 : 18
    }
}

// MARK: - Widget Configuration

struct TunerWidget: Widget {
    let kind: String = "TunerWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TunerWidgetProvider()) { entry in
            TunerWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("Tuner")
        .description("Quick access to tune your instrument")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    TunerWidget()
} timeline: {
    TunerWidgetEntry(date: .now, streakCount: 7)
}
