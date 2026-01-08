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
    private var accentPlayer: AVAudioPlayer?
    private var normalPlayer: AVAudioPlayer?
    
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
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Audio Setup
    
    private func setupAudioPlayers() {
        // Configure audio session for playback
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("⚠️ Metronome audio session failed: \(error)")
        }
        
        // Try to load custom sounds
        if let accentURL = Bundle.main.url(forResource: "metronome_accent", withExtension: "wav") {
            accentPlayer = try? AVAudioPlayer(contentsOf: accentURL)
            accentPlayer?.prepareToPlay()
        }
        
        if let normalURL = Bundle.main.url(forResource: "metronome_click", withExtension: "wav") {
            normalPlayer = try? AVAudioPlayer(contentsOf: normalURL)
            normalPlayer?.prepareToPlay()
        }
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
        
        // Release audio players
        accentPlayer?.stop()
        normalPlayer?.stop()
        accentPlayer = nil
        normalPlayer = nil
        
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
        if let player = accentPlayer {
            player.currentTime = 0
            player.play()
        } else {
            AudioServicesPlaySystemSound(1104)
        }
    }
    
    private func playNormalSound() {
        if let player = normalPlayer {
            player.currentTime = 0
            player.play()
        } else {
            AudioServicesPlaySystemSound(1103)
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
