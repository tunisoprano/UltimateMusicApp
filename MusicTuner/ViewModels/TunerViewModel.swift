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
            resetSmoothing()
        }
    }
    @Published var isListening = false
    @Published var errorMessage: String?
    @Published var selectedTargetString: InstrumentString? = nil
    
    // Smoothed values for UI (ultra-smooth)
    @Published private(set) var smoothedNeedlePosition: Double = 0
    @Published private(set) var smoothedCents: Double = 0
    
    // Success lock state
    @Published private(set) var isLocked: Bool = false
    
    // MARK: - Audio Manager
    private let audioManager = AudioManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - ULTRA SMOOTH: Exponential Smoothing
    // Uses exponential weighted moving average (EWMA) for buttery smooth movement
    private var ewmaValue: Double = 0
    
    // Dynamic smoothing based on instrument
    // Bass needs more smoothing (lower alpha) due to slower string vibration
    private var smoothingAlpha: Double {
        switch selectedInstrument {
        case .bass:
            return 0.05  // More smoothing for bass stability
        case .guitar:
            return 0.08  // Standard smoothing
        case .ukulele:
            return 0.10  // Faster response for higher frequencies
        case .free:
            return 0.08
        }
    }
    
    // Additional buffer for stability - larger for bass
    private var centsBuffer: [Double] = []
    private var bufferSize: Int {
        selectedInstrument == .bass ? 8 : 5  // Larger buffer for bass
    }
    
    // MARK: - SUCCESS LOCK: Timer-based confirmation
    private let lockThreshold: Double = 3.0      // ±3 cents
    private let lockDuration: TimeInterval = 0.5  // 0.5 seconds in zone to lock
    private var inZoneStartTime: Date? = nil
    private var hasPlayedSuccessSound: Bool = false
    
    // MARK: - Haptic Feedback
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let successHaptic = UINotificationFeedbackGenerator()
    
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
        
        // If locked, always return inTune
        if isLocked {
            return .inTune
        }
        
        let absCents = abs(smoothedCents)
        
        if absCents <= lockThreshold {
            return .close  // Not yet locked, but close
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
        selectedInstrument.strings
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
    
    // MARK: - ULTRA SMOOTH: Audio Processing with Exponential Smoothing
    
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
        
        // Step 2: Calculate buffer average
        let bufferAvg = centsBuffer.reduce(0, +) / Double(centsBuffer.count)
        
        // Step 3: Apply EWMA (Exponential Weighted Moving Average)
        // Formula: EWMA_new = α * value + (1 - α) * EWMA_old
        ewmaValue = smoothingAlpha * bufferAvg + (1 - smoothingAlpha) * ewmaValue
        
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
        } catch {
            errorMessage = error.localizedDescription
            isListening = false
        }
    }
    
    func stopListening() {
        audioManager.stop()
        isListening = false
        resetSmoothing()
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
        case .noSignal: return "Play a note"
        case .flat: return "Too Low ↓"
        case .sharp: return "Too High ↑"
        case .close: return "Almost!"
        case .inTune: return "Perfect! ✓"
        }
    }
}
