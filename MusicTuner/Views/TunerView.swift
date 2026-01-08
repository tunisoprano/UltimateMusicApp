//
//  TunerView.swift
//  MusicTuner
//
//  Premium tuner interface with auto-start microphone
//

import SwiftUI

/// Main tuner interface with headstock and smooth needle
struct TunerView: View {
    @StateObject private var viewModel = TunerViewModel()
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var storeManager = StoreKitManager.shared
    @State private var showDebug = false
    
    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        instrumentPicker
                        
                        if viewModel.selectedInstrument.hasStringTargeting {
                            headstockSection
                        }
                        
                        tunerDisplay
                        errorView
                    }
                    .padding(.vertical, 16)
                }
                
                AdBannerContainer()
            }
            
            // Mini mic button (bottom right)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    miniMicButton
                        .padding(.trailing, 24)
                        .padding(.bottom, 70) // Above banner
                }
            }
            
            if showDebug && viewModel.isListening {
                debugOverlay
            }
        }
        .navigationTitle("Tuner")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.background, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showDebug.toggle()
                } label: {
                    Image(systemName: showDebug ? "ladybug.fill" : "ladybug")
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
        .onAppear {
            // Auto-start microphone when entering tuner
            Task {
                await viewModel.startListening()
            }
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }
    
    // MARK: - Mini Mic Button
    
    private var miniMicButton: some View {
        Button {
            Task { await viewModel.toggleListening() }
        } label: {
            Image(systemName: viewModel.isListening ? "mic.fill" : "mic.slash.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(viewModel.isListening ? theme.success : theme.error)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                )
        }
    }
    
    // MARK: - Instrument Picker
    
    private var instrumentPicker: some View {
        VStack(spacing: 10) {
            Picker("Instrument", selection: $viewModel.selectedInstrument) {
                ForEach(Instrument.allCases) { inst in
                    Text(inst.rawValue).tag(inst)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Headstock Section
    
    private var headstockSection: some View {
        VStack(spacing: 12) {
            Text(viewModel.isAutoMode ? "Tap a peg for manual mode" : "Manual: \(viewModel.selectedTargetString?.name ?? "")")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textSecondary)
            
            HeadstockView(
                instrument: viewModel.selectedInstrument,
                strings: viewModel.instrumentStrings,
                selectedString: viewModel.selectedTargetString,
                tunedString: viewModel.tunedString,
                onPegTap: { string in
                    viewModel.toggleStringSelection(string)
                }
            )
            .frame(height: headstockHeight)
            .padding(.horizontal, 40)
            
            // Auto mode button
            if !viewModel.isAutoMode {
                Button {
                    viewModel.selectString(nil)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12))
                        Text("Auto Detect")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(theme.accent.opacity(0.15))
                    )
                }
            }
        }
        .padding(16)
        .themeCard()
        .padding(.horizontal, 20)
    }
    
    private var headstockHeight: CGFloat {
        switch viewModel.selectedInstrument {
        case .guitar: return 180
        case .bass: return 200
        case .ukulele: return 140
        case .free: return 0
        }
    }
    
    // MARK: - Tuner Display
    
    private var tunerDisplay: some View {
        VStack(spacing: 16) {
            noteDisplay
            tunerNeedle
            frequencyAndStatus
        }
        .frame(minHeight: 280)
        .padding(20)
        .themeCard()
        .padding(.horizontal, 20)
        .animation(nil, value: viewModel.tuningState)
    }
    
    private var noteDisplay: some View {
        ZStack {
            // Outer glow when in tune
            if viewModel.tuningState == .inTune {
                Circle()
                    .fill(theme.success.opacity(0.2))
                    .frame(width: 130, height: 130)
                    .blur(radius: 10)
            }
            
            Circle()
                .fill(theme.cardBackground)
                .frame(width: 110, height: 110)
                .shadow(color: viewModel.tuningState == .inTune ? theme.success.opacity(0.4) : theme.shadow, radius: 10)
                .overlay(
                    Circle()
                        .stroke(
                            viewModel.tuningState == .inTune ? theme.success : theme.inactive.opacity(0.3),
                            lineWidth: 3
                        )
                )
            
            if let note = viewModel.detectedNote {
                VStack(spacing: 2) {
                    Text(NoteFormatter.formatLetter(note.name))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                    
                    Text("\(note.octave)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                }
            } else {
                Text("--")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.inactive)
            }
        }
    }
    
    // MARK: - Smooth Needle
    
    private var tunerNeedle: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            let needleOffset = CGFloat(viewModel.needlePosition) * (centerX - 20)
            
            ZStack {
                // Background track
                tunerTrack
                
                // Center marker
                Rectangle()
                    .fill(theme.success)
                    .frame(width: 3, height: 20)
                    .position(x: centerX, y: 14)
                
                // Tick marks
                ForEach([-2, -1, 1, 2], id: \.self) { tick in
                    Rectangle()
                        .fill(theme.inactive.opacity(0.5))
                        .frame(width: 1, height: 10)
                        .position(x: centerX + CGFloat(tick) * (centerX / 2.5), y: 14)
                }
                
                // Needle indicator
                needleIndicator
                    .position(x: centerX + needleOffset, y: 14)
                    .animation(.easeInOut(duration: 0.35), value: viewModel.needlePosition)
            }
        }
        .frame(height: 28)
        .padding(.horizontal, 16)
    }
    
    private var tunerTrack: some View {
        GeometryReader { geo in
            Capsule()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: theme.error.opacity(0.3), location: 0),
                            .init(color: theme.warning.opacity(0.3), location: 0.3),
                            .init(color: theme.success.opacity(0.5), location: 0.5),
                            .init(color: theme.warning.opacity(0.3), location: 0.7),
                            .init(color: theme.error.opacity(0.3), location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 8)
                .position(x: geo.size.width / 2, y: 14)
        }
    }
    
    private var needleIndicator: some View {
        ZStack {
            // Glow
            if viewModel.tuningState == .inTune {
                Circle()
                    .fill(theme.success.opacity(0.5))
                    .frame(width: 36, height: 36)
                    .blur(radius: 6)
            }
            
            Circle()
                .fill(stateColor)
                .frame(width: 24, height: 24)
                .shadow(color: stateColor.opacity(0.5), radius: 4, x: 0, y: 2)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private var frequencyAndStatus: some View {
        VStack(spacing: 8) {
            if viewModel.detectedFrequency > 0 {
                Text(String(format: "%.1f Hz", viewModel.detectedFrequency))
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(theme.textSecondary)
            } else {
                Text("-- Hz")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(theme.inactive)
            }
            
            Text(viewModel.tuningState.description)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(stateColor)
        }
        .frame(height: 60) // Fixed height to prevent jumping
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        Group {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(theme.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Debug Overlay
    
    private var debugOverlay: some View {
        VStack {
            HStack {
                Spacer()
                VStack(alignment: .leading, spacing: 3) {
                    Text("DEBUG")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(theme.accent)
                    Text("RMS: \(String(format: "%.4f", AudioManager.shared.debugRMS))")
                    Text("Raw: \(String(format: "%.1f", AudioManager.shared.debugRawPitch))")
                    Text("Smooth: \(String(format: "%.1f", viewModel.smoothedCents))")
                    Text("Locked: \(viewModel.isLocked ? "YES" : "NO")")
                }
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(theme.textSecondary)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.cardBackground.opacity(0.95))
                )
                .padding(10)
            }
            Spacer()
        }
    }
    
    private var stateColor: Color {
        switch viewModel.tuningState {
        case .inTune: return theme.success
        case .close: return theme.warning
        case .sharp, .flat: return theme.error
        case .noSignal: return theme.inactive
        }
    }
}

#Preview {
    NavigationStack {
        TunerView()
    }
}
