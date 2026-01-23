//
//  AudioManager.swift
//  MusicTuner
//
//  Powered by AudioKit v5+
//

import Foundation
import AVFoundation
import AudioKit
import SoundpipeAudioKit

/// AudioKit-based Audio Manager for pitch detection
/// Clean, stable, and thread-safe implementation
final class AudioManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AudioManager()
    
    // MARK: - Published Properties (Main Thread)
    @Published private(set) var isRunning = false
    @Published private(set) var hasPermission = false
    @Published private(set) var detectedFrequency: Double = 0.0
    @Published private(set) var detectedNote: Note?
    @Published private(set) var centsDeviation: Double = 0.0
    @Published private(set) var amplitude: Float = 0.0
    
    // MARK: - Debug
    @Published private(set) var debugRMS: Float = 0.0
    @Published private(set) var debugRawPitch: Double = 0.0
    
    // MARK: - AudioKit Components
    private var engine: AudioEngine?
    private var mic: AudioEngine.InputNode?
    private var pitchTap: PitchTap?
    private var silenceNode: Mixer?
    
    // MARK: - Configuration
    /// Noise gate threshold - below this amplitude, consider silence
    /// Lower threshold for bass to catch quieter low frequencies
    private var noiseGateThreshold: Float = 0.01
    
    /// Minimum frequency to detect (filters out noise)
    /// Bass E1 = 41Hz, so we need to go lower
    private var minFrequency: Double = 30.0
    
    /// Maximum frequency to detect
    private var maxFrequency: Double = 1400.0
    
    /// Current instrument for optimized detection
    private var currentInstrument: Instrument = .guitar
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Configuration for Instruments
    
    func configureForInstrument(_ instrument: Instrument) {
        currentInstrument = instrument
        
        switch instrument {
        case .guitar:
            // E2 (82Hz) to E5 (659Hz)
            minFrequency = 70.0
            maxFrequency = 700.0
            noiseGateThreshold = 0.01
        case .bass:
            // E1 (41Hz) to G3 (196Hz)
            // Lower noise gate for bass - low frequencies have less amplitude
            minFrequency = 30.0
            maxFrequency = 250.0
            noiseGateThreshold = 0.005
        case .ukulele:
            // G4 (392Hz) to A4 (440Hz)
            minFrequency = 200.0
            maxFrequency = 500.0
            noiseGateThreshold = 0.01
        case .free:
            // Full range
            minFrequency = 27.5  // A0
            maxFrequency = 4000.0
            noiseGateThreshold = 0.008
        }
        print("🎸 Configured for \(instrument.rawValue): \(minFrequency)Hz - \(maxFrequency)Hz")
    }
    
    // MARK: - Permission
    
    func requestPermission() async -> Bool {
        let status = AVAudioApplication.shared.recordPermission
        
        switch status {
        case .granted:
            await MainActor.run { self.hasPermission = true }
            return true
        case .denied:
            await MainActor.run { self.hasPermission = false }
            return false
        case .undetermined:
            let granted = await AVAudioApplication.requestRecordPermission()
            await MainActor.run { self.hasPermission = granted }
            return granted
        @unknown default:
            return false
        }
    }
    
    // MARK: - Start/Stop
    
    @MainActor
    func start() async throws {
        // Check permission first
        if !hasPermission {
            guard await requestPermission() else {
                throw AudioError.permissionDenied
            }
        }
        
        guard !isRunning else { return }
        
        // CRITICAL: Configure AVAudioSession BEFORE creating AudioKit engine
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            print("✅ Audio session configured")
        } catch {
            print("❌ Audio session failed: \(error)")
            throw AudioError.engineCreationFailed
        }
        
        // Create AudioKit engine
        engine = AudioEngine()
        guard let engine = engine else {
            throw AudioError.engineCreationFailed
        }
        
        // Get microphone input
        guard let input = engine.input else {
            throw AudioError.inputNodeUnavailable
        }
        mic = input
        
        // Route to silent output (we only analyze, don't playback)
        silenceNode = Mixer([input])
        silenceNode?.volume = 0
        engine.output = silenceNode
        
        // Create PitchTap for pitch detection
        pitchTap = PitchTap(input) { [weak self] frequency, amplitude in
            self?.handlePitchDetection(frequency: frequency, amplitude: amplitude)
        }
        pitchTap?.start()
        
        // Start engine
        do {
            try engine.start()
            isRunning = true
            print("✅ AudioKit engine started")
        } catch {
            print("❌ AudioKit failed to start: \(error)")
            throw AudioError.engineCreationFailed
        }
    }
    
    @MainActor
    func stop() {
        pitchTap?.stop()
        pitchTap = nil
        
        engine?.stop()
        engine = nil
        mic = nil
        silenceNode = nil
        
        isRunning = false
        
        // Reset values
        detectedFrequency = 0.0
        detectedNote = nil
        centsDeviation = 0.0
        amplitude = 0.0
        debugRMS = 0.0
        debugRawPitch = 0.0
        
        print("🛑 AudioKit engine stopped")
    }
    
    // MARK: - Pitch Detection Handler (Background Thread)
    
    private func handlePitchDetection(frequency: [Float], amplitude: [Float]) {
        // PitchTap provides arrays, we use first element
        let freq = Double(frequency[0])
        let amp = amplitude[0]
        
        // Update on Main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update debug values
            self.debugRMS = amp
            self.debugRawPitch = freq
            self.amplitude = amp
            
            // NOISE GATE: If amplitude is too low, treat as silence
            guard amp > self.noiseGateThreshold else {
                self.detectedFrequency = 0.0
                self.detectedNote = nil
                self.centsDeviation = 0.0
                return
            }
            
            // Validate frequency range
            guard freq >= self.minFrequency && freq <= self.maxFrequency else {
                self.detectedFrequency = 0.0
                self.detectedNote = nil
                self.centsDeviation = 0.0
                return
            }
            
            // Update frequency
            self.detectedFrequency = freq
            
            // Convert to note
            if let result = NoteUtility.frequencyToNote(freq) {
                self.detectedNote = result.note
                self.centsDeviation = result.cents
            }
        }
    }
}

// MARK: - Errors

enum AudioError: LocalizedError {
    case permissionDenied
    case engineCreationFailed
    case inputNodeUnavailable
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Microphone permission denied"
        case .engineCreationFailed: return "Failed to start audio engine"
        case .inputNodeUnavailable: return "No audio input available"
        }
    }
}
