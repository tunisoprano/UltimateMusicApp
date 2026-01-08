//
//  ExerciseLevel.swift
//  MusicTuner
//
//  Created by MusicTuner
//

import Foundation

/// Difficulty levels for fretboard exercises
enum ExerciseLevel: String, CaseIterable, Identifiable {
    case openStrings = "Open Strings"
    case first3Frets = "Frets 0-3"
    case first5Frets = "Frets 0-5"
    case random = "Full Fretboard"
    
    var id: String { rawValue }
    
    /// Range of frets included in this level
    var fretRange: ClosedRange<Int> {
        switch self {
        case .openStrings:
            return 0...0
        case .first3Frets:
            return 0...3
        case .first5Frets:
            return 0...5
        case .random:
            return 0...12 // Practical range for exercises
        }
    }
    
    /// Description for the level
    var description: String {
        switch self {
        case .openStrings:
            return "Practice open strings only"
        case .first3Frets:
            return "Open strings and first 3 frets"
        case .first5Frets:
            return "Open strings and first 5 frets"
        case .random:
            return "All notes across the fretboard"
        }
    }
    
    /// Emoji icon for the level
    var icon: String {
        switch self {
        case .openStrings: return "🎸"
        case .first3Frets: return "🎵"
        case .first5Frets: return "🎶"
        case .random: return "🔥"
        }
    }
}

/// Represents a single exercise question
struct ExerciseQuestion: Identifiable, Equatable {
    let id = UUID()
    let instrumentString: InstrumentString
    let fret: Int
    let targetFrequency: Double
    let noteName: String
    let noteOctave: Int
    
    /// Display text for the question - simplified for memorization
    var promptText: String {
        // Hide fret info - user should memorize the fretboard
        "\(instrumentString.name) String (\(noteName))"
    }
    
    /// Expected note display
    var expectedNote: String {
        "\(noteName)\(noteOctave)"
    }
    
    /// Create a question from an instrument string and fret
    init(instrumentString: InstrumentString, fret: Int) {
        self.instrumentString = instrumentString
        self.fret = fret
        self.targetFrequency = instrumentString.frequencyAtFret(fret)
        
        let noteInfo = instrumentString.noteAtFret(fret)
        self.noteName = noteInfo.name
        self.noteOctave = noteInfo.octave
    }
}
