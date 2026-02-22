//
//  StreakBadgeView.swift
//  MusicTuner
//
//  Fire icon + streak count badge for gamification
//

import SwiftUI

/// Compact streak badge showing fire icon and current streak count
struct StreakBadgeView: View {
    @ObservedObject var streakManager = StreakManager.shared
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 4) {
            Text("🔥")
                .font(.system(size: 16))
            
            Text("\(streakManager.currentStreak)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(streakManager.currentStreak > 0 ? theme.warning : theme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(theme.cardBackground)
                .shadow(color: theme.shadow, radius: 4)
        )
    }
}

#Preview {
    StreakBadgeView()
}
