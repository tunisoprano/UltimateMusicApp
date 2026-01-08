//
//  MetronomeView.swift
//  MusicTuner
//
//  Visual metronome with BPM control, beat indicator, and Tap Tempo
//

import SwiftUI

/// Metronome view with visual feedback and tap tempo
struct MetronomeView: View {
    @StateObject private var engine = MetronomeEngine()
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 28) {
                    Spacer()
                    
                    beatIndicator
                    bpmDisplay
                    bpmSlider
                    timeSignaturePicker
                    
                    Spacer()
                    
                    // Tap Tempo & Play buttons
                    HStack(spacing: 40) {
                        tapTempoButton
                        playButton
                    }
                    .padding(.bottom, 20)
                }
                .padding(24)
                
                // Banner Ad at bottom
                AdBannerContainer()
            }
        }
        .navigationTitle("Metronome")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.background, for: .navigationBar)
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
        
        return Circle()
            .fill(isActive ? (isAccent ? theme.accent : theme.success) : theme.cardBackground)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(isAccent ? theme.accent.opacity(0.5) : theme.inactive.opacity(0.3), lineWidth: 2)
            )
            .shadow(color: isActive ? (isAccent ? theme.accent : theme.success).opacity(0.6) : .clear, radius: isActive ? 12 : 0)
            .scaleEffect(isActive ? 1.15 : 1.0)
    }
    
    // MARK: - BPM Display
    
    private var bpmDisplay: some View {
        VStack(spacing: 6) {
            Text("\(Int(engine.bpm))")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.15), value: Int(engine.bpm))
            
            Text("BPM")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textSecondary)
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
                        .foregroundStyle(theme.textSecondary)
                }
                
                Slider(value: $engine.bpm, in: engine.minBPM...engine.maxBPM, step: 1)
                    .tint(theme.accent)
                    .onChange(of: engine.bpm) { _, newValue in
                        engine.setBPM(newValue)
                    }
                
                Button {
                    engine.increaseBPM()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(theme.textSecondary)
                }
            }
            
            HStack {
                Text("\(Int(engine.minBPM))")
                Spacer()
                Text("\(Int(engine.maxBPM))")
            }
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(theme.inactive)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Time Signature
    
    private var timeSignaturePicker: some View {
        VStack(spacing: 10) {
            Text("Time Signature")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textSecondary)
            
            HStack(spacing: 8) {
                ForEach(TimeSignature.allCases) { sig in
                    timeSignatureButton(sig)
                }
            }
        }
        .padding(14)
        .themeCard()
    }
    
    private func timeSignatureButton(_ sig: TimeSignature) -> some View {
        let isSelected = engine.timeSignature == sig
        
        return Button {
            engine.timeSignature = sig
        } label: {
            Text(sig.rawValue)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? .white : theme.textSecondary)
                .frame(width: 46, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? theme.accent : theme.cardBackground)
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
            .foregroundStyle(theme.textPrimary)
            .frame(width: 70, height: 70)
            .background(
                Circle()
                    .fill(theme.cardBackground)
                    .shadow(color: theme.shadow, radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(TapButtonStyle())
    }
    
    // MARK: - Play Button
    
    private var playButton: some View {
        Button {
            engine.toggle()
        } label: {
            ZStack {
                Circle()
                    .fill(engine.isPlaying ? theme.error : theme.accent)
                    .frame(width: 76, height: 76)
                    .shadow(color: (engine.isPlaying ? theme.error : theme.accent).opacity(0.4), radius: 12, x: 0, y: 6)
                
                Image(systemName: engine.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
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
