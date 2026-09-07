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

    // MARK: - Feedback Chime
    // Played through this engine (not AudioServicesPlaySystemSound) because
    // .measurement mode disables the system loudness/limiter processing that
    // system sounds rely on, which made them play back very quietly during
    // quizzes. Synthesizing our own buffer controls loudness explicitly.
    private var feedbackPlayer: AVAudioPlayerNode?
    private var feedbackBuffer: AVAudioPCMBuffer?
    
    // MARK: - Configuration
    /// Minimum frequency to detect (filters out noise)
    private var minFrequency: Double = 30.0
    
    /// Maximum frequency to detect
    private var maxFrequency: Double = 1400.0
    
    /// Amplitude threshold (lower = more sensitive)
    private var amplitudeThreshold: Float = 0.008
    
    /// Noise gate: signal must drop below this fraction of threshold to reset
    /// Prevents flicker when signal hovers near threshold boundary
    private let noiseGateHysteresis: Float = 0.4
    
    /// Thread-safe lock for noise gate state (accessed from audio callback + main thread)
    private let noiseGateLock = NSLock()
    
    /// Tracks whether we're currently above the noise gate
    private var _isAboveNoiseGate: Bool = false
    private var isAboveNoiseGate: Bool {
        get { noiseGateLock.withLock { _isAboveNoiseGate } }
        set { noiseGateLock.withLock { _isAboveNoiseGate = newValue } }
    }
    
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
            amplitudeThreshold = 0.008
            pitchDetector.configureForGuitar()
        case .bass:
            // E1 (41Hz) to G3 (196Hz)
            minFrequency = 30.0
            maxFrequency = 250.0
            amplitudeThreshold = 0.006
            pitchDetector.configureForBass()
        case .ukulele:
            // Open strings G4-A4 (392-440Hz) up to the 12th fret A5 (880Hz)
            minFrequency = 200.0
            maxFrequency = 1000.0
            amplitudeThreshold = 0.008
            pitchDetector.minF0 = 200.0
            pitchDetector.maxF0 = 1000.0
            pitchDetector.resetState()
        case .free:
            // Full range
            minFrequency = 27.5  // A0
            maxFrequency = 4000.0
            amplitudeThreshold = 0.008
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
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothA2DP])
            try session.setPreferredSampleRate(44100.0)
            try session.setActive(true)
            
            // Read ACTUAL hardware sample rate (may differ from preferred)
            let actualRate = session.sampleRate
            print("✅ Audio session configured (requested: 44100, actual: \(actualRate)Hz)")
        } catch {
            print("❌ Audio session failed: \(error)")
            throw AudioError.engineCreationFailed
        }
        
        // Create AVAudioEngine
        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else {
            throw AudioError.engineCreationFailed
        }
        
        // Get input node and read actual sample rate
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        sampleRate = format.sampleRate

        // Wire up the feedback chime player on this same engine/session
        let feedback = AVAudioPlayerNode()
        engine.attach(feedback)
        engine.connect(feedback, to: engine.mainMixerNode, format: format)
        feedbackPlayer = feedback
        feedbackBuffer = Self.makeChimeBuffer(format: format)
        
        // Informational only: the tap delivers buffers in the INPUT NODE's
        // format, so that is the source of truth for pitch math. The session
        // rate can legitimately differ (Bluetooth mics, USB interfaces) and
        // must NOT override it, or every detection is scaled off-pitch.
        let sessionRate = AVAudioSession.sharedInstance().sampleRate
        if abs(sampleRate - sessionRate) > 1.0 {
            print("ℹ️ Input runs at \(sampleRate)Hz while session reports \(sessionRate)Hz — using input rate")
        }
        
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
        feedbackPlayer?.stop()
        audioEngine?.stop()
        audioEngine = nil
        feedbackPlayer = nil
        feedbackBuffer = nil

        isRunning = false
        isAboveNoiseGate = false

        // Reset values
        detectedFrequency = 0.0
        detectedNote = nil
        centsDeviation = 0.0
        amplitude = 0.0
        debugRMS = 0.0
        debugRawPitch = 0.0

        // Release the .playAndRecord/.measurement session so whatever plays
        // next (metronome, chord playback) starts from a clean session
        // instead of inheriting this mode's disabled loudness processing.
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("⚠️ AudioManager: failed to deactivate session: \(error)")
        }

        print("🛑 Audio engine stopped")
    }

    /// Plays a short success chime through the engine already running for
    /// pitch detection. See the `feedbackPlayer` doc comment for why this
    /// replaces `AudioServicesPlaySystemSound`.
    func playFeedbackChime() {
        guard let buffer = feedbackBuffer, let player = feedbackPlayer, let engine = audioEngine else {
            AudioServicesPlaySystemSound(1057) // fallback if the engine isn't running
            return
        }
        if !engine.isRunning {
            try? engine.start()
        }
        player.play()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
    }

    /// Synthesizes a short two-tone success chime at an explicit amplitude,
    /// so its loudness doesn't depend on system processing that `.measurement`
    /// mode disables.
    private static func makeChimeBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration = 0.18
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        let tones: [(frequency: Double, start: Double)] = [(880, 0), (1320, 0.06)]
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            var sample = 0.0
            for tone in tones where t >= tone.start {
                let localT = t - tone.start
                let attack = min(1.0, localT / 0.005)
                let envelope = attack * exp(-localT * 14.0)
                sample += sin(2.0 * .pi * tone.frequency * localT) * envelope
            }
            let value = Float(sample * 0.5)
            for channel in 0..<Int(format.channelCount) {
                buffer.floatChannelData?[channel][frame] = value
            }
        }
        return buffer
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
        
        // Detect pitch using the buffer's own sample rate — robust even if the
        // input route (and its rate) changes mid-session, e.g. AirPods connect
        let result = pitchDetector.detectPitch(buffer: bufferArray, sampleRate: buffer.format.sampleRate)
        
        // Update on Main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update debug values
            self.debugRMS = rms
            self.amplitude = rms
            
            // If no pitch detected, reset
            guard let freq = result.frequency, result.confidence > 0.35 else {
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
