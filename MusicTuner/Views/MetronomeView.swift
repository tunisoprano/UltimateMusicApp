//
//  MetronomeView.swift
//  MusicTuner
//
//  "Playful Premium" metronome — acid/black theme, matches TunerView.
//

import SwiftUI

/// Metronome view with visual feedback and tap tempo — acid/black "Playful Premium" design
struct MetronomeView: View {
    @StateObject private var engine = MetronomeEngine()

    var body: some View {
        ZStack {
            Color(hex: "131313").ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        beatIndicator
                            .padding(.top, 24)

                        bpmDisplay
                        bpmSlider
                        timeSignaturePicker

                        HStack(spacing: 40) {
                            tapTempoButton
                            playButton
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                }

                AdBannerContainer()
            }
        }
        .navigationTitle(L("metronome"))
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.colorScheme, .dark)
        .toolbarBackground(Color(hex: "131313"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onDisappear {
            // CRITICAL: Safe cleanup when leaving view
            engine.cleanup()
        }
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
        let size: CGFloat = isAccent ? 48 : 38
        let acid = Color(hex: "E1EC00")

        return Circle()
            .fill(isActive ? acid : Color(hex: "1F1F1F"))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(isAccent ? acid.opacity(0.6) : Color(hex: "353534"), lineWidth: 2)
            )
            .overlay(
                Image(systemName: isAccent ? "metronome.fill" : "circle.fill")
                    .font(.system(size: isAccent ? 16 : 8, weight: .bold))
                    .foregroundStyle(isActive ? Color(hex: "303300") : Color(hex: "929277"))
                    .opacity(isAccent ? 1 : (isActive ? 1 : 0.5))
            )
            .shadow(color: isActive ? acid.opacity(0.5) : .clear, radius: isActive ? 12 : 0)
            .scaleEffect(isActive ? 1.15 : 1.0)
    }

    // MARK: - BPM Display

    private var bpmDisplay: some View {
        VStack(spacing: 6) {
            Text("\(Int(engine.bpm))")
                .font(.system(size: 72, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: "E2E2E2"))
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.15), value: Int(engine.bpm))

            Text("BPM")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color(hex: "E1EC00"))
        }
    }

    // MARK: - BPM Slider

    private var bpmSlider: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    engine.decreaseBPM()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Color(hex: "929277"))
                }

                Slider(value: $engine.bpm, in: engine.minBPM...engine.maxBPM, step: 1)
                    .tint(Color(hex: "E1EC00"))
                    .onChange(of: engine.bpm) { _, newValue in
                        engine.setBPM(newValue)
                    }

                Button {
                    engine.increaseBPM()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Color(hex: "929277"))
                }
            }

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

    // MARK: - Time Signature

    private var timeSignaturePicker: some View {
        VStack(spacing: 10) {
            Text("Time Signature")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(0.6)
                .foregroundStyle(Color(hex: "929277"))

            HStack(spacing: 8) {
                ForEach(TimeSignature.allCases) { sig in
                    timeSignatureButton(sig)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1F1F1F"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "353534"), lineWidth: 1)
        )
    }

    private func timeSignatureButton(_ sig: TimeSignature) -> some View {
        let isSelected = engine.timeSignature == sig

        return Button {
            engine.timeSignature = sig
        } label: {
            Text(sig.rawValue)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? Color(hex: "303300") : Color(hex: "929277"))
                .frame(width: 46, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color(hex: "E1EC00") : Color(hex: "131313"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.clear : Color(hex: "353534"), lineWidth: 1)
                )
        }
    }

    // MARK: - Tap Tempo Button

    private var tapTempoButton: some View {
        Button {
            engine.tap()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 24, weight: .semibold))
                Text("TAP")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Color(hex: "E2E2E2"))
            .frame(width: 70, height: 70)
            .background(
                Circle()
                    .fill(Color(hex: "1F1F1F"))
                    .overlay(
                        Circle().stroke(Color(hex: "353534"), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(TapButtonStyle())
    }

    // MARK: - Play Button

    private var playButton: some View {
        let acid = Color(hex: "E1EC00")
        let stopColor = Color(hex: "FF5A5A")

        return Button {
            engine.toggle()
        } label: {
            ZStack {
                Circle()
                    .fill(engine.isPlaying ? stopColor : acid)
                    .frame(width: 76, height: 76)
                    .shadow(color: (engine.isPlaying ? stopColor : acid).opacity(0.4), radius: 12, x: 0, y: 6)

                Image(systemName: engine.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color(hex: "131313"))
                    .offset(x: engine.isPlaying ? 0 : 2)
            }
        }
        .animation(.spring(response: 0.3), value: engine.isPlaying)
    }
}

// MARK: - Tap Button Style

struct TapButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        MetronomeView()
    }
}
