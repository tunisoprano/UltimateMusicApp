//
//  TunerView.swift
//  MusicTuner
//
//  Premium GuitarTuna-style tuner interface
//  Layout: Tuning indicator (top) → Note display → Headstock with pegs (bottom)
//

import SwiftUI

/// Main tuner interface — GuitarTuna-inspired premium design
struct TunerView: View {
    @StateObject private var viewModel = TunerViewModel()
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var storeManager = StoreKitManager.shared
    @State private var showDebug = false
    
    var body: some View {
        ZStack {
            // Dark background
            theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content
                VStack(spacing: 0) {
                    // Instrument picker at top
                    instrumentPicker
                        .padding(.top, 8)
                    
                    Spacer(minLength: 12)
                    
                    // Tuning section: indicator + note
                    tuningSection
                    
                    // Headstock fills remaining space
                    if viewModel.selectedInstrument.hasStringTargeting {
                        headstockSection
                    }
                    
                    Spacer(minLength: 0)
                }
                
                // Ad banner at very bottom
                AdBannerContainer()
            }
            
            // Floating mic button (bottom right)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    miniMicButton
                        .padding(.trailing, 24)
                        .padding(.bottom, 70)
                }
            }
            
            // Debug overlay
            #if DEBUG
            if showDebug && viewModel.isListening {
                debugOverlay
            }
            #endif
            
            // Error overlay
            errorView
        }
        .navigationTitle(L("tuner"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.background, for: .navigationBar)
        #if DEBUG
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
        #endif
        .onAppear {
            Task { await viewModel.startListening() }
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }
    
    // MARK: - Instrument Picker
    
    private var instrumentPicker: some View {
        Picker("Instrument", selection: $viewModel.selectedInstrument) {
            ForEach(Instrument.allCases) { inst in
                Text(inst.rawValue).tag(inst)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Tuning Section (Indicator + Note)
    
    private var tuningSection: some View {
        VStack(spacing: 16) {
            // Tuning needle/gauge
            tunerNeedle
            
            // Note display circle
            noteDisplay
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Note Display
    
    private var noteDisplay: some View {
        ZStack {
            // Outer glow when in tune
            if viewModel.tuningState == .inTune {
                Circle()
                    .fill(theme.success.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .blur(radius: 12)
            }
            
            // Note circle
            Circle()
                .fill(theme.cardBackground)
                .frame(width: 100, height: 100)
                .shadow(
                    color: viewModel.tuningState == .inTune
                        ? theme.success.opacity(0.4) : theme.shadow,
                    radius: 10
                )
                .overlay(
                    Circle()
                        .stroke(
                            viewModel.tuningState == .inTune
                                ? theme.success : theme.inactive.opacity(0.3),
                            lineWidth: 3
                        )
                )
            
            // Note text
            if let note = viewModel.detectedNote {
                VStack(spacing: 2) {
                    Text(NoteFormatter.formatLetter(note.name))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                    
                    Text("\(note.octave)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                }
            } else {
                Text("--")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.inactive)
            }
        }
    }
    
    // MARK: - Tuning Needle
    
    private var tunerNeedle: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            let needleOffset = CGFloat(viewModel.needlePosition) * (centerX - 20)
            
            ZStack {
                // Gradient track
                tunerTrack
                
                // Center marker (green)
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
                
                // Flat/Sharp labels
                Text("♭")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(theme.textSecondary.opacity(0.6))
                    .position(x: 14, y: 14)
                
                Text("♯")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(theme.textSecondary.opacity(0.6))
                    .position(x: geo.size.width - 14, y: 14)
                
                // Needle indicator
                needleIndicator
                    .position(x: centerX + needleOffset, y: 14)
                    .animation(.easeInOut(duration: 0.35), value: viewModel.needlePosition)
            }
        }
        .frame(height: 28)
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
    
    // MARK: - Headstock Section (Bottom)
    
    private var headstockSection: some View {
        VStack(spacing: 4) {
            // Mode label
            HStack {
                Text(viewModel.isAutoMode ? "Tap a peg for manual mode" : "Manual: \(viewModel.selectedTargetString?.name ?? "")")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                
                if !viewModel.isAutoMode {
                    Button {
                        viewModel.selectString(nil)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 10))
                            Text("Auto")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(theme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(theme.accent.opacity(0.15))
                        )
                    }
                }
            }
            
            // Headstock — fills available space, flush to bottom
            HeadstockView(
                instrument: viewModel.selectedInstrument,
                strings: viewModel.instrumentStrings,
                selectedString: viewModel.selectedTargetString,
                tunedString: viewModel.tunedString,
                onPegTap: { string in
                    viewModel.toggleStringSelection(string)
                }
            )
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 0)
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
    
    // MARK: - Error View
    
    private var errorView: some View {
        Group {
            if let error = viewModel.errorMessage {
                let isMicDenied = error.localizedCaseInsensitiveContains("denied") ||
                                  error.localizedCaseInsensitiveContains("permission") ||
                                  error.localizedCaseInsensitiveContains("microphone")

                if isMicDenied {
                    // Full-screen mic permission banner
                    VStack(spacing: 20) {
                        Spacer()

                        VStack(spacing: 16) {
                            Image(systemName: "mic.slash.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(theme.error)

                            Text("Microphone Access Required")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(theme.textPrimary)

                            Text("Please allow microphone access in Settings so the tuner can hear your instrument.")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)

                            Button {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Text("Open Settings")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Capsule().fill(theme.accent))
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(theme.cardBackground)
                                .shadow(color: theme.shadow, radius: 16, x: 0, y: 8)
                        )
                        .padding(.horizontal, 24)

                        Spacer()
                    }
                } else {
                    // Generic error toast
                    VStack {
                        Spacer()
                        Text(error)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(theme.error)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 80)
                    }
                }
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
                    
                    Divider().background(theme.textSecondary)
                    
                    Text("CALIBRATION")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(theme.accent)
                    
                    HStack(spacing: 4) {
                        Text("\(String(format: "%+.0f", viewModel.calibrationCents)) ct")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .frame(width: 40, alignment: .trailing)
                        
                        Slider(
                            value: Binding(
                                get: { viewModel.calibrationCents },
                                set: { viewModel.calibrationCents = $0 }
                            ),
                            in: -50...50,
                            step: 1
                        )
                        .frame(width: 100)
                        .tint(theme.accent)
                        
                        Button {
                            viewModel.calibrationCents = 0
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 10))
                                .foregroundStyle(theme.accent)
                        }
                    }
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
    
    // MARK: - Helpers
    
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
