//
//  MetronomeEngine.swift
//  MusicTuner
//
//  High-precision metronome engine with safe lifecycle management
//

import Foundation
import AVFoundation

/// Time signature options for metronome
enum TimeSignature: String, CaseIterable, Identifiable {
    case twoFour = "2/4"
    case threeFour = "3/4"
    case fourFour = "4/4"
    case fiveFour = "5/4"
    case sevenEight = "7/8"
    
    var id: String { rawValue }
    
    var beatsPerMeasure: Int {
        switch self {
        case .twoFour: return 2
        case .threeFour: return 3
        case .fourFour: return 4
        case .fiveFour: return 5
        case .sevenEight: return 7
        }
    }
}

/// High-precision metronome engine with safe cleanup
final class MetronomeEngine: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var bpm: Double = 120
    @Published var timeSignature: TimeSignature = .fourFour
    @Published var currentBeat: Int = 0
    
    // MARK: - Audio
    // Clicks are synthesized into PCM buffers and played through AVAudioEngine.
    // This routes correctly (headphones/Bluetooth/speaker), ignores the silent
    // switch like other playback, and needs no bundled sound files.
    private var audioEngine: AVAudioEngine?
    private var clickPlayer: AVAudioPlayerNode?
    private var accentBuffer: AVAudioPCMBuffer?
    private var normalBuffer: AVAudioPCMBuffer?
    
    // MARK: - Timer
    private var timer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "com.musictuner.metronome", qos: .userInteractive)
    private var isTimerActive = false
    
    // MARK: - BPM Range
    let minBPM: Double = 40
    let maxBPM: Double = 220
    
    // MARK: - Tap Tempo
    private var tapTimes: [Date] = []
    private let maxTaps = 4
    private let tapTimeout: TimeInterval = 2.0
    
    // MARK: - Initialization
    
    init() {
        setupAudioPlayers()
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleConfigurationChange),
            name: .AVAudioEngineConfigurationChange, object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        cleanup()
    }

    /// The engine's graph/format changed under us (route change, interruption
    /// recovery). The pre-rendered click buffers target the old format, so
    /// rebuild everything rather than risk silent or mismatched playback.
    @objc private func handleConfigurationChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.audioEngine?.stop()
            self.setupAudioPlayers()
        }
    }

    // MARK: - Audio Setup

    private func setupAudioPlayers() {
        // Configure audio session for playback (follows the system output route)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("⚠️ Metronome audio session failed: \(error)")
        }
        
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        
        let format = engine.outputNode.outputFormat(forBus: 0)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        
        accentBuffer = Self.makeClickBuffer(frequency: 1600, format: format)
        normalBuffer = Self.makeClickBuffer(frequency: 1050, format: format)
        
        do {
            try engine.start()
            player.play()
            audioEngine = engine
            clickPlayer = player
        } catch {
            print("⚠️ Metronome engine failed to start: \(error)")
            audioEngine = nil
            clickPlayer = nil
        }
    }
    
    /// Synthesize a short percussive click: a sine burst with a fast exponential decay
    private static func makeClickBuffer(frequency: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration = 0.030
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            // 1ms attack to avoid a pop, then fast decay
            let attack = min(1.0, t / 0.001)
            let envelope = attack * exp(-t * 90.0)
            let sample = Float(sin(2.0 * .pi * frequency * t) * envelope * 0.85)
            for channel in 0..<Int(format.channelCount) {
                buffer.floatChannelData?[channel][frame] = sample
            }
        }
        return buffer
    }
    
    // MARK: - Control
    
    func start() {
        guard !isPlaying else { return }
        
        isPlaying = true
        currentBeat = 0
        startTimer()
    }
    
    func stop() {
        guard isPlaying else { return }
        
        isPlaying = false
        stopTimer()
        
        DispatchQueue.main.async { [weak self] in
            self?.currentBeat = 0
        }
    }
    
    func toggle() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }
    
    /// Safe cleanup - call this when view disappears
    func cleanup() {
        stopTimer()
        isPlaying = false
        
        // Release audio engine
        clickPlayer?.stop()
        audioEngine?.stop()
        clickPlayer = nil
        audioEngine = nil
        accentBuffer = nil
        normalBuffer = nil
        
        tapTimes.removeAll()
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        stopTimer() // Ensure no existing timer
        
        let interval = 60.0 / bpm
        
        timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer?.schedule(deadline: .now(), repeating: interval)
        
        timer?.setEventHandler { [weak self] in
            guard let self = self, self.isPlaying else { return }
            self.tick()
        }
        
        isTimerActive = true
        timer?.resume()
    }
    
    private func stopTimer() {
        guard isTimerActive, timer != nil else { return }
        
        timer?.cancel()
        timer = nil
        isTimerActive = false
    }
    
    private func tick() {
        let beat = currentBeat
        let beatsPerMeasure = timeSignature.beatsPerMeasure
        
        // Play sound
        if beat == 0 {
            playAccentSound()
        } else {
            playNormalSound()
        }
        
        // Update UI on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isPlaying else { return }
            self.currentBeat = (beat + 1) % beatsPerMeasure
        }
    }
    
    // MARK: - Sounds
    
    private func playAccentSound() {
        playClick(accentBuffer)
    }
    
    private func playNormalSound() {
        playClick(normalBuffer)
    }
    
    private func playClick(_ buffer: AVAudioPCMBuffer?) {
        // Another feature (tuner/fretboard mic) may have left the shared
        // session in .playAndRecord + .measurement, which plays clicks back
        // very quietly. Re-assert playback before every tick.
        ensurePlaybackSession()

        guard let buffer, let player = clickPlayer, let engine = audioEngine else {
            // Last-resort fallback (no engine): system tick
            AudioServicesPlaySystemSound(1103)
            return
        }
        // Recover if the engine was interrupted (phone call, route change)
        if !engine.isRunning {
            try? engine.start()
            player.play()
        }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
    }

    /// Re-assert the playback session if another feature (tuner/fretboard
    /// mic) left the shared session in .playAndRecord + .measurement.
    private func ensurePlaybackSession() {
        let session = AVAudioSession.sharedInstance()
        guard session.category != .playback else { return }
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("⚠️ Metronome: could not restore playback session: \(error)")
        }
    }
    
    // MARK: - BPM Control
    
    func setBPM(_ newBPM: Double) {
        let clampedBPM = max(minBPM, min(maxBPM, newBPM))
        
        guard abs(bpm - clampedBPM) > 0.1 else { return }
        
        bpm = clampedBPM
        
        if isPlaying {
            startTimer() // Restart timer with new interval
        }
    }
    
    func increaseBPM(by amount: Double = 5) {
        setBPM(bpm + amount)
    }
    
    func decreaseBPM(by amount: Double = 5) {
        setBPM(bpm - amount)
    }
    
    // MARK: - Tap Tempo
    
    func tap() {
        let now = Date()
        
        // Remove old taps (timeout)
        tapTimes = tapTimes.filter { now.timeIntervalSince($0) < tapTimeout }
        
        // Add new tap
        tapTimes.append(now)
        
        // Keep only last N taps
        if tapTimes.count > maxTaps {
            tapTimes.removeFirst()
        }
        
        // Need at least 2 taps to calculate BPM
        guard tapTimes.count >= 2 else { return }
        
        // Calculate average interval
        var totalInterval: TimeInterval = 0
        for i in 1..<tapTimes.count {
            totalInterval += tapTimes[i].timeIntervalSince(tapTimes[i-1])
        }
        
        let avgInterval = totalInterval / Double(tapTimes.count - 1)
        
        // Convert to BPM (60 seconds / interval)
        let calculatedBPM = 60.0 / avgInterval
        
        // Apply to metronome
        setBPM(calculatedBPM)
    }
    
    func resetTapTempo() {
        tapTimes.removeAll()
    }
}
