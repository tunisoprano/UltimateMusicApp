//
//  TunerView.swift
//  MusicTuner
//
//  "Playful Premium" tuner — GuitarTuna-inspired, acid/black theme.
//  Layout: instrument pills → tuning meter card → Auto-Detect / Tuning
//  preset cards → vector pegboard.
//

import SwiftUI

/// Main tuner interface — acid/black "Playful Premium" design
struct TunerView: View {
    @StateObject private var viewModel = TunerViewModel()
    @State private var showDebug = false
    @State private var showTuningSheet = false

    var body: some View {
        ZStack {
            Color(hex: "131313").ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        instrumentPicker
                            .padding(.top, 16)

                        tuningMeterCard

                        controlCardsRow

                        if viewModel.selectedInstrument.hasStringTargeting {
                            headstockSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }

                AdBannerContainer()
            }

            #if DEBUG
            if showDebug && viewModel.isListening {
                debugOverlay
            }
            #endif

            errorView
        }
        .navigationTitle(L("tuner"))
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.colorScheme, .dark)
        .toolbarBackground(Color(hex: "131313"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            #if DEBUG
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showDebug.toggle()
                } label: {
                    Image(systemName: showDebug ? "ladybug.fill" : "ladybug")
                        .foregroundStyle(Color(hex: "929277"))
                }
            }
            #endif
            ToolbarItem(placement: .topBarTrailing) {
                StreakBadgeView()
            }
        }
        .sheet(isPresented: $showTuningSheet) {
            tuningPresetSheet
        }
        .onAppear {
            Task { await viewModel.startListening() }
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }

    // MARK: - Instrument Picker (pill segmented)

    private var instrumentPicker: some View {
        HStack(spacing: 8) {
            ForEach(Instrument.allCases) { inst in
                let isActive = viewModel.selectedInstrument == inst

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedInstrument = inst
                    }
                } label: {
                    Text(inst == .free ? L("tuner_chromatic") : inst.rawValue)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(isActive ? Color(hex: "303300") : Color(hex: "C8C8AB"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().fill(isActive ? LearningPath.acid : Color(hex: "1F1F1F"))
                        )
                }
            }
        }
    }

    // MARK: - Tuning Meter Card

    private var tuningMeterCard: some View {
        VStack(spacing: 20) {
            statusPill

            tunerNeedle
                .padding(.horizontal, 8)

            noteDisplay
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "1F1F1F"))
        )
    }

    private var statusPill: some View {
        Text(viewModel.tuningState.description)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(statusTextColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(statusTextColor.opacity(0.15))
            )
    }

    private var statusTextColor: Color {
        switch viewModel.tuningState {
        case .inTune: return LearningPath.acid
        case .close: return Color(hex: "FFC94A")
        case .sharp, .flat: return Color(hex: "FF5A5A")
        case .noSignal: return Color(hex: "929277")
        }
    }

    // MARK: - Note Display

    private var noteDisplay: some View {
        ZStack {
            if viewModel.tuningState == .inTune {
                Circle()
                    .fill(LearningPath.acid.opacity(0.25))
                    .frame(width: 140, height: 140)
                    .blur(radius: 16)
            }

            Circle()
                .fill(Color(hex: "131313"))
                .frame(width: 116, height: 116)
                .overlay(
                    Circle()
                        .stroke(
                            viewModel.tuningState == .inTune
                                ? LearningPath.acid : Color(hex: "353534"),
                            lineWidth: 3
                        )
                )
                .shadow(color: .black.opacity(0.4), radius: 10)

            if let note = viewModel.detectedNote {
                VStack(spacing: 2) {
                    Text(NoteFormatter.formatLetter(note.name))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "E2E2E2"))

                    Text("\(note.octave)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "929277"))
                }
            } else {
                Text("--")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "353534"))
            }
        }
    }

    // MARK: - Tuning Needle

    private var tunerNeedle: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            let needleOffset = CGFloat(viewModel.needlePosition) * (centerX - 20)

            ZStack {
                tunerTrack

                Rectangle()
                    .fill(LearningPath.acid)
                    .frame(width: 3, height: 20)
                    .position(x: centerX, y: 14)

                ForEach([-2, -1, 1, 2], id: \.self) { tick in
                    Rectangle()
                        .fill(Color(hex: "929277").opacity(0.5))
                        .frame(width: 1, height: 10)
                        .position(x: centerX + CGFloat(tick) * (centerX / 2.5), y: 14)
                }

                Text("♭")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(hex: "929277").opacity(0.7))
                    .position(x: 14, y: 14)

                Text("♯")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(hex: "929277").opacity(0.7))
                    .position(x: geo.size.width - 14, y: 14)

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
                            .init(color: Color(hex: "FF5A5A").opacity(0.3), location: 0),
                            .init(color: Color(hex: "FFC94A").opacity(0.3), location: 0.3),
                            .init(color: LearningPath.acid.opacity(0.5), location: 0.5),
                            .init(color: Color(hex: "FFC94A").opacity(0.3), location: 0.7),
                            .init(color: Color(hex: "FF5A5A").opacity(0.3), location: 1)
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
                    .fill(LearningPath.acid.opacity(0.5))
                    .frame(width: 36, height: 36)
                    .blur(radius: 6)
            }

            Circle()
                .fill(statusTextColor)
                .frame(width: 24, height: 24)
                .shadow(color: statusTextColor.opacity(0.5), radius: 4, x: 0, y: 2)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }

    // MARK: - Control Cards (Auto-Detect + Active Tuning)

    private var controlCardsRow: some View {
        HStack(spacing: 12) {
            autoDetectCard

            if viewModel.selectedInstrument.hasStringTargeting {
                activeTuningCard
            }
        }
    }

    private var autoDetectCard: some View {
        Button {
            Task { await viewModel.toggleListening() }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: viewModel.isListening ? "mic.fill" : "mic.slash.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(viewModel.isListening ? LearningPath.acid : Color(hex: "FF5A5A"))
                    Spacer()
                }
                Text(L("tuner_auto_detect"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "E2E2E2"))
                Text(viewModel.isListening ? L("tuner_perfect") : L("tuner_play_a_note"))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Color(hex: "929277"))
                    .lineLimit(1)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "1F1F1F"))
            )
        }
    }

    private var activeTuningCard: some View {
        Button {
            showTuningSheet = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "tuningfork")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: "D5FBFF"))
                    Spacer()
                    Text(L("tuner_change"))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(LearningPath.acid)
                }
                Text(L("tuner_active_tuning"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "E2E2E2"))
                Text(viewModel.selectedPreset.displayName)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Color(hex: "929277"))
                    .lineLimit(1)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "1F1F1F"))
            )
        }
    }

    // MARK: - Tuning Preset Sheet

    private var tuningPresetSheet: some View {
        ZStack {
            Color(hex: "131313").ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text(L("tuner_select_tuning"))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "E2E2E2"))
                    Spacer()
                    Button(L("done")) {
                        showTuningSheet = false
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(LearningPath.acid)
                }
                .padding(20)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(viewModel.availablePresets) { preset in
                            let isActive = viewModel.selectedPreset.id == preset.id

                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    viewModel.selectedPreset = preset
                                }
                                showTuningSheet = false
                            } label: {
                                HStack {
                                    Text(preset.displayName)
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(isActive ? Color(hex: "303300") : Color(hex: "E2E2E2"))
                                    Spacer()
                                    if isActive {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color(hex: "303300"))
                                    }
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(isActive ? LearningPath.acid : Color(hex: "1F1F1F"))
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .environment(\.colorScheme, .dark)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Headstock Section (Pegboard)

    private var headstockSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text(viewModel.isAutoMode ? L("tuner_tap_peg_manual") : L("tuner_manual_mode", viewModel.selectedTargetString?.name ?? ""))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "929277"))

                if !viewModel.isAutoMode {
                    Button {
                        viewModel.selectString(nil)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 10))
                            Text(L("tuner_auto"))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(LearningPath.acid)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(LearningPath.acid.opacity(0.15))
                        )
                    }
                }

                Spacer()
            }

            HeadstockView(
                instrument: viewModel.selectedInstrument,
                strings: viewModel.instrumentStrings,
                selectedString: viewModel.selectedTargetString,
                tunedString: viewModel.tunedString,
                onPegTap: { string in
                    viewModel.toggleStringSelection(string)
                }
            )
            .frame(height: 260)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "1F1F1F"))
        )
    }

    // MARK: - Error View

    private var errorView: some View {
        Group {
            if let error = viewModel.errorMessage {
                let isMicDenied = error.localizedCaseInsensitiveContains("denied") ||
                                  error.localizedCaseInsensitiveContains("permission") ||
                                  error.localizedCaseInsensitiveContains("microphone")

                if isMicDenied {
                    VStack(spacing: 20) {
                        Spacer()

                        VStack(spacing: 16) {
                            Image(systemName: "mic.slash.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(Color(hex: "FF5A5A"))

                            Text(L("mic_access_required"))
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color(hex: "E2E2E2"))

                            Text(L("mic_access_message"))
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(Color(hex: "929277"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)

                            Button {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Text(L("open_settings"))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color(hex: "303300"))
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Capsule().fill(LearningPath.acid))
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(hex: "1F1F1F"))
                                .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
                        )
                        .padding(.horizontal, 24)

                        Spacer()
                    }
                } else {
                    VStack {
                        Spacer()
                        Text(error)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(Color(hex: "FF5A5A"))
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

    #if DEBUG
    private var debugOverlay: some View {
        VStack {
            HStack {
                Spacer()
                VStack(alignment: .leading, spacing: 3) {
                    Text("DEBUG")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(LearningPath.acid)
                    Text("RMS: \(String(format: "%.4f", AudioManager.shared.debugRMS))")
                    Text("Raw: \(String(format: "%.1f", AudioManager.shared.debugRawPitch))")
                    Text("Smooth: \(String(format: "%.1f", viewModel.smoothedCents))")
                    Text("Locked: \(viewModel.isLocked ? "YES" : "NO")")

                    Divider().background(Color(hex: "929277"))

                    Text("CALIBRATION")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(LearningPath.acid)

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
                        .tint(LearningPath.acid)

                        Button {
                            viewModel.calibrationCents = 0
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 10))
                                .foregroundStyle(LearningPath.acid)
                        }
                    }
                }
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color(hex: "929277"))
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "1F1F1F").opacity(0.95))
                )
                .padding(10)
            }
            Spacer()
        }
    }
    #endif
}

#Preview {
    NavigationStack {
        TunerView()
    }
}
