//
//  MetronomeWidget.swift
//  2JamWidget
//
//  Quick launch widget for Metronome with streak display
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct MetronomeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MetronomeWidgetEntry {
        MetronomeWidgetEntry(date: Date(), streakCount: 5)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MetronomeWidgetEntry) -> Void) {
        let entry = MetronomeWidgetEntry(date: Date(), streakCount: getStreakCount())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MetronomeWidgetEntry>) -> Void) {
        let entry = MetronomeWidgetEntry(date: Date(), streakCount: getStreakCount())
        
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

struct MetronomeWidgetEntry: TimelineEntry {
    let date: Date
    let streakCount: Int
}

// MARK: - Widget View

struct MetronomeWidgetView: View {
    var entry: MetronomeWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Full gradient background
                LinearGradient(
                    colors: [Color(hex: "f093fb"), Color(hex: "f5576c")],
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
                    Image(systemName: "metronome.fill")
                        .font(.system(size: iconSize, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 4)
                    
                    Spacer()
                    
                    // Bottom: Title
                    Text("Metronome")
                        .font(.system(size: titleSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.bottom, 14)
                }
            }
        }
        .widgetURL(URL(string: "jam2://metronome"))
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

struct MetronomeWidget: Widget {
    let kind: String = "MetronomeWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MetronomeWidgetProvider()) { entry in
            MetronomeWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("Metronome")
        .description("Quick access to your metronome")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    MetronomeWidget()
} timeline: {
    MetronomeWidgetEntry(date: .now, streakCount: 3)
}
