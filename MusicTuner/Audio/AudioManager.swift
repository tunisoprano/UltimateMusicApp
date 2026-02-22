//
//  AudioManager.swift
//  MusicTuner
//
//  Powered by YIN pitch detection algorithm
//  Clean, stable, and thread-safe implementation
//

import Foundation
import AVFoundation

/// Audio Manager with YIN pitch detection
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
    
    // MARK: - User Calibration
    /// User-adjustable calibration in cents, persisted to UserDefaults
    @Published var calibrationCents: Double {
        didSet {
            UserDefaults.standard.set(calibrationCents, forKey: "tunerCalibrationCents")
            pitchDetector.calibrationOffsetCents = calibrationCents
        }
    }
    
    // MARK: - Debug
    @Published private(set) var debugRMS: Float = 0.0
    @Published private(set) var debugRawPitch: Double = 0.0
    
    // MARK: - Audio Components
    private var audioEngine: AVAudioEngine?
    private let pitchDetector = PitchDetector()
    private let bufferSize: UInt32 = 4096
    private var sampleRate: Double = 44100.0
    
    // MARK: - Configuration
    /// Minimum frequency to detect (filters out noise)
    private var minFrequency: Double = 30.0
    
    /// Maximum frequency to detect
    private var maxFrequency: Double = 1400.0
    
    /// Amplitude threshold (lower = more sensitive)
    private var amplitudeThreshold: Float = 0.015
    
    /// Noise gate: signal must drop below this fraction of threshold to reset
    /// Prevents flicker when signal hovers near threshold boundary
    private let noiseGateHysteresis: Float = 0.6
    
    /// Tracks whether we're currently above the noise gate
    private var isAboveNoiseGate: Bool = false
    
    /// Current instrument for optimized detection
    private var currentInstrument: Instrument = .guitar
    
    // MARK: - Initialization
    private init() {
        // Load saved calibration
        let saved = UserDefaults.standard.double(forKey: "tunerCalibrationCents")
        calibrationCents = saved // defaults to 0.0 if never set
        pitchDetector.calibrationOffsetCents = saved
    }
    
    // MARK: - Configuration for Instruments
    
    func configureForInstrument(_ instrument: Instrument) {
        currentInstrument = instrument
        
        switch instrument {
        case .guitar:
            // E2 (82Hz) to E5 (659Hz)
            minFrequency = 70.0
            maxFrequency = 700.0
            amplitudeThreshold = 0.015
            pitchDetector.configureForGuitar()
        case .bass:
            // E1 (41Hz) to G3 (196Hz)
            minFrequency = 30.0
            maxFrequency = 250.0
            amplitudeThreshold = 0.012
            pitchDetector.configureForBass()
        case .ukulele:
            // G4 (392Hz) to A4 (440Hz)
            minFrequency = 200.0
            maxFrequency = 500.0
            amplitudeThreshold = 0.015
            pitchDetector.minF0 = 200.0
            pitchDetector.maxF0 = 500.0
        case .free:
            // Full range
            minFrequency = 27.5  // A0
            maxFrequency = 4000.0
            amplitudeThreshold = 0.015
            pitchDetector.configureForFreeMode()
        }
        
        // Reset noise gate on instrument change
        isAboveNoiseGate = false
        
        print("🎸 Configured for \(instrument.rawValue): \(minFrequency)Hz - \(maxFrequency)Hz [YIN]")
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
        
        // Configure AVAudioSession
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            print("✅ Audio session configured")
        } catch {
            print("❌ Audio session failed: \(error)")
            throw AudioError.engineCreationFailed
        }
        
        // Create AVAudioEngine
        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else {
            throw AudioError.engineCreationFailed
        }
        
        // Get input node
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        sampleRate = format.sampleRate
        
        // Install tap for pitch detection
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        // Start engine
        do {
            try engine.start()
            isRunning = true
            isAboveNoiseGate = false
            print("✅ YIN audio engine started (sample rate: \(sampleRate)Hz)")
        } catch {
            print("❌ Audio engine failed to start: \(error)")
            throw AudioError.engineCreationFailed
        }
    }
    
    @MainActor
    func stop() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        
        isRunning = false
        isAboveNoiseGate = false
        
        // Reset values
        detectedFrequency = 0.0
        detectedNote = nil
        centsDeviation = 0.0
        amplitude = 0.0
        debugRMS = 0.0
        debugRawPitch = 0.0
        
        print("🛑 Audio engine stopped")
    }
    
    // MARK: - Audio Processing (Background Thread)
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Calculate RMS amplitude
        guard let channelData = buffer.floatChannelData else { return }
        let frames = buffer.frameLength
        
        var sum: Float = 0
        for i in 0..<Int(frames) {
            let sample = channelData[0][i]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(frames))
        
        // Noise gate with hysteresis to prevent flicker
        let currentThreshold = amplitudeThreshold
        if isAboveNoiseGate {
            // Already active: only deactivate if signal drops well below threshold
            if rms < currentThreshold * noiseGateHysteresis {
                isAboveNoiseGate = false
            }
        } else {
            // Not active: only activate if signal clearly exceeds threshold
            if rms > currentThreshold {
                isAboveNoiseGate = true
            }
        }
        
        // Skip if below noise gate
        guard isAboveNoiseGate else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.debugRMS = rms
                self.amplitude = rms
                self.debugRawPitch = 0
                self.detectedFrequency = 0.0
                self.detectedNote = nil
                self.centsDeviation = 0.0
            }
            return
        }
        
        // Convert buffer to [Float] array for YIN
        let bufferArray = Array(UnsafeBufferPointer(start: channelData[0], count: Int(frames)))
        
        // Detect pitch using YIN algorithm
        let result = pitchDetector.detectPitch(buffer: bufferArray, sampleRate: sampleRate)
        
        // Update on Main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update debug values
            self.debugRMS = rms
            self.amplitude = rms
            
            // If no pitch detected, reset
            guard let freq = result.frequency, result.confidence > 0.5 else {
                self.debugRawPitch = 0
                self.detectedFrequency = 0.0
                self.detectedNote = nil
                self.centsDeviation = 0.0
                return
            }
            
            self.debugRawPitch = freq
            
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
            if let noteResult = NoteUtility.frequencyToNote(freq) {
                self.detectedNote = noteResult.note
                self.centsDeviation = noteResult.cents
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
