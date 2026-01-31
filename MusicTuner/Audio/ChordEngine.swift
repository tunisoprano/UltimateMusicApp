//
//  ChordEngine.swift
//  MusicTuner
//
//  Professional guitar sampling engine with AudioKit
//  Supports arpeggiated chord playback and dynamic chord diagrams
//
//  IMPORTANT: Guitar.sf2 Setup
//  ----------------------------
//  1. Drag "Guitar.sf2" file into the MusicTuner folder in Xcode
//  2. Make sure "Copy items if needed" is checked
//  3. Verify it's added to Target -> Build Phases -> Copy Bundle Resources
//  4. If the file is missing, the engine will use a fallback synth sound
//

import Foundation
import AVFoundation
import AudioKit
import SoundpipeAudioKit

// MARK: - Chord Type

enum ChordType: String, CaseIterable, Identifiable {
    case major = "Major"
    case minor = "Minor"
    case seventh = "7th"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .major: return String(localized: "major")
        case .minor: return String(localized: "minor")
        case .seventh: return String(localized: "seventh")
        }
    }
    
    var suffix: String {
        switch self {
        case .major: return ""
        case .minor: return "m"
        case .seventh: return "7"
        }
    }
}

// MARK: - Root Note

enum RootNote: String, CaseIterable, Identifiable {
    case C, Csharp, D, Dsharp, E, F, Fsharp, G, Gsharp, A, Asharp, B
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .C: return "C"
        case .Csharp: return "C#"
        case .D: return "D"
        case .Dsharp: return "D#"
        case .E: return "E"
        case .F: return "F"
        case .Fsharp: return "F#"
        case .G: return "G"
        case .Gsharp: return "G#"
        case .A: return "A"
        case .Asharp: return "A#"
        case .B: return "B"
        }
    }
}

// MARK: - Unified Chord Definition

/// Unified chord model for both audio playback and visual diagram rendering
struct ChordDefinition: Identifiable, Equatable, Hashable {
    let id = UUID()
    let rootNote: RootNote
    let type: ChordType
    let midiNotes: [UInt8]
    
    /// Fret positions for 6 strings (E A D G B e). nil = muted string, 0 = open string
    let fretPositions: [Int?]
    
    /// Starting fret for diagram display (1 for open chords, higher for barre chords)
    let startFret: Int
    
    /// Finger positions (0 = not pressed, 1-4 = finger number)
    let fingerPositions: [Int]
    
    /// Which finger creates the barre (nil if no barre)
    let barreInfo: BarreInfo?
    
    var name: String {
        rootNote.displayName + type.suffix
    }
    
    var displayName: String {
        "\(rootNote.displayName) \(type.localizedName)"
    }
    
    static func == (lhs: ChordDefinition, rhs: ChordDefinition) -> Bool {
        lhs.rootNote == rhs.rootNote && lhs.type == rhs.type
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(rootNote)
        hasher.combine(type)
    }
}

// MARK: - Barre Info

struct BarreInfo: Equatable, Hashable {
    let fret: Int
    let fromString: Int  // 0 = low E
    let toString: Int    // 5 = high e
}

// MARK: - Chord Database

/// Comprehensive database of guitar chords with MIDI mappings and diagram data
struct ChordDatabase {
    
    // MARK: - Major Chords
    
    static let majorChords: [ChordDefinition] = [
        // C Major - Open Position
        ChordDefinition(
            rootNote: .C, type: .major,
            midiNotes: [48, 52, 55, 60, 64],
            fretPositions: [nil, 3, 2, 0, 1, 0],
            startFret: 1,
            fingerPositions: [0, 3, 2, 0, 1, 0],
            barreInfo: nil
        ),
        // C# Major - Barre
        ChordDefinition(
            rootNote: .Csharp, type: .major,
            midiNotes: [49, 53, 56, 61, 65],
            fretPositions: [nil, 4, 3, 1, 2, 1],
            startFret: 1,
            fingerPositions: [0, 4, 3, 1, 2, 1],
            barreInfo: BarreInfo(fret: 1, fromString: 3, toString: 5)
        ),
        // D Major - Open Position
        ChordDefinition(
            rootNote: .D, type: .major,
            midiNotes: [50, 57, 62, 66],
            fretPositions: [nil, nil, 0, 2, 3, 2],
            startFret: 1,
            fingerPositions: [0, 0, 0, 1, 3, 2],
            barreInfo: nil
        ),
        // D# Major - Barre
        ChordDefinition(
            rootNote: .Dsharp, type: .major,
            midiNotes: [51, 58, 63, 67],
            fretPositions: [nil, nil, 1, 3, 4, 3],
            startFret: 1,
            fingerPositions: [0, 0, 1, 2, 4, 3],
            barreInfo: nil
        ),
        // E Major - Open Position
        ChordDefinition(
            rootNote: .E, type: .major,
            midiNotes: [40, 47, 52, 56, 59, 64],
            fretPositions: [0, 2, 2, 1, 0, 0],
            startFret: 1,
            fingerPositions: [0, 2, 3, 1, 0, 0],
            barreInfo: nil
        ),
        // F Major - Barre
        ChordDefinition(
            rootNote: .F, type: .major,
            midiNotes: [41, 48, 53, 57, 60, 65],
            fretPositions: [1, 3, 3, 2, 1, 1],
            startFret: 1,
            fingerPositions: [1, 3, 4, 2, 1, 1],
            barreInfo: BarreInfo(fret: 1, fromString: 0, toString: 5)
        ),
        // F# Major - Barre
        ChordDefinition(
            rootNote: .Fsharp, type: .major,
            midiNotes: [42, 49, 54, 58, 61, 66],
            fretPositions: [2, 4, 4, 3, 2, 2],
            startFret: 2,
            fingerPositions: [1, 3, 4, 2, 1, 1],
            barreInfo: BarreInfo(fret: 2, fromString: 0, toString: 5)
        ),
        // G Major - Open Position
        ChordDefinition(
            rootNote: .G, type: .major,
            midiNotes: [43, 47, 50, 55, 59, 67],
            fretPositions: [3, 2, 0, 0, 0, 3],
            startFret: 1,
            fingerPositions: [2, 1, 0, 0, 0, 3],
            barreInfo: nil
        ),
        // G# Major - Barre
        ChordDefinition(
            rootNote: .Gsharp, type: .major,
            midiNotes: [44, 48, 51, 56, 60, 68],
            fretPositions: [4, 3, 1, 1, 1, 4],
            startFret: 1,
            fingerPositions: [3, 2, 1, 1, 1, 4],
            barreInfo: BarreInfo(fret: 1, fromString: 2, toString: 4)
        ),
        // A Major - Open Position
        ChordDefinition(
            rootNote: .A, type: .major,
            midiNotes: [45, 52, 57, 61, 64],
            fretPositions: [nil, 0, 2, 2, 2, 0],
            startFret: 1,
            fingerPositions: [0, 0, 2, 1, 3, 0],
            barreInfo: nil
        ),
        // A# Major - Barre
        ChordDefinition(
            rootNote: .Asharp, type: .major,
            midiNotes: [46, 53, 58, 62, 65],
            fretPositions: [nil, 1, 3, 3, 3, 1],
            startFret: 1,
            fingerPositions: [0, 1, 3, 3, 3, 1],
            barreInfo: BarreInfo(fret: 1, fromString: 1, toString: 5)
        ),
        // B Major - Barre
        ChordDefinition(
            rootNote: .B, type: .major,
            midiNotes: [47, 54, 59, 63, 66],
            fretPositions: [nil, 2, 4, 4, 4, 2],
            startFret: 2,
            fingerPositions: [0, 1, 3, 3, 3, 1],
            barreInfo: BarreInfo(fret: 2, fromString: 1, toString: 5)
        )
    ]
    
    // MARK: - Minor Chords
    
    static let minorChords: [ChordDefinition] = [
        // Cm - Barre
        ChordDefinition(
            rootNote: .C, type: .minor,
            midiNotes: [48, 51, 55, 60, 63],
            fretPositions: [nil, 3, 1, 0, 1, 0],
            startFret: 1,
            fingerPositions: [0, 3, 1, 0, 2, 0],
            barreInfo: nil
        ),
        // C#m - Barre
        ChordDefinition(
            rootNote: .Csharp, type: .minor,
            midiNotes: [49, 52, 56, 61, 64],
            fretPositions: [nil, 4, 2, 1, 2, 0],
            startFret: 1,
            fingerPositions: [0, 4, 2, 1, 3, 0],
            barreInfo: nil
        ),
        // Dm - Open Position
        ChordDefinition(
            rootNote: .D, type: .minor,
            midiNotes: [50, 57, 62, 65],
            fretPositions: [nil, nil, 0, 2, 3, 1],
            startFret: 1,
            fingerPositions: [0, 0, 0, 2, 3, 1],
            barreInfo: nil
        ),
        // D#m - Barre
        ChordDefinition(
            rootNote: .Dsharp, type: .minor,
            midiNotes: [51, 58, 63, 66],
            fretPositions: [nil, nil, 1, 3, 4, 2],
            startFret: 1,
            fingerPositions: [0, 0, 1, 3, 4, 2],
            barreInfo: nil
        ),
        // Em - Open Position
        ChordDefinition(
            rootNote: .E, type: .minor,
            midiNotes: [40, 47, 52, 55, 59, 64],
            fretPositions: [0, 2, 2, 0, 0, 0],
            startFret: 1,
            fingerPositions: [0, 2, 3, 0, 0, 0],
            barreInfo: nil
        ),
        // Fm - Barre
        ChordDefinition(
            rootNote: .F, type: .minor,
            midiNotes: [41, 48, 53, 56, 60, 65],
            fretPositions: [1, 3, 3, 1, 1, 1],
            startFret: 1,
            fingerPositions: [1, 3, 4, 1, 1, 1],
            barreInfo: BarreInfo(fret: 1, fromString: 0, toString: 5)
        ),
        // F#m - Barre
        ChordDefinition(
            rootNote: .Fsharp, type: .minor,
            midiNotes: [42, 49, 54, 57, 61, 66],
            fretPositions: [2, 4, 4, 2, 2, 2],
            startFret: 2,
            fingerPositions: [1, 3, 4, 1, 1, 1],
            barreInfo: BarreInfo(fret: 2, fromString: 0, toString: 5)
        ),
        // Gm - Barre
        ChordDefinition(
            rootNote: .G, type: .minor,
            midiNotes: [43, 50, 55, 58, 62, 67],
            fretPositions: [3, 5, 5, 3, 3, 3],
            startFret: 3,
            fingerPositions: [1, 3, 4, 1, 1, 1],
            barreInfo: BarreInfo(fret: 3, fromString: 0, toString: 5)
        ),
        // G#m - Barre
        ChordDefinition(
            rootNote: .Gsharp, type: .minor,
            midiNotes: [44, 51, 56, 59, 63, 68],
            fretPositions: [4, 6, 6, 4, 4, 4],
            startFret: 4,
            fingerPositions: [1, 3, 4, 1, 1, 1],
            barreInfo: BarreInfo(fret: 4, fromString: 0, toString: 5)
        ),
        // Am - Open Position
        ChordDefinition(
            rootNote: .A, type: .minor,
            midiNotes: [45, 52, 57, 60, 64],
            fretPositions: [nil, 0, 2, 2, 1, 0],
            startFret: 1,
            fingerPositions: [0, 0, 2, 3, 1, 0],
            barreInfo: nil
        ),
        // A#m - Barre
        ChordDefinition(
            rootNote: .Asharp, type: .minor,
            midiNotes: [46, 53, 58, 61, 65],
            fretPositions: [nil, 1, 3, 3, 2, 1],
            startFret: 1,
            fingerPositions: [0, 1, 3, 4, 2, 1],
            barreInfo: BarreInfo(fret: 1, fromString: 1, toString: 5)
        ),
        // Bm - Barre
        ChordDefinition(
            rootNote: .B, type: .minor,
            midiNotes: [47, 54, 59, 62, 66],
            fretPositions: [nil, 2, 4, 4, 3, 2],
            startFret: 2,
            fingerPositions: [0, 1, 3, 4, 2, 1],
            barreInfo: BarreInfo(fret: 2, fromString: 1, toString: 5)
        )
    ]
    
    // MARK: - Seventh Chords
    
    static let seventhChords: [ChordDefinition] = [
        // C7
        ChordDefinition(
            rootNote: .C, type: .seventh,
            midiNotes: [48, 52, 55, 58, 64],
            fretPositions: [nil, 3, 2, 3, 1, 0],
            startFret: 1,
            fingerPositions: [0, 3, 2, 4, 1, 0],
            barreInfo: nil
        ),
        // C#7
        ChordDefinition(
            rootNote: .Csharp, type: .seventh,
            midiNotes: [49, 53, 56, 59, 65],
            fretPositions: [nil, 4, 3, 4, 2, 0],
            startFret: 1,
            fingerPositions: [0, 3, 2, 4, 1, 0],
            barreInfo: nil
        ),
        // D7
        ChordDefinition(
            rootNote: .D, type: .seventh,
            midiNotes: [50, 57, 60, 66],
            fretPositions: [nil, nil, 0, 2, 1, 2],
            startFret: 1,
            fingerPositions: [0, 0, 0, 2, 1, 3],
            barreInfo: nil
        ),
        // D#7
        ChordDefinition(
            rootNote: .Dsharp, type: .seventh,
            midiNotes: [51, 58, 61, 67],
            fretPositions: [nil, nil, 1, 3, 2, 3],
            startFret: 1,
            fingerPositions: [0, 0, 1, 3, 2, 4],
            barreInfo: nil
        ),
        // E7 - Open Position
        ChordDefinition(
            rootNote: .E, type: .seventh,
            midiNotes: [40, 47, 50, 56, 59, 64],
            fretPositions: [0, 2, 0, 1, 0, 0],
            startFret: 1,
            fingerPositions: [0, 2, 0, 1, 0, 0],
            barreInfo: nil
        ),
        // F7
        ChordDefinition(
            rootNote: .F, type: .seventh,
            midiNotes: [41, 48, 51, 57, 60, 65],
            fretPositions: [1, 3, 1, 2, 1, 1],
            startFret: 1,
            fingerPositions: [1, 3, 1, 2, 1, 1],
            barreInfo: BarreInfo(fret: 1, fromString: 0, toString: 5)
        ),
        // F#7
        ChordDefinition(
            rootNote: .Fsharp, type: .seventh,
            midiNotes: [42, 49, 52, 58, 61, 66],
            fretPositions: [2, 4, 2, 3, 2, 2],
            startFret: 2,
            fingerPositions: [1, 3, 1, 2, 1, 1],
            barreInfo: BarreInfo(fret: 2, fromString: 0, toString: 5)
        ),
        // G7 - Open Position
        ChordDefinition(
            rootNote: .G, type: .seventh,
            midiNotes: [43, 47, 50, 53, 59, 67],
            fretPositions: [3, 2, 0, 0, 0, 1],
            startFret: 1,
            fingerPositions: [3, 2, 0, 0, 0, 1],
            barreInfo: nil
        ),
        // G#7
        ChordDefinition(
            rootNote: .Gsharp, type: .seventh,
            midiNotes: [44, 48, 51, 54, 60, 68],
            fretPositions: [4, 3, 1, 1, 1, 2],
            startFret: 1,
            fingerPositions: [4, 3, 1, 1, 1, 2],
            barreInfo: BarreInfo(fret: 1, fromString: 2, toString: 4)
        ),
        // A7 - Open Position
        ChordDefinition(
            rootNote: .A, type: .seventh,
            midiNotes: [45, 52, 55, 61, 64],
            fretPositions: [nil, 0, 2, 0, 2, 0],
            startFret: 1,
            fingerPositions: [0, 0, 1, 0, 2, 0],
            barreInfo: nil
        ),
        // A#7
        ChordDefinition(
            rootNote: .Asharp, type: .seventh,
            midiNotes: [46, 53, 56, 62, 65],
            fretPositions: [nil, 1, 3, 1, 3, 1],
            startFret: 1,
            fingerPositions: [0, 1, 3, 1, 4, 1],
            barreInfo: BarreInfo(fret: 1, fromString: 1, toString: 5)
        ),
        // B7 - Open Position
        ChordDefinition(
            rootNote: .B, type: .seventh,
            midiNotes: [47, 54, 57, 63, 66],
            fretPositions: [nil, 2, 1, 2, 0, 2],
            startFret: 1,
            fingerPositions: [0, 2, 1, 3, 0, 4],
            barreInfo: nil
        )
    ]
    
    // MARK: - All Chords
    
    static var allChords: [ChordDefinition] {
        majorChords + minorChords + seventhChords
    }
    
    /// Get chord by root note and type
    static func chord(root: RootNote, type: ChordType) -> ChordDefinition? {
        allChords.first { $0.rootNote == root && $0.type == type }
    }
    
    /// Get chords for a specific chord type
    static func chords(ofType type: ChordType) -> [ChordDefinition] {
        switch type {
        case .major: return majorChords
        case .minor: return minorChords
        case .seventh: return seventhChords
        }
    }
    
    /// Get basic chords for ear training (compatible with old Chord struct)
    static let earTrainingChords: [ChordDefinition] = [
        chord(root: .G, type: .major)!,
        chord(root: .D, type: .major)!,
        chord(root: .C, type: .major)!,
        chord(root: .E, type: .minor)!,
        chord(root: .A, type: .minor)!
    ]
}

// MARK: - Chord Engine

/// AudioKit-based engine for playing guitar chords with realistic strumming
@MainActor
final class ChordEngine: ObservableObject {
    
    static let shared = ChordEngine()
    
    // MARK: - Published Properties
    @Published private(set) var isInitialized = false
    @Published private(set) var usingSoundFont = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - AudioKit Components
    private var engine: AudioEngine?
    private var sampler: AppleSampler?
    private var oscillatorBank: [DynamicOscillator] = []
    private var mixer: Mixer?
    
    // MARK: - Configuration
    private let strumDelay: TimeInterval = 0.04  // 40ms between notes for strumming effect
    private let noteDuration: TimeInterval = 4.0 // How long each note rings (increased for realism)
    
    private init() {}
    
    // MARK: - Initialization
    
    /// Initialize the audio engine with SoundFont or fallback
    func initialize() async {
        guard !isInitialized else { return }
        
        do {
            // Configure audio session
            try await configureAudioSession()
            
            // Create engine
            engine = AudioEngine()
            
            // Try to load SoundFont
            if let sf2URL = Bundle.main.url(forResource: "Guitar", withExtension: "sf2") {
                print("📁 ChordEngine: Found Guitar.sf2 at \(sf2URL.path)")
                do {
                    try await loadSoundFont(url: sf2URL)
                    print("🎸 ChordEngine: SoundFont loaded successfully!")
                } catch {
                    print("❌ ChordEngine: SoundFont loading failed: \(error)")
                    setupFallbackSynth()
                }
            } else {
                print("⚠️ ChordEngine: Guitar.sf2 not found in bundle. Using fallback synth.")
                setupFallbackSynth()
            }
            
            // Start engine
            try engine?.start()
            isInitialized = true
            print("✅ ChordEngine initialized successfully (SoundFont: \(usingSoundFont))")
            
        } catch {
            errorMessage = "Audio initialization failed: \(error.localizedDescription)"
            print("❌ ChordEngine: \(errorMessage ?? "Unknown error")")
            
            // Try fallback if SoundFont loading failed
            if !usingSoundFont {
                setupFallbackSynth()
                do {
                    try engine?.start()
                    isInitialized = true
                    print("✅ ChordEngine: Fallback synth initialized")
                } catch {
                    print("❌ ChordEngine: Fallback also failed")
                }
            }
        }
    }
    
    private func configureAudioSession() async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
    }
    
    private func loadSoundFont(url: URL) async throws {
        sampler = AppleSampler()
        guard let sampler = sampler, let engine = engine else { return }
        
        // Try loading with file name (AudioKit expects just the filename for bundle resources)
        let fileName = url.deletingPathExtension().lastPathComponent
        print("🎸 Trying to load SoundFont: \(fileName)")
        
        // Try different methods to load the SoundFont
        var loaded = false
        
        // Method 1: Try loadMelodicSoundFont (for melodic SF2 files)
        for preset in [0, 25, 24, 1] {
            do {
                try sampler.loadMelodicSoundFont(fileName, preset: preset)
                print("✅ Loaded with loadMelodicSoundFont, preset: \(preset)")
                loaded = true
                break
            } catch {
                print("⚠️ loadMelodicSoundFont preset \(preset) failed: \(error.localizedDescription)")
            }
        }
        
        // Method 2: Try with full path if filename method failed
        if !loaded {
            for preset in [0, 25, 24, 1] {
                do {
                    try sampler.loadSoundFont(url.path, preset: preset, bank: 0)
                    print("✅ Loaded with loadSoundFont path, preset: \(preset)")
                    loaded = true
                    break
                } catch {
                    print("⚠️ loadSoundFont path preset \(preset) failed")
                }
            }
        }
        
        if !loaded {
            throw NSError(domain: "ChordEngine", code: -1, 
                          userInfo: [NSLocalizedDescriptionKey: "Could not load SoundFont with any method"])
        }
        
        engine.output = sampler
        usingSoundFont = true
    }
    
    private func setupFallbackSynth() {
        guard let engine = engine else { return }
        
        // Create a bank of oscillators for polyphonic playback
        oscillatorBank = (0..<6).map { _ in
            let osc = DynamicOscillator()
            osc.amplitude = 0.3
            osc.start()
            return osc
        }
        
        mixer = Mixer(oscillatorBank)
        engine.output = mixer
        usingSoundFont = false
    }
    
    // MARK: - Playback
    
    /// Play a chord with arpeggiated strumming effect
    func playChord(_ chord: ChordDefinition) {
        guard isInitialized else {
            print("⚠️ ChordEngine: Not initialized")
            return
        }
        
        // Stop any currently playing notes
        stopAllNotes()
        
        // Play notes with strum delay
        for (index, midiNote) in chord.midiNotes.enumerated() {
            let delay = Double(index) * strumDelay
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playNote(midiNote: midiNote, velocity: 80)
            }
        }
        
        // Schedule note off
        DispatchQueue.main.asyncAfter(deadline: .now() + noteDuration) { [weak self] in
            self?.stopAllNotes()
        }
    }
    
    /// Play a single MIDI note
    private func playNote(midiNote: UInt8, velocity: UInt8 = 80) {
        if usingSoundFont {
            sampler?.play(noteNumber: MIDINoteNumber(midiNote), velocity: MIDIVelocity(velocity), channel: 0)
        } else {
            // Fallback: Use oscillator
            if let osc = oscillatorBank.first(where: { $0.amplitude < 0.1 }) ?? oscillatorBank.first {
                let frequency = 440.0 * pow(2.0, (Double(midiNote) - 69.0) / 12.0)
                osc.frequency = AUValue(frequency)
                osc.amplitude = 0.3
            }
        }
    }
    
    /// Stop all currently playing notes
    func stopAllNotes() {
        if usingSoundFont {
            // Stop all MIDI notes
            for note in 0..<128 {
                sampler?.stop(noteNumber: MIDINoteNumber(note), channel: 0)
            }
        } else {
            // Silence oscillators
            for osc in oscillatorBank {
                osc.amplitude = 0
            }
        }
    }
    
    // MARK: - Cleanup
    
    /// Clean up audio resources
    func cleanup() {
        stopAllNotes()
        engine?.stop()
        isInitialized = false
    }
    
    deinit {
        engine?.stop()
    }
}
