//
//  LevelSelectView.swift
//  MusicTuner
//
//  Level selection grid for Chord Mastery
//  Shows 4 levels with lock/unlock states
//

import SwiftUI

struct LevelSelectView: View {
    @StateObject private var viewModel = ChordMasteryViewModel()
    @ObservedObject var storeManager = StoreKitManager.shared

    /// Dynamic premium threshold — last 2 levels require premium
    private var premiumThreshold: Int { ChordCurriculum.premiumThreshold }

    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Color(hex: "131313").ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    pathHeader
                    pathMap
                        .padding(.top, 40)
                        .padding(.bottom, 40)
                }

                // Banner Ad
                AdBannerContainer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.colorScheme, .dark)
        .toolbarBackground(Color(hex: "131313"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                StreakBadgeView()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear {
            viewModel.loadProgress()
        }
    }

    // MARK: - Path Header

    private var pathHeader: some View {
        VStack(spacing: 8) {
            Text(L("chord_mastery_title"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "E2E2E2"))

            Text(L("chord_mastery_subtitle"))
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(Color(hex: "C8C8AB"))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
        .padding(.top, 24)
    }

    // MARK: - Path Map

    private var currentIndex: Int {
        let levels = ChordCurriculum.levels
        return levels.firstIndex { viewModel.isLevelUnlocked($0) && !viewModel.isLevelCompleted($0) } ?? max(levels.count - 1, 0)
    }

    private var pathMap: some View {
        let levels = ChordCurriculum.levels
        let mapHeight = CGFloat(levels.count) * LearningPath.nodeSpacing

        return GeometryReader { geo in
            ZStack(alignment: .top) {
                if currentIndex > 0 {
                    LearningPathConnector(nodeCount: levels.count, startIndex: 0, endIndex: currentIndex)
                        .stroke(LearningPath.acid.opacity(0.8), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                }
                if currentIndex < levels.count - 1 {
                    LearningPathConnector(nodeCount: levels.count, startIndex: currentIndex, endIndex: levels.count - 1)
                        .stroke(Color(hex: "353534"), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [8, 8]))
                }

                ForEach(Array(levels.enumerated()), id: \.element.id) { index, level in
                    pathNode(level: level, index: index)
                        .position(LearningPath.center(for: index, containerWidth: geo.size.width))
                }
            }
        }
        .frame(height: mapHeight)
    }

    @ViewBuilder
    private func pathNode(level: LevelDefinition, index: Int) -> some View {
        let isCompleted = viewModel.isLevelCompleted(level)
        let isSequenceUnlocked = viewModel.isLevelUnlocked(level)
        let isPremiumLocked = isSequenceUnlocked && level.id >= premiumThreshold && !storeManager.isPremium
        let canAccess = isSequenceUnlocked && !isPremiumLocked

        let state: PathNodeState = isCompleted ? .completed : (canAccess ? .current : .locked)
        let icon: String = isPremiumLocked ? "crown.fill" : (isCompleted ? "checkmark" : (canAccess ? "play.fill" : "lock.fill"))

        Group {
            if canAccess {
                NavigationLink(destination: LearningSessionView(level: level)) {
                    LearningPathNodeView(state: state, icon: icon, startLessonLabel: L("start_lesson"))
                }
            } else if isPremiumLocked {
                Button {
                    showPaywall = true
                } label: {
                    LearningPathNodeView(state: .locked, icon: icon, startLessonLabel: "")
                }
            } else {
                LearningPathNodeView(state: .locked, icon: icon, startLessonLabel: "")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LevelSelectView()
    }
}
