//
//  TempoTrainingView.swift
//  MusicTuner
//
//  Tempo Training game — a hidden random tempo plays continuously, the
//  player dials in their guess on a metronome-style slider, and checks
//  it within a ±5 BPM tolerance. Single round loop, no levels.
//

import SwiftUI

struct TempoTrainingView: View {
    let signatureChoice: TempoSignatureChoice

    @StateObject private var viewModel: TempoTrainingViewModel
    @ObservedObject private var engine: MetronomeEngine

    private let acid = Color(hex: "E1EC00")
    private let wrong = Color(hex: "FF5A5A")

    init(signatureChoice: TempoSignatureChoice) {
        self.signatureChoice = signatureChoice
        let vm = TempoTrainingViewModel()
        _viewModel = StateObject(wrappedValue: vm)
        _engine = ObservedObject(wrappedValue: vm.engine)
    }

    var body: some View {
        ZStack {
            Color(hex: "131313").ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        scoreBadge
                            .padding(.top, 16)

                        beatIndicator

                        Text(L("tempo_training_prompt"))
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(hex: "929277"))

                        feedbackBanner

                        guessDisplay
                        guessSlider

                        QuizCheckButton(
                            title: L("check"),
                            isEnabled: viewModel.lastResult == nil
                        ) {
                            viewModel.submitGuess()
                        }

                        playPauseButton
                            .padding(.top, 4)
                    }
                    .padding(24)
                }

                AdBannerContainer()
            }
        }
        .navigationTitle(L("tempo_training"))
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.colorScheme, .dark)
        .toolbarBackground(Color(hex: "131313"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            viewModel.begin(with: signatureChoice)
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }

    // MARK: - Score Badge

    private var scoreBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(acid)

            Text("\(viewModel.correctCount)/\(viewModel.totalCount)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "E2E2E2"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(Color(hex: "1F1F1F"))
        )
        .overlay(
            Capsule().stroke(Color(hex: "353534"), lineWidth: 1)
        )
    }

    // MARK: - Beat Indicator

    private var beatIndicator: some View {
        HStack(spacing: 14) {
            ForEach(0..<engine.timeSignature.beatsPerMeasure, id: \.self) { beat in
                beatCircle(beat: beat)
            }
        }
        .animation(.easeInOut(duration: 0.08), value: engine.currentBeat)
    }

    private func beatCircle(beat: Int) -> some View {
        let isAccent = beat == 0
        let isActive = engine.isPlaying && engine.currentBeat == beat
        let size: CGFloat = isAccent ? 44 : 34

        return Circle()
            .fill(isActive ? acid : Color(hex: "1F1F1F"))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(isAccent ? acid.opacity(0.6) : Color(hex: "353534"), lineWidth: 2)
            )
            .shadow(color: isActive ? acid.opacity(0.5) : .clear, radius: 10)
            .scaleEffect(isActive ? 1.15 : 1.0)
    }

    // MARK: - Feedback Banner

    @ViewBuilder
    private var feedbackBanner: some View {
        if let result = viewModel.lastResult {
            VStack(spacing: 4) {
                Text(result.isCorrect ? L("correct") : L("tempo_incorrect_feedback"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(result.isCorrect ? acid : wrong)

                Text(L("actual_tempo_format", result.actualBPM))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "929277"))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill((result.isCorrect ? acid : wrong).opacity(0.12))
            )
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        } else {
            Color.clear.frame(height: 1)
        }
    }

    // MARK: - Guess Display

    private var guessDisplay: some View {
        VStack(spacing: 6) {
            Text("\(Int(viewModel.guessBPM))")
                .font(.system(size: 72, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: "E2E2E2"))
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.15), value: Int(viewModel.guessBPM))

            Text(L("your_guess").uppercased())
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(acid)
        }
    }

    // MARK: - Guess Slider

    private var guessSlider: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    viewModel.guessBPM = max(engine.minBPM, viewModel.guessBPM - 5)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Color(hex: "929277"))
                }

                Slider(value: $viewModel.guessBPM, in: engine.minBPM...engine.maxBPM, step: 1)
                    .tint(acid)
                    .disabled(viewModel.lastResult != nil)

                Button {
                    viewModel.guessBPM = min(engine.maxBPM, viewModel.guessBPM + 5)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Color(hex: "929277"))
                }
            }
            .disabled(viewModel.lastResult != nil)
            .opacity(viewModel.lastResult != nil ? 0.5 : 1.0)

            HStack {
                Text("\(Int(engine.minBPM))")
                Spacer()
                Text("\(Int(engine.maxBPM))")
            }
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(Color(hex: "929277"))
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Play / Pause Button

    private var playPauseButton: some View {
        Button {
            viewModel.togglePlayback()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                Text(engine.isPlaying ? L("stop") : L("listen"))
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(Color(hex: "E2E2E2"))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(Color(hex: "1F1F1F"))
            )
            .overlay(
                Capsule().stroke(Color(hex: "353534"), lineWidth: 1)
            )
        }
    }
}

#Preview {
    NavigationStack {
        TempoTrainingView(signatureChoice: .fourFour)
    }
}
