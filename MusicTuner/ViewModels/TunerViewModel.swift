//
//  TunerViewModel.swift
//  MusicTuner
//
//  Ultra-smooth tuner with exponential smoothing and success lock
//

import Foundation
import SwiftUI
import Combine
import UIKit
import AudioToolbox

/// Enhanced TunerViewModel with ultra-smooth needle and success lock
@MainActor
final class TunerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedInstrument: Instrument = .guitar {
        didSet {
            audioManager.configureForInstrument(selectedInstrument)
            selectedTargetString = nil
            selectedPreset = TuningPreset.presets(for: selectedInstrument).first ?? .standard
            resetSmoothing()
        }
    }
    @Published var isListening = false
    @Published var errorMessage: String?
    @Published var selectedTargetString: InstrumentString? = nil

    /// Currently active alternate tuning (Standard, Drop D, Half-Step Down, ...)
    @Published var selectedPreset: TuningPreset = TuningPreset.presets(for: .guitar).first ?? .standard {
        didSet {
            selectedTargetString = nil
            resetSmoothing()
        }
    }
    
    // Smoothed values for UI (ultra-smooth)
    @Published private(set) var smoothedNeedlePosition: Double = 0
    @Published private(set) var smoothedCents: Double = 0
    
    // Success lock state
    @Published private(set) var isLocked: Bool = false
    
    // MARK: - Audio Manager
    private let audioManager = AudioManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - ULTRA SMOOTH: Adaptive Exponential Smoothing
    // Uses adaptive EWMA: fast response for big changes, ultra-smooth for small changes
    private var ewmaValue: Double = 0
    
    /// Base alpha ranges per instrument (min, max)
    /// Actual alpha is interpolated based on the magnitude of cent change
    private var alphaRange: (min: Double, max: Double) {
        switch selectedInstrument {
        case .bass:
            return (min: 0.08, max: 0.60)  // Extra smooth for bass stability
        case .guitar:
            return (min: 0.10, max: 0.70)  // Balanced
        case .ukulele:
            return (min: 0.12, max: 0.80)  // Fast response for higher frequencies
        case .free:
            return (min: 0.10, max: 0.70)
        }
    }
    
    /// Calculate adaptive alpha based on how much the value changed
    /// Small delta → low alpha (smooth), big delta → high alpha (responsive)
    private func adaptiveAlpha(for delta: Double) -> Double {
        let range = alphaRange
        let absDelta = abs(delta)
        
        // Thresholds for interpolation
        let smallChange: Double = 3.0   // Below this: minimum alpha (ultra-smooth)
        let bigChange: Double = 25.0    // Above this: maximum alpha (fast snap)
        
        if absDelta <= smallChange {
            return range.min
        } else if absDelta >= bigChange {
            return range.max
        } else {
            // Linear interpolation between min and max alpha
            let t = (absDelta - smallChange) / (bigChange - smallChange)
            return range.min + t * (range.max - range.min)
        }
    }
    
    // Additional buffer for stability - larger for bass
    private var centsBuffer: [Double] = []
    /// Buffer size per instrument — larger buffers = more stable readings
    private var bufferSize: Int {
        switch selectedInstrument {
        case .bass: return 7
        case .guitar: return 5
        case .ukulele: return 4
        case .free: return 5
        }
    }
    
    // MARK: - SUCCESS LOCK: Timer-based confirmation
    private let lockThreshold: Double = 3.0      // ±3 cents
    private let lockDuration: TimeInterval = 0.5  // 0.5 seconds in zone to lock
    private var inZoneStartTime: Date? = nil
    private var hasPlayedSuccessSound: Bool = false
    
    // MARK: - Streak Timer (30 seconds active usage)
    private var usageTimer: Timer?
    private var accumulatedUsageTime: TimeInterval = 0
    private let streakUsageThreshold: TimeInterval = 30.0  // 30 seconds
    private var hasMarkedStreakToday = false
    
    // MARK: - Haptic Feedback
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let successHaptic = UINotificationFeedbackGenerator()
    
    // MARK: - Calibration
    
    /// User calibration in cents (-50 to +50), forwarded to AudioManager
    var calibrationCents: Double {
        get { audioManager.calibrationCents }
        set { audioManager.calibrationCents = newValue }
    }
    
    // MARK: - Computed Properties
    
    var detectedNote: Note? {
        audioManager.detectedNote
    }
    
    var detectedFrequency: Double {
        audioManager.detectedFrequency
    }
    
    var signalLevel: Float {
        audioManager.amplitude
    }
    
    var isAutoMode: Bool {
        selectedTargetString == nil
    }
    
    /// Raw cents deviation before smoothing
    private var rawCentsDeviation: Double {
        if let targetString = selectedTargetString, detectedFrequency > 0 {
            return NoteUtility.centsDeviation(from: detectedFrequency, to: targetString.frequency)
        }
        return audioManager.centsDeviation
    }
    
    var tuningState: TuningState {
        guard detectedFrequency > 0 else { return .noSignal }

        // If locked (stable for lockDuration), always in tune
        if isLocked {
            return .inTune
        }

        let absCents = abs(smoothedCents)

        // Show green immediately when within ±lockThreshold cents.
        // The success lock (haptic + sound) fires separately after 0.5 s of stability.
        if absCents <= lockThreshold {
            return .inTune
        } else if absCents <= 15 {
            return .close
        } else {
            return smoothedCents > 0 ? .sharp : .flat
        }
    }
    
    /// Ultra-smooth needle position
    var needlePosition: Double {
        smoothedNeedlePosition
    }
    
    var indicatorColor: Color {
        switch tuningState {
        case .inTune: return ThemeManager.shared.success
        case .close: return ThemeManager.shared.warning
        case .sharp, .flat: return ThemeManager.shared.error
        case .noSignal: return ThemeManager.shared.textSecondary
        }
    }
    
    var instrumentStrings: [InstrumentString] {
        selectedPreset.apply(to: selectedInstrument.strings)
    }

    /// All alternate tunings available for the current instrument
    var availablePresets: [TuningPreset] {
        TuningPreset.presets(for: selectedInstrument)
    }
    
    var closestString: InstrumentString? {
        if let targetString = selectedTargetString {
            return targetString
        }
        
        guard detectedNote != nil else { return nil }
        guard selectedInstrument.hasStringTargeting else { return nil }
        
        return instrumentStrings.min { s1, s2 in
            abs(s1.frequency - detectedFrequency) < abs(s2.frequency - detectedFrequency)
        }
    }
    
    /// The string that's currently in tune (for headstock highlighting)
    var tunedString: InstrumentString? {
        guard isLocked else { return nil }
        return closestString
    }
    
    func isStringInTune(_ string: InstrumentString) -> Bool {
        guard isLocked else { return false }
        
        if let target = selectedTargetString {
            return target.id == string.id
        } else if let closest = closestString {
            return closest.id == string.id
        }
        return false
    }
    
    // MARK: - Initialization
    
    init() {
        hapticGenerator.prepare()
        successHaptic.prepare()
        
        // Subscribe to AudioManager updates
        audioManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.processAudioUpdate()
            }
            .store(in: &cancellables)
        
        audioManager.configureForInstrument(.guitar)
    }
    
    // MARK: - ULTRA SMOOTH: Audio Processing with Adaptive Exponential Smoothing
    
    private func processAudioUpdate() {
        guard detectedFrequency > 0 else {
            // No signal - smoothly return to center
            resetToCenter()
            objectWillChange.send()
            return
        }
        
        let raw = rawCentsDeviation
        
        // Step 1: Add to buffer for initial smoothing
        centsBuffer.append(raw)
        if centsBuffer.count > bufferSize {
            centsBuffer.removeFirst()
        }
        
        // Step 2: Calculate buffer average (pre-filter)
        let bufferAvg = centsBuffer.reduce(0, +) / Double(centsBuffer.count)
        
        // Step 3: Apply ADAPTIVE EWMA
        // Alpha adapts based on how much the value changed:
        //   - Small delta (fine tuning) → low alpha → ultra-smooth needle
        //   - Big delta (new string plucked) → high alpha → snap to new value
        let delta = bufferAvg - ewmaValue
        let alpha = adaptiveAlpha(for: delta)
        ewmaValue = alpha * bufferAvg + (1 - alpha) * ewmaValue
        
        // Step 4: Check for success lock
        checkLockStatus(cents: ewmaValue)
        
        // Step 5: Update published values
        if isLocked {
            // Locked to center
            smoothedCents = 0
            smoothedNeedlePosition = 0
        } else {
            smoothedCents = ewmaValue
            smoothedNeedlePosition = max(-1, min(1, ewmaValue / 50.0))
        }
        
        objectWillChange.send()
    }
    
    // MARK: - SUCCESS LOCK: Timer-based Confirmation
    
    private func checkLockStatus(cents: Double) {
        let isInZone = abs(cents) <= lockThreshold
        
        if isInZone {
            if inZoneStartTime == nil {
                // Just entered the zone - start timer
                inZoneStartTime = Date()
            } else if let startTime = inZoneStartTime {
                // Check if we've been in zone long enough
                let elapsed = Date().timeIntervalSince(startTime)
                
                if elapsed >= lockDuration && !isLocked {
                    // SUCCESS! Lock it
                    triggerSuccessLock()
                }
            }
        } else {
            // Left the zone - reset timer and unlock
            inZoneStartTime = nil
            
            if isLocked {
                isLocked = false
                hasPlayedSuccessSound = false
            }
        }
    }
    
    private func triggerSuccessLock() {
        isLocked = true
        
        // Only play sound/haptic once per lock
        guard !hasPlayedSuccessSound else { return }
        hasPlayedSuccessSound = true
        
        // 1. Play success sound if enabled
        if UserDefaults.standard.object(forKey: "successSoundEnabled") as? Bool ?? true {
            AudioServicesPlaySystemSound(1057)
        }
        
        // 2. Success haptic if enabled
        if UserDefaults.standard.object(forKey: "hapticFeedbackEnabled") as? Bool ?? true {
            successHaptic.notificationOccurred(.success)
        }
        
        print("✅ Tuning locked!")
    }
    
    private func resetToCenter() {
        // Smooth return to center when no signal
        ewmaValue = ewmaValue * 0.9  // Decay towards zero
        
        if abs(ewmaValue) < 0.5 {
            ewmaValue = 0
            centsBuffer.removeAll()
        }
        
        smoothedCents = ewmaValue
        smoothedNeedlePosition = max(-1, min(1, ewmaValue / 50.0))
        
        // Reset lock state
        inZoneStartTime = nil
        isLocked = false
        hasPlayedSuccessSound = false
    }
    
    private func resetSmoothing() {
        centsBuffer.removeAll()
        ewmaValue = 0
        smoothedCents = 0
        smoothedNeedlePosition = 0
        inZoneStartTime = nil
        isLocked = false
        hasPlayedSuccessSound = false
    }
    
    // MARK: - String Selection
    
    func selectString(_ string: InstrumentString?) {
        selectedTargetString = string
        resetSmoothing()
    }
    
    func toggleStringSelection(_ string: InstrumentString) {
        if selectedTargetString?.id == string.id {
            selectedTargetString = nil
        } else {
            selectedTargetString = string
        }
        resetSmoothing()
    }
    
    // MARK: - Actions
    
    func startListening() async {
        errorMessage = nil
        resetSmoothing()
        hapticGenerator.prepare()
        successHaptic.prepare()
        
        do {
            try await audioManager.start()
            isListening = true
            startUsageTimer()
        } catch {
            errorMessage = error.localizedDescription
            isListening = false
        }
    }
    
    func stopListening() {
        audioManager.stop()
        isListening = false
        resetSmoothing()
        stopUsageTimer()
    }
    
    // MARK: - Streak Usage Timer
    
    private func startUsageTimer() {
        // Reset if already marked today
        if StreakManager.shared.hasCompletedToday {
            hasMarkedStreakToday = true
            return
        }
        
        usageTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateUsageTime()
            }
        }
    }
    
    private func stopUsageTimer() {
        usageTimer?.invalidate()
        usageTimer = nil
    }
    
    private func updateUsageTime() {
        guard !hasMarkedStreakToday else { return }
        
        // Only count time when we're detecting a signal
        if detectedFrequency > 0 {
            accumulatedUsageTime += 1.0
            
            if accumulatedUsageTime >= streakUsageThreshold {
                markStreakCompleted()
            }
        }
    }
    
    private func markStreakCompleted() {
        guard !hasMarkedStreakToday else { return }
        
        hasMarkedStreakToday = true
        StreakManager.shared.markDailyActivity()
        stopUsageTimer()
        
        print("🔥 Tuner streak marked after 30s usage")
    }
    
    func toggleListening() async {
        if isListening {
            stopListening()
        } else {
            await startListening()
        }
    }
}

// MARK: - Tuning State

enum TuningState {
    case noSignal, flat, sharp, close, inTune
    
    var description: String {
        switch self {
        case .noSignal: return L("tuner_play_a_note")
        case .flat: return L("tuner_too_low")
        case .sharp: return L("tuner_too_high")
        case .close: return L("tuner_almost")
        case .inTune: return L("tuner_perfect")
        }
    }
}
