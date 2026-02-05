//
//  Curriculum.swift
//  MusicTuner
//
//  Chord Mastery curriculum definitions
//  Defines the learning path with 4 progressive levels
//

import SwiftUI

// MARK: - Level Definition

/// Represents a single learning level in Chord Mastery
struct LevelDefinition: Identifiable {
    let id: Int
    let title: String
    let localizedTitleKey: String
    let subtitle: String
    let localizedSubtitleKey: String
    let icon: String
    let gradientColors: [Color]
    
    /// Chord identifiers as (RootNote, ChordType) tuples
    let chordIdentifiers: [(RootNote, ChordType)]
    
    /// Localized title
    var localizedTitle: String {
        L(localizedTitleKey)
    }
    
    /// Localized subtitle
    var localizedSubtitle: String {
        L(localizedSubtitleKey)
    }
    
    /// Get actual ChordDefinition objects from the database
    var chords: [ChordDefinition] {
        chordIdentifiers.compactMap { (root, type) in
            ChordDatabase.chord(root: root, type: type)
        }
    }
    
    /// Number of quiz questions (chord count × 2)
    var questionCount: Int {
        chordIdentifiers.count * 2
    }
    
    /// Pass threshold (70%)
    var passThreshold: Double {
        0.70
    }
    
    /// Minimum correct answers to pass
    var minimumCorrectAnswers: Int {
        Int(ceil(Double(questionCount) * passThreshold))
    }
}

// MARK: - Chord Curriculum

/// The complete Chord Mastery curriculum with 4 progressive levels
struct ChordCurriculum {
    
    // MARK: - All Levels
    
    static let levels: [LevelDefinition] = [
        // Level 1: Basics
        LevelDefinition(
            id: 1,
            title: "Basics",
            localizedTitleKey: "level_basics",
            subtitle: "First chords every guitarist learns",
            localizedSubtitleKey: "level_basics_subtitle",
            icon: "1.circle.fill",
            gradientColors: [.green, .teal],
            chordIdentifiers: [
                (.G, .major),
                (.D, .major),
                (.E, .minor),
                (.C, .major)
            ]
        ),
        
        // Level 2: Open Chords
        LevelDefinition(
            id: 2,
            title: "Open Chords",
            localizedTitleKey: "level_open_chords",
            subtitle: "Expand your chord vocabulary",
            localizedSubtitleKey: "level_open_chords_subtitle",
            icon: "2.circle.fill",
            gradientColors: [.blue, .purple],
            chordIdentifiers: [
                (.A, .major),
                (.E, .major),
                (.A, .minor),
                (.D, .minor),
                (.F, .major)
            ]
        ),
        
        // Level 3: Power Chords
        LevelDefinition(
            id: 3,
            title: "Power Chords",
            localizedTitleKey: "level_power_chords",
            subtitle: "Rock and punk essentials",
            localizedSubtitleKey: "level_power_chords_subtitle",
            icon: "3.circle.fill",
            gradientColors: [.orange, .red],
            chordIdentifiers: [
                (.E, .power),
                (.A, .power),
                (.D, .power),
                (.G, .power)
            ]
        ),
        
        // Level 4: 7th Chords
        LevelDefinition(
            id: 4,
            title: "7th Chords",
            localizedTitleKey: "level_seventh_chords",
            subtitle: "Add color to your playing",
            localizedSubtitleKey: "level_seventh_chords_subtitle",
            icon: "4.circle.fill",
            gradientColors: [.pink, .purple],
            chordIdentifiers: [
                (.G, .seventh),
                (.C, .seventh),
                (.D, .seventh),
                (.A, .seventh)
            ]
        )
    ]
    
    // MARK: - Helper Methods
    
    /// Get a specific level by ID
    static func level(id: Int) -> LevelDefinition? {
        levels.first { $0.id == id }
    }
    
    /// Get the next level after the given level
    static func nextLevel(after level: LevelDefinition) -> LevelDefinition? {
        levels.first { $0.id == level.id + 1 }
    }
    
    /// Total number of levels
    static var totalLevels: Int {
        levels.count
    }
}
