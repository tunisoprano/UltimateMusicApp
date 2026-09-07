//
//  ExerciseView.swift
//  MusicTuner
//
//  Level selection for Fretboard Training
//  Instrument picker at top, then level cards
//  Matches LevelSelectView pattern
//

import SwiftUI

/// Fretboard Training level selection
struct ExerciseView: View {
    @StateObject private var viewModel = ExerciseViewModel()
    @ObservedObject var storeManager = StoreKitManager.shared

    /// Dynamic premium threshold — last 2 levels require premium
    private var premiumThreshold: Int { FretboardCurriculum.premiumThreshold }

    @State private var showPaywall = false
    @AppStorage("showLessonPreview") private var showLessonPreview: Bool = true

    var body: some View {
        ZStack {
            Color(hex: "131313").ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    pathHeader
                    instrumentPicker
                        .padding(.top, 20)
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
            Text(L("fb_title"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "E2E2E2"))

            Text(L("fb_subtitle"))
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(Color(hex: "C8C8AB"))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
        .padding(.top, 24)
    }

    // MARK: - Instrument Picker

    private var instrumentPicker: some View {
        VStack(spacing: 12) {
            Text(L("instrument"))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "C8C8AB"))

            Picker("Instrument", selection: $viewModel.selectedInstrument) {
                ForEach(Instrument.exerciseInstruments) { instrument in
                    Text(instrument.rawValue).tag(instrument)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.selectedInstrument) { _, newValue in
                viewModel.selectInstrument(newValue)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                .fill(Color(hex: "1F1F1F"))
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Path Map

    private var currentIndex: Int {
        let levels = FretboardCurriculum.levels
        return levels.firstIndex { viewModel.isLevelUnlocked($0) && !viewModel.isLevelCompleted($0) } ?? max(levels.count - 1, 0)
    }

    private var pathMap: some View {
        let levels = FretboardCurriculum.levels
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
    private func pathNode(level: FretboardLevel, index: Int) -> some View {
        let isCompleted = viewModel.isLevelCompleted(level)
        let isSequenceUnlocked = viewModel.isLevelUnlocked(level)
        let isPremiumLocked = isSequenceUnlocked && level.id >= premiumThreshold && !storeManager.isPremium
        let canAccess = isSequenceUnlocked && !isPremiumLocked

        let state: PathNodeState = isCompleted ? .completed : (canAccess ? .current : .locked)
        let icon: String = isPremiumLocked ? "crown.fill" : (isCompleted ? "checkmark" : (canAccess ? "play.fill" : "lock.fill"))

        Group {
            if canAccess {
                NavigationLink {
                    if showLessonPreview {
                        FretboardLearningView(level: level, instrument: viewModel.selectedInstrument)
                    } else {
                        FretboardQuizView(level: level, instrument: viewModel.selectedInstrument)
                    }
                } label: {
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
        ExerciseView()
    }
}
