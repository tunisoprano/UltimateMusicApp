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
    case power = "Power"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .major: return L("major")
        case .minor: return L("minor")
        case .seventh: return L("seventh")
        case .power: return L("power")
        }
    }
    
    var suffix: String {
        switch self {
        case .major: return ""
        case .minor: return "m"
        case .seventh: return "7"
        case .power: return "5"
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

// MARK: - Chord Variation (NEW - Multi-voicing support)

/// Represents a single chord voicing/position
struct ChordVariation: Identifiable, Equatable, Hashable {
    let id = UUID()
    let positionName: String  // e.g., "Open", "Barre 3rd", "Triad"
    
    /// Fret positions for 6 strings (E A D G B e). nil = muted string, 0 = open string
    let fretPositions: [Int?]
    
    /// Starting fret for diagram display (1 for open chords, higher for barre chords)
    let startFret: Int
    
    /// Finger positions (0 = not pressed, 1=Index, 2=Middle, 3=Ring, 4=Pinky)
    let fingerPositions: [Int]
    
    /// MIDI notes for audio playback
    let midiNotes: [UInt8]
    
    /// Which finger creates the barre (nil if no barre)
    let barreInfo: BarreInfo?
    
    static func == (lhs: ChordVariation, rhs: ChordVariation) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
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
        // Cm - Open (high e muted — E natural is not in C minor)
        ChordDefinition(
            rootNote: .C, type: .minor,
            midiNotes: [48, 51, 55, 60],
            fretPositions: [nil, 3, 1, 0, 1, nil],
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
        // C7 — frets: x32310 → C(48) E(52) Bb(58) C(60) E(64)
        ChordDefinition(
            rootNote: .C, type: .seventh,
            midiNotes: [48, 52, 58, 60, 64],
            fretPositions: [nil, 3, 2, 3, 1, 0],
            startFret: 1,
            fingerPositions: [0, 3, 2, 4, 1, 0],
            barreInfo: nil
        ),
        // C#7 — high e muted (E natural not in C#7): x4342x → C#(49) F(53) B(59) C#(61)
        ChordDefinition(
            rootNote: .Csharp, type: .seventh,
            midiNotes: [49, 53, 59, 61],
            fretPositions: [nil, 4, 3, 4, 2, nil],
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
        // G7 - Open Position: 320001 → G(43) B(47) D(50) G(55) B(59) F(65)
        ChordDefinition(
            rootNote: .G, type: .seventh,
            midiNotes: [43, 47, 50, 55, 59, 65],
            fretPositions: [3, 2, 0, 0, 0, 1],
            startFret: 1,
            fingerPositions: [3, 2, 0, 0, 0, 1],
            barreInfo: nil
        ),
        // G#7: 431112 → G#(44) C(48) D#(51) G#(56) C(60) F#(66)
        ChordDefinition(
            rootNote: .Gsharp, type: .seventh,
            midiNotes: [44, 48, 51, 56, 60, 66],
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
        // B7 - Open Position: x21202 → B(47) D#(51) A(57) B(59) F#(66)
        ChordDefinition(
            rootNote: .B, type: .seventh,
            midiNotes: [47, 51, 57, 59, 66],
            fretPositions: [nil, 2, 1, 2, 0, 2],
            startFret: 1,
            fingerPositions: [0, 2, 1, 3, 0, 4],
            barreInfo: nil
        )
    ]
    
    // MARK: - Power Chords
    
    static let powerChords: [ChordDefinition] = [
        // E5 - Open Power Chord
        ChordDefinition(
            rootNote: .E, type: .power,
            midiNotes: [40, 47, 52],
            fretPositions: [0, 2, 2, nil, nil, nil],
            startFret: 1,
            fingerPositions: [0, 1, 2, 0, 0, 0],
            barreInfo: nil
        ),
        // F5 - Power Chord
        ChordDefinition(
            rootNote: .F, type: .power,
            midiNotes: [41, 48, 53],
            fretPositions: [1, 3, 3, nil, nil, nil],
            startFret: 1,
            fingerPositions: [1, 3, 4, 0, 0, 0],
            barreInfo: nil
        ),
        // F#5 - Power Chord
        ChordDefinition(
            rootNote: .Fsharp, type: .power,
            midiNotes: [42, 49, 54],
            fretPositions: [2, 4, 4, nil, nil, nil],
            startFret: 2,
            fingerPositions: [1, 3, 4, 0, 0, 0],
            barreInfo: nil
        ),
        // G5 - Power Chord
        ChordDefinition(
            rootNote: .G, type: .power,
            midiNotes: [43, 50, 55],
            fretPositions: [3, 5, 5, nil, nil, nil],
            startFret: 3,
            fingerPositions: [1, 3, 4, 0, 0, 0],
            barreInfo: nil
        ),
        // G#5 - Power Chord
        ChordDefinition(
            rootNote: .Gsharp, type: .power,
            midiNotes: [44, 51, 56],
            fretPositions: [4, 6, 6, nil, nil, nil],
            startFret: 4,
            fingerPositions: [1, 3, 4, 0, 0, 0],
            barreInfo: nil
        ),
        // A5 - Open Power Chord
        ChordDefinition(
            rootNote: .A, type: .power,
            midiNotes: [45, 52, 57],
            fretPositions: [nil, 0, 2, 2, nil, nil],
            startFret: 1,
            fingerPositions: [0, 0, 1, 2, 0, 0],
            barreInfo: nil
        ),
        // A#5 - Power Chord
        ChordDefinition(
            rootNote: .Asharp, type: .power,
            midiNotes: [46, 53, 58],
            fretPositions: [nil, 1, 3, 3, nil, nil],
            startFret: 1,
            fingerPositions: [0, 1, 3, 4, 0, 0],
            barreInfo: nil
        ),
        // B5 - Power Chord
        ChordDefinition(
            rootNote: .B, type: .power,
            midiNotes: [47, 54, 59],
            fretPositions: [nil, 2, 4, 4, nil, nil],
            startFret: 2,
            fingerPositions: [0, 1, 3, 4, 0, 0],
            barreInfo: nil
        ),
        // C5 - Power Chord
        ChordDefinition(
            rootNote: .C, type: .power,
            midiNotes: [48, 55, 60],
            fretPositions: [nil, 3, 5, 5, nil, nil],
            startFret: 3,
            fingerPositions: [0, 1, 3, 4, 0, 0],
            barreInfo: nil
        ),
        // C#5 - Power Chord
        ChordDefinition(
            rootNote: .Csharp, type: .power,
            midiNotes: [49, 56, 61],
            fretPositions: [nil, 4, 6, 6, nil, nil],
            startFret: 4,
            fingerPositions: [0, 1, 3, 4, 0, 0],
            barreInfo: nil
        ),
        // D5 - Open Power Chord
        ChordDefinition(
            rootNote: .D, type: .power,
            midiNotes: [50, 57, 62],
            fretPositions: [nil, nil, 0, 2, 3, nil],
            startFret: 1,
            fingerPositions: [0, 0, 0, 1, 2, 0],
            barreInfo: nil
        ),
        // D#5 - Power Chord
        ChordDefinition(
            rootNote: .Dsharp, type: .power,
            midiNotes: [51, 58, 63],
            fretPositions: [nil, nil, 1, 3, 4, nil],
            startFret: 1,
            fingerPositions: [0, 0, 1, 3, 4, 0],
            barreInfo: nil
        )
    ]
    
    // MARK: - MIDI Validation

    /// Open string MIDI values: E2=40, A2=45, D3=50, G3=55, B3=59, E4=64
    private static let openStringMIDI: [UInt8] = [40, 45, 50, 55, 59, 64]

    /// Compute expected MIDI notes from fret positions (ground truth)
    static func midiNotes(fromFrets frets: [Int?]) -> [UInt8] {
        frets.enumerated().compactMap { index, fret in
            guard let fret = fret else { return nil }
            return openStringMIDI[index] + UInt8(fret)
        }
    }

    /// Validate that all chord MIDI notes match their fret positions (debug only)
    #if DEBUG
    static func validateAllChords() {
        for chord in allChords {
            let expected = midiNotes(fromFrets: chord.fretPositions)
            if chord.midiNotes != expected {
                print("⚠️ MIDI mismatch for \(chord.name): stored=\(chord.midiNotes) expected=\(expected)")
            }
        }
        print("✅ ChordDatabase validation complete (\(allChords.count) chords)")
    }
    #endif

    // MARK: - All Chords

    static var allChords: [ChordDefinition] {
        majorChords + minorChords + seventhChords + powerChords
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
        case .power: return powerChords
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
    
    // MARK: - Chord Variations (Multi-voicing)
    
    /// C Major - 5 Variations
    static let cMajorVariations: [ChordVariation] = [
        // 1. Open Position (Standard)
        ChordVariation(
            positionName: "Open",
            fretPositions: [nil, 3, 2, 0, 1, 0],
            startFret: 1,
            fingerPositions: [0, 3, 2, 0, 1, 0],
            midiNotes: [48, 52, 55, 60, 64],
            barreInfo: nil
        ),
        // 2. Barre (A Shape) - 3rd fret
        ChordVariation(
            positionName: "Barre (3rd)",
            fretPositions: [nil, 3, 5, 5, 5, 3],
            startFret: 3,
            fingerPositions: [0, 1, 3, 3, 3, 1],
            midiNotes: [48, 55, 60, 64, 67],
            barreInfo: BarreInfo(fret: 3, fromString: 1, toString: 5)
        ),
        // 3. Barre (E Shape) - 8th fret
        ChordVariation(
            positionName: "Barre (8th)",
            fretPositions: [8, 10, 10, 9, 8, 8],
            startFret: 8,
            fingerPositions: [1, 3, 4, 2, 1, 1],
            midiNotes: [48, 55, 60, 64, 67, 72],
            barreInfo: BarreInfo(fret: 8, fromString: 0, toString: 5)
        ),
        // 4. Triad (High Strings) — G5=C(60), B5=E(64), e3=G(67)
        ChordVariation(
            positionName: "Triad",
            fretPositions: [nil, nil, nil, 5, 5, 3],
            startFret: 3,
            fingerPositions: [0, 0, 0, 3, 4, 1],
            midiNotes: [60, 64, 67],
            barreInfo: nil
        ),
        // 5. Cadd9 Open (Bonus voicing)
        ChordVariation(
            positionName: "Add9",
            fretPositions: [nil, 3, 2, 0, 3, 0],
            startFret: 1,
            fingerPositions: [0, 2, 1, 0, 3, 0],
            midiNotes: [48, 52, 55, 62, 64],
            barreInfo: nil
        )
    ]
    
    /// G Major - 5 Variations
    static let gMajorVariations: [ChordVariation] = [
        // 1. Open Position (Standard)
        ChordVariation(
            positionName: "Open",
            fretPositions: [3, 2, 0, 0, 0, 3],
            startFret: 1,
            fingerPositions: [2, 1, 0, 0, 0, 3],
            midiNotes: [43, 47, 50, 55, 59, 67],
            barreInfo: nil
        ),
        // 2. Barre (E Shape) - 3rd fret
        ChordVariation(
            positionName: "Barre (3rd)",
            fretPositions: [3, 5, 5, 4, 3, 3],
            startFret: 3,
            fingerPositions: [1, 3, 4, 2, 1, 1],
            midiNotes: [43, 50, 55, 59, 62, 67],
            barreInfo: BarreInfo(fret: 3, fromString: 0, toString: 5)
        ),
        // 3. Barre (A Shape) - 10th fret
        ChordVariation(
            positionName: "Barre (10th)",
            fretPositions: [nil, 10, 12, 12, 12, 10],
            startFret: 10,
            fingerPositions: [0, 1, 3, 3, 3, 1],
            midiNotes: [55, 62, 67, 71, 74],
            barreInfo: BarreInfo(fret: 10, fromString: 1, toString: 5)
        ),
        // 4. Triad (High Strings)
        ChordVariation(
            positionName: "Triad",
            fretPositions: [nil, nil, nil, 0, 0, 3],
            startFret: 1,
            fingerPositions: [0, 0, 0, 0, 0, 3],
            midiNotes: [55, 59, 67],
            barreInfo: nil
        ),
        // 5. Folk G (4 finger version)
        ChordVariation(
            positionName: "Folk",
            fretPositions: [3, 2, 0, 0, 3, 3],
            startFret: 1,
            fingerPositions: [2, 1, 0, 0, 3, 4],
            midiNotes: [43, 47, 50, 55, 62, 67],
            barreInfo: nil
        )
    ]
    
    /// Get variations for a specific chord (returns array of voicings)
    static func variations(for root: RootNote, type: ChordType) -> [ChordVariation] {
        var result: [ChordVariation]

        // Hand-curated sets keep their special voicings (Add9, Folk...)
        switch (root, type) {
        case (.C, .major): result = cMajorVariations
        case (.G, .major): result = gMajorVariations
        default:
            if let chord = chord(root: root, type: type) {
                let isOpen = chord.fretPositions.contains(0) && chord.barreInfo == nil
                result = [ChordVariation(
                    positionName: isOpen ? "Open" : "Standard",
                    fretPositions: chord.fretPositions,
                    startFret: chord.startFret,
                    fingerPositions: chord.fingerPositions,
                    midiNotes: chord.midiNotes,
                    barreInfo: chord.barreInfo
                )]
            } else {
                result = []
            }
        }

        // Generated movable voicings, skipping any that duplicate existing positions
        for variation in generatedVariations(for: root, type: type)
        where !result.contains(where: { $0.fretPositions == variation.fretPositions }) {
            result.append(variation)
        }

        return result
    }

    // MARK: - Generated Voicings (movable CAGED shapes)
    //
    // Barre shapes are movable: the same finger pattern shifted to fret N
    // produces the chord whose root sits at fret N of the shape's root string.
    // All generated voicings are verified against the chord's theoretical
    // pitch-class set in validateAllVariations() (DEBUG).

    /// A movable voicing shape. `baseFrets` are offsets relative to the barre fret N.
    private struct MovableShape {
        let namePrefix: String
        let baseFrets: [Int?]              // nil = muted string
        let fingers: [Int]
        let barreStrings: (from: Int, to: Int)?
        let rootOpenPC: Int                // pitch class of the shape's root string played open
        let minFret: Int
    }

    private static let majorShapes: [MovableShape] = [
        // E-shape (root on 6th string)
        MovableShape(namePrefix: "Barre", baseFrets: [0, 2, 2, 1, 0, 0],
                     fingers: [1, 3, 4, 2, 1, 1], barreStrings: (0, 5), rootOpenPC: 4, minFret: 1),
        // A-shape (root on 5th string)
        MovableShape(namePrefix: "Barre", baseFrets: [nil, 0, 2, 2, 2, 0],
                     fingers: [0, 1, 3, 3, 3, 1], barreStrings: (1, 5), rootOpenPC: 9, minFret: 1)
    ]

    private static let minorShapes: [MovableShape] = [
        // Em-shape
        MovableShape(namePrefix: "Barre", baseFrets: [0, 2, 2, 0, 0, 0],
                     fingers: [1, 3, 4, 1, 1, 1], barreStrings: (0, 5), rootOpenPC: 4, minFret: 1),
        // Am-shape
        MovableShape(namePrefix: "Barre", baseFrets: [nil, 0, 2, 2, 1, 0],
                     fingers: [0, 1, 3, 4, 2, 1], barreStrings: (1, 5), rootOpenPC: 9, minFret: 1)
    ]

    private static let seventhShapes: [MovableShape] = [
        // E7-shape
        MovableShape(namePrefix: "Barre", baseFrets: [0, 2, 0, 1, 0, 0],
                     fingers: [1, 3, 1, 2, 1, 1], barreStrings: (0, 5), rootOpenPC: 4, minFret: 1),
        // A7-shape
        MovableShape(namePrefix: "Barre", baseFrets: [nil, 0, 2, 0, 2, 0],
                     fingers: [0, 1, 3, 1, 4, 1], barreStrings: (1, 5), rootOpenPC: 9, minFret: 1)
    ]

    /// Dominant 9th, A-shape (the classic "x32333"-style funk voicing, movable)
    private static let ninthShape = MovableShape(
        namePrefix: "9th", baseFrets: [nil, 0, -1, 0, 0, 0],
        fingers: [0, 2, 1, 3, 3, 3], barreStrings: (3, 5), rootOpenPC: 9, minFret: 2
    )

    private static let powerShapes: [MovableShape] = [
        MovableShape(namePrefix: "Alt", baseFrets: [0, 2, 2, nil, nil, nil],
                     fingers: [1, 3, 4, 0, 0, 0], barreStrings: nil, rootOpenPC: 4, minFret: 1),
        MovableShape(namePrefix: "Alt", baseFrets: [nil, 0, 2, 2, nil, nil],
                     fingers: [0, 1, 3, 4, 0, 0], barreStrings: nil, rootOpenPC: 9, minFret: 1)
    ]

    /// Hand-curated open add9 voicings for popular chords (C's lives in cMajorVariations)
    private static let add9Variations: [RootNote: ChordVariation] = [
        .G: ChordVariation(
            positionName: "Add9",
            fretPositions: [3, nil, 0, 2, 0, 3],
            startFret: 1,
            fingerPositions: [2, 0, 0, 1, 0, 3],
            midiNotes: midiNotes(fromFrets: [3, nil, 0, 2, 0, 3]),
            barreInfo: nil
        ),
        .E: ChordVariation(
            positionName: "Add9",
            fretPositions: [0, 2, 2, 1, 0, 2],
            startFret: 1,
            fingerPositions: [0, 2, 3, 1, 0, 4],
            midiNotes: midiNotes(fromFrets: [0, 2, 2, 1, 0, 2]),
            barreInfo: nil
        ),
        .A: ChordVariation(
            positionName: "Add9",
            fretPositions: [nil, 0, 2, 4, 2, 0],
            startFret: 1,
            fingerPositions: [0, 0, 1, 3, 2, 0],
            midiNotes: midiNotes(fromFrets: [nil, 0, 2, 4, 2, 0]),
            barreInfo: nil
        )
    ]

    private static func generatedVariations(for root: RootNote, type: ChordType) -> [ChordVariation] {
        let pc = root.pitchClass
        var generated: [ChordVariation] = []

        let shapes: [MovableShape]
        switch type {
        case .major: shapes = majorShapes
        case .minor: shapes = minorShapes
        case .seventh: shapes = seventhShapes
        case .power: shapes = powerShapes
        }

        for shape in shapes {
            if let variation = variation(from: shape, rootPC: pc) {
                generated.append(variation)
            }
        }
        generated.sort { $0.startFret < $1.startFret }

        // Top-string triad for major/minor
        if type == .major || type == .minor,
           let triad = triadVariation(rootPC: pc, third: type == .major ? 4 : 3) {
            generated.append(triad)
        }

        // Dominant 9th voicing for 7th chords
        if type == .seventh, let ninth = variation(from: ninthShape, rootPC: pc) {
            generated.append(ninth)
        }

        // Open add9 voicings for popular majors
        if type == .major, let add9 = add9Variations[root] {
            generated.append(add9)
        }

        return generated
    }

    /// Build a voicing by shifting a movable shape to this root's fret
    private static func variation(from shape: MovableShape, rootPC: Int) -> ChordVariation? {
        var n = mod12(rootPC - shape.rootOpenPC)
        if n < shape.minFret { n += 12 }
        let maxBase = shape.baseFrets.compactMap { $0 }.max() ?? 0
        guard n <= 12, n + maxBase <= 15 else { return nil }

        let frets = shape.baseFrets.map { $0.map { $0 + n } }
        let barre = shape.barreStrings.map {
            BarreInfo(fret: n, fromString: $0.from, toString: $0.to)
        }
        // Diagram window must start at the lowest fretted position (can sit below the barre)
        let lowestFretted = frets.compactMap { $0 }.filter { $0 > 0 }.min() ?? n

        return ChordVariation(
            positionName: "\(shape.namePrefix) (\(ordinal(n)))",
            fretPositions: frets,
            startFret: lowestFretted,
            fingerPositions: shape.fingers,
            midiNotes: midiNotes(fromFrets: frets),
            barreInfo: barre
        )
    }

    /// Compact triad on the top three strings (G B e). Picks the lowest playable inversion.
    private static func triadVariation(rootPC: Int, third: Int) -> ChordVariation? {
        // Frets on G(7)/B(11)/e(4) for root position, 1st and 2nd inversions
        let candidates: [[Int]] = [
            [mod12(rootPC - 7), mod12(rootPC + third - 11), mod12(rootPC + 7 - 4)],
            [mod12(rootPC + third - 7), mod12(rootPC + 7 - 11), mod12(rootPC - 4)],
            [mod12(rootPC + 7 - 7), mod12(rootPC - 11), mod12(rootPC + third - 4)]
        ]

        let playable = candidates.filter { frets in
            guard let maxF = frets.max(), let minF = frets.min() else { return false }
            return maxF >= 1 && maxF <= 12 && (maxF - minF) <= 3
        }
        guard let best = playable.min(by: { $0.max()! < $1.max()! }) else { return nil }

        let frets: [Int?] = [nil, nil, nil] + best.map { Optional($0) }
        let fingers = [0, 0, 0] + triadFingers(best)
        let startFret = best.filter { $0 > 0 }.min() ?? 1

        return ChordVariation(
            positionName: "Triad",
            fretPositions: frets,
            startFret: startFret,
            fingerPositions: fingers,
            midiNotes: midiNotes(fromFrets: frets),
            barreInfo: nil
        )
    }

    /// Finger assignment heuristic for 3-note shapes: lowest fret gets index,
    /// higher frets get ring/pinky (matches conventional triad fingerings).
    private static func triadFingers(_ frets: [Int]) -> [Int] {
        let distinct = Set(frets.filter { $0 > 0 }).sorted()
        var baseForValue: [Int: Int] = [:]
        for (index, value) in distinct.enumerated() {
            baseForValue[value] = index == 0 ? 1 : (index == 1 ? 3 : 4)
        }
        var occurrences: [Int: Int] = [:]
        return frets.map { fret in
            guard fret > 0, let base = baseForValue[fret] else { return 0 }
            let offset = occurrences[fret, default: 0]
            occurrences[fret] = offset + 1
            return min(base + offset, 4)
        }
    }

    private static func mod12(_ value: Int) -> Int {
        ((value % 12) + 12) % 12
    }

    private static func ordinal(_ n: Int) -> String {
        switch n {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        default: return "\(n)th"
        }
    }

    // MARK: - Variation Validation (DEBUG)

    #if DEBUG
    /// Verify every voicing (hand-written and generated) against the chord's
    /// theoretical pitch-class set. Triads may omit the fifth but never contain
    /// a wrong note.
    static func validateAllVariations() {
        var issueCount = 0

        for root in RootNote.allCases {
            for type in ChordType.allCases {
                let r = root.pitchClass
                let fullSet: Set<Int>
                switch type {
                case .major: fullSet = Set([0, 4, 7].map { mod12(r + $0) })
                case .minor: fullSet = Set([0, 3, 7].map { mod12(r + $0) })
                case .seventh: fullSet = Set([0, 4, 7, 10].map { mod12(r + $0) })
                case .power: fullSet = Set([0, 7].map { mod12(r + $0) })
                }

                for variation in variations(for: root, type: type) {
                    let actual = Set(midiNotes(fromFrets: variation.fretPositions).map { Int($0) % 12 })
                    let name = "\(root.displayName)\(type.suffix) [\(variation.positionName)]"

                    // Allowed = every tone of the formula; required = formula minus
                    // the fifth, which is conventionally omittable (e.g. open C7).
                    let allowed: Set<Int>
                    let required: Set<Int>
                    if variation.positionName.hasPrefix("9th") {
                        allowed = Set([0, 2, 4, 7, 10].map { mod12(r + $0) })
                        required = Set([0, 2, 4, 10].map { mod12(r + $0) })
                    } else if variation.positionName == "Add9" {
                        allowed = Set([0, 2, 4, 7].map { mod12(r + $0) })
                        required = allowed
                    } else if variation.positionName == "Triad" {
                        let third = type == .minor ? 3 : 4
                        allowed = fullSet
                        required = Set([0, third].map { mod12(r + $0) })
                    } else if type == .seventh {
                        allowed = fullSet
                        required = Set([0, 4, 10].map { mod12(r + $0) })
                    } else {
                        allowed = fullSet
                        required = fullSet
                    }

                    if !actual.isSubset(of: allowed) || !required.isSubset(of: actual) {
                        print("⚠️ Variation pitch mismatch: \(name) got \(actual.sorted()) expected \(required.sorted()) ⊆ x ⊆ \(allowed.sorted())")
                        issueCount += 1
                    }
                }
            }
        }

        print(issueCount == 0
              ? "✅ Variation validation complete — all voicings match their chord formulas"
              : "❌ Variation validation found \(issueCount) issue(s)")
    }
    #endif
}

// MARK: - Root Note Pitch Class

extension RootNote {
    /// Chromatic pitch class (C = 0 ... B = 11)
    var pitchClass: Int {
        switch self {
        case .C: return 0
        case .Csharp: return 1
        case .D: return 2
        case .Dsharp: return 3
        case .E: return 4
        case .F: return 5
        case .Fsharp: return 6
        case .G: return 7
        case .Gsharp: return 8
        case .A: return 9
        case .Asharp: return 10
        case .B: return 11
        }
    }
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
    
    // Playback tracking - prevents race conditions
    private nonisolated(unsafe) var currentPlaybackID: UUID?
    
    /// Dedicated queue for strum timing — keeps main thread free
    private let strumQueue = DispatchQueue(label: "com.2jam.chordEngine.strum", qos: .userInteractive)
    
    /// Track active notes so we only stop what's actually playing
    private var activeNotes: Set<UInt8> = []
    
    private init() {}
    
    // MARK: - Initialization
    
    /// Initialize the audio engine with SoundFont or fallback
    func initialize() async {
        guard !isInitialized else { return }

        #if DEBUG
        ChordDatabase.validateAllChords()
        ChordDatabase.validateAllVariations()
        #endif

        do {
            // Configure audio session for playback (ambient allows mixing with mic input)
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
        // Use .playAndRecord so playback and mic can coexist without session conflicts
        // .mixWithOthers prevents interrupting other audio (e.g., Tuner's mic)
        // .defaultToSpeaker ensures sound comes from speaker, not earpiece
        try session.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
        try session.setPreferredIOBufferDuration(0.005) // 5ms buffer for lower latency
        try session.setActive(true)
    }
    
    private func loadSoundFont(url: URL) async throws {
        sampler = AppleSampler()
        guard let sampler = sampler, let engine = engine else { return }

        let fileName = url.deletingPathExtension().lastPathComponent
        print("🎸 Trying to load SoundFont: \(fileName) at \(url.path)")

        var loaded = false

        // Method 1: AudioKit's loadSoundFont with just the FILENAME (no path, no extension)
        // AudioKit internally calls findFileURL which searches Bundle.main
        let guitarPresets: [Int] = [25, 24, 0, 1, 2, 3, 4, 5]
        for preset in guitarPresets {
            do {
                try sampler.loadSoundFont(fileName, preset: preset, bank: 0)
                print("✅ Loaded SoundFont '\(fileName)' with preset: \(preset)")
                loaded = true
                break
            } catch {
                print("⚠️ loadSoundFont(\(fileName), preset: \(preset)) failed: \(error.localizedDescription)")
            }
        }

        // Method 2: Direct AVAudioUnitSampler load with full URL (bypasses AudioKit file search)
        if !loaded {
            print("🔄 Trying direct AVAudioUnitSampler load with URL...")
            for preset in guitarPresets {
                do {
                    try sampler.samplerUnit.loadSoundBankInstrument(
                        at: url,
                        program: MIDIByte(preset),
                        bankMSB: MIDIByte(0x79),  // kAUSampler_DefaultMelodicBankMSB
                        bankLSB: MIDIByte(0)
                    )
                    print("✅ Direct load succeeded with preset: \(preset)")
                    loaded = true
                    break
                } catch {
                    print("⚠️ Direct load preset \(preset) failed: \(error.localizedDescription)")
                }
            }
        }

        // Method 3: Try bank MSB 0 (some SoundFonts use this instead of 0x79)
        if !loaded {
            print("🔄 Trying with bankMSB 0...")
            for preset in guitarPresets {
                do {
                    try sampler.samplerUnit.loadSoundBankInstrument(
                        at: url,
                        program: MIDIByte(preset),
                        bankMSB: MIDIByte(0),
                        bankLSB: MIDIByte(0)
                    )
                    print("✅ Bank 0 load succeeded with preset: \(preset)")
                    loaded = true
                    break
                } catch {
                    // Silent - last resort
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

        // Create 6 oscillators (one per guitar string) with triangle waveform
        // Triangle waves have softer harmonics than sawtooth, closer to plucked string
        oscillatorBank = (0..<6).map { _ in
            let osc = DynamicOscillator(waveform: Table(.triangle))
            osc.amplitude = 0
            osc.start()
            return osc
        }

        mixer = Mixer(oscillatorBank)
        mixer?.volume = 0.6
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
        
        // Generate new playback ID to cancel any pending stop from previous chord
        let playbackID = UUID()
        currentPlaybackID = playbackID
        
        // Stop any currently playing notes immediately
        stopAllNotes()

        // Use MIDI notes directly — they already represent correct guitar pitches
        let notes = chord.midiNotes

        // Calculate total strum duration
        let totalStrumTime = Double(notes.count) * strumDelay

        // Play notes with strum delay on dedicated queue for precise timing
        let capturedPlaybackID = playbackID
        strumQueue.async { [weak self] in
            for (index, midiNote) in notes.enumerated() {
                // Check if playback was cancelled
                guard self?.currentPlaybackID == capturedPlaybackID else { return }
                
                if index > 0 {
                    Thread.sleep(forTimeInterval: self?.strumDelay ?? 0.04)
                }
                
                DispatchQueue.main.async {
                    guard self?.currentPlaybackID == capturedPlaybackID else { return }
                    self?.playNote(midiNote: midiNote, velocity: 80)
                }
            }
        }
        
        // Schedule note off - account for strum time + note duration
        let stopDelay = totalStrumTime + noteDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + stopDelay) { [weak self] in
            // Only stop if this is still the current playback (no new chord started)
            guard self?.currentPlaybackID == playbackID else { return }
            self?.stopAllNotes()
        }
    }
    
    /// Index of next available oscillator for fallback synth
    private var nextOscIndex: Int = 0

    /// Play a single MIDI note
    private func playNote(midiNote: UInt8, velocity: UInt8 = 80) {
        activeNotes.insert(midiNote)
        if usingSoundFont {
            sampler?.play(noteNumber: MIDINoteNumber(midiNote), velocity: MIDIVelocity(velocity), channel: 0)
        } else {
            // Fallback: Assign oscillators round-robin (one per string)
            guard !oscillatorBank.isEmpty else { return }
            let osc = oscillatorBank[nextOscIndex % oscillatorBank.count]
            nextOscIndex += 1

            let frequency = 440.0 * pow(2.0, (Double(midiNote) - 69.0) / 12.0)
            osc.frequency = AUValue(frequency)

            // Velocity-sensitive amplitude with pluck-like attack
            let amp = AUValue(velocity) / 127.0 * 0.35
            osc.amplitude = amp

            // Simulate decay: fade out over 2 seconds for guitar-like pluck
            let capturedOsc = osc
            let capturedAmp = amp
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                // Only fade if the oscillator hasn't been reassigned
                if capturedOsc.amplitude == capturedAmp || capturedOsc.amplitude > 0.05 {
                    capturedOsc.amplitude = capturedAmp * 0.4
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if capturedOsc.amplitude > 0.02 {
                    capturedOsc.amplitude = capturedAmp * 0.1
                }
            }
        }
    }
    
    /// Stop all currently playing notes
    func stopAllNotes() {
        if usingSoundFont {
            // Only stop notes that are actually playing (not all 128!)
            for note in activeNotes {
                sampler?.stop(noteNumber: MIDINoteNumber(note), channel: 0)
            }
        } else {
            // Silence oscillators
            for osc in oscillatorBank {
                osc.amplitude = 0
            }
            nextOscIndex = 0
        }
        activeNotes.removeAll()
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
