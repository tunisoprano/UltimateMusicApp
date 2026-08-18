//
//  ExerciseLevel.swift
//  MusicTuner
//
//  Fretboard exercise levels with progressive difficulty
//

import Foundation
import SwiftUI

/// Fretboard exercise level definition
struct FretboardLevel: Identifiable, Equatable {
    let id: Int
    let title: String
    let localizedTitleKey: String
    let subtitle: String
    let localizedSubtitleKey: String
    let icon: String
    let gradientColors: [Color]
    let fretRange: ClosedRange<Int>
    let passThreshold: Double
    
    var localizedTitle: String { L(localizedTitleKey) }
    var localizedSubtitle: String { L(localizedSubtitleKey) }
    
    static func == (lhs: FretboardLevel, rhs: FretboardLevel) -> Bool {
        lhs.id == rhs.id
    }
}

/// All fretboard levels
struct FretboardCurriculum {
    
    static let levels: [FretboardLevel] = [
        // Level 1: Open Strings
        FretboardLevel(
            id: 1,
            title: "Open Strings",
            localizedTitleKey: "fb_level_open_strings",
            subtitle: "Learn open string notes",
            localizedSubtitleKey: "fb_level_open_strings_subtitle",
            icon: "1.circle.fill",
            gradientColors: [.green, .teal],
            fretRange: 0...0,
            passThreshold: 0.7
        ),
        
        // Level 2: First Position
        FretboardLevel(
            id: 2,
            title: "First Position",
            localizedTitleKey: "fb_level_first_position",
            subtitle: "Frets 0-3",
            localizedSubtitleKey: "fb_level_first_position_subtitle",
            icon: "2.circle.fill",
            gradientColors: [.blue, .purple],
            fretRange: 0...3,
            passThreshold: 0.7
        ),
        
        // Level 3: Fifth Position
        FretboardLevel(
            id: 3,
            title: "Fifth Position",
            localizedTitleKey: "fb_level_fifth_position",
            subtitle: "Frets 0-5",
            localizedSubtitleKey: "fb_level_fifth_position_subtitle",
            icon: "3.circle.fill",
            gradientColors: [.cyan, .blue],
            fretRange: 0...5,
            passThreshold: 0.75
        ),
        
        // Level 4: Upper Frets
        FretboardLevel(
            id: 4,
            title: "Upper Frets",
            localizedTitleKey: "fb_level_upper_frets",
            subtitle: "Frets 0-7",
            localizedSubtitleKey: "fb_level_upper_frets_subtitle",
            icon: "4.circle.fill",
            gradientColors: [.indigo, .blue],
            fretRange: 0...7,
            passThreshold: 0.8
        ),
        
        // Level 5: Full Fretboard
        FretboardLevel(
            id: 5,
            title: "Full Fretboard",
            localizedTitleKey: "fb_level_full_fretboard",
            subtitle: "Frets 0-12",
            localizedSubtitleKey: "fb_level_full_fretboard_subtitle",
            icon: "star.circle.fill",
            gradientColors: [.orange, .red],
            fretRange: 0...12,
            passThreshold: 0.85
        )
    ]
    
    static func level(id: Int) -> FretboardLevel? {
        levels.first { $0.id == id }
    }
    
    static func nextLevel(after level: FretboardLevel) -> FretboardLevel? {
        levels.first { $0.id == level.id + 1 }
    }
    
    static var totalLevels: Int { levels.count }

    /// Levels with id >= this value require premium (last 2 levels)
    static var premiumThreshold: Int {
        let ids = levels.map { $0.id }.sorted()
        guard ids.count > 2 else { return ids.last.map { $0 + 1 } ?? Int.max }
        return ids[ids.count - 2]
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
    
    /// Display text for the question
    var promptText: String {
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
