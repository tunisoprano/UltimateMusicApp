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
        
        // Level 3: Minor Chords
        LevelDefinition(
            id: 3,
            title: "Minor Chords",
            localizedTitleKey: "level_minor_chords",
            subtitle: "Explore emotional minor sounds",
            localizedSubtitleKey: "level_minor_chords_subtitle",
            icon: "3.circle.fill",
            gradientColors: [.indigo, .blue],
            chordIdentifiers: [
                (.C, .minor),
                (.G, .minor),
                (.F, .minor),
                (.B, .minor)
            ]
        ),
        
        // Level 4: Power Chords
        LevelDefinition(
            id: 4,
            title: "Power Chords",
            localizedTitleKey: "level_power_chords",
            subtitle: "Rock and punk essentials",
            localizedSubtitleKey: "level_power_chords_subtitle",
            icon: "4.circle.fill",
            gradientColors: [.orange, .red],
            chordIdentifiers: [
                (.E, .power),
                (.A, .power),
                (.D, .power),
                (.G, .power)
            ]
        ),
        
        // Level 5: 7th Chords
        LevelDefinition(
            id: 5,
            title: "7th Chords",
            localizedTitleKey: "level_seventh_chords",
            subtitle: "Add color to your playing",
            localizedSubtitleKey: "level_seventh_chords_subtitle",
            icon: "5.circle.fill",
            gradientColors: [.pink, .purple],
            chordIdentifiers: [
                (.G, .seventh),
                (.C, .seventh),
                (.D, .seventh),
                (.A, .seventh)
            ]
        ),
        
        // Level 6: Barre Chords
        LevelDefinition(
            id: 6,
            title: "Barre Chords",
            localizedTitleKey: "level_barre_chords",
            subtitle: "Unlock the entire fretboard",
            localizedSubtitleKey: "level_barre_chords_subtitle",
            icon: "6.circle.fill",
            gradientColors: [.red, .orange],
            chordIdentifiers: [
                (.F, .major),
                (.B, .major),
                (.Fsharp, .minor),
                (.Asharp, .major),
                (.Gsharp, .minor)
            ]
        ),
        
        // Level 7: Sharp & Flat Chords
        LevelDefinition(
            id: 7,
            title: "Sharp Chords",
            localizedTitleKey: "level_sharp_chords",
            subtitle: "Master the in-between notes",
            localizedSubtitleKey: "level_sharp_chords_subtitle",
            icon: "7.circle.fill",
            gradientColors: [.teal, .mint],
            chordIdentifiers: [
                (.Csharp, .major),
                (.Fsharp, .major),
                (.Dsharp, .minor),
                (.Csharp, .seventh),
                (.B, .seventh)
            ]
        ),
        
        // Level 8: Mixed Review
        LevelDefinition(
            id: 8,
            title: "Mixed Review",
            localizedTitleKey: "level_final_challenge",
            subtitle: "Test everything you've learned",
            localizedSubtitleKey: "level_final_challenge_subtitle",
            icon: "star.circle.fill",
            gradientColors: [.yellow, .orange],
            chordIdentifiers: [
                (.G, .major),
                (.A, .minor),
                (.E, .seventh),
                (.D, .power),
                (.F, .major),
                (.B, .minor)
            ]
        ),

        // Level 9: 7th Expansion
        LevelDefinition(
            id: 9,
            title: "7th Expansion",
            localizedTitleKey: "level_seventh_expansion",
            subtitle: "New seventh chords across the neck",
            localizedSubtitleKey: "level_seventh_expansion_subtitle",
            icon: "9.circle.fill",
            gradientColors: [.purple, .indigo],
            chordIdentifiers: [
                (.E, .seventh),
                (.F, .seventh),
                (.Fsharp, .seventh),
                (.Gsharp, .seventh),
                (.Asharp, .seventh)
            ]
        ),

        // Level 10: Power Master
        LevelDefinition(
            id: 10,
            title: "Power Master",
            localizedTitleKey: "level_power_master",
            subtitle: "Power chords all over the fretboard",
            localizedSubtitleKey: "level_power_master_subtitle",
            icon: "bolt.circle.fill",
            gradientColors: [.red, .pink],
            chordIdentifiers: [
                (.C, .power),
                (.F, .power),
                (.B, .power),
                (.Csharp, .power),
                (.Gsharp, .power)
            ]
        ),

        // Level 11: Grand Finale
        LevelDefinition(
            id: 11,
            title: "Grand Finale",
            localizedTitleKey: "level_grand_finale",
            subtitle: "The toughest mix of everything",
            localizedSubtitleKey: "level_grand_finale_subtitle",
            icon: "trophy.fill",
            gradientColors: [.yellow, .red],
            chordIdentifiers: [
                (.Asharp, .major),
                (.Dsharp, .minor),
                (.Fsharp, .seventh),
                (.C, .minor),
                (.Gsharp, .power),
                (.Csharp, .major)
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

    /// Levels with id >= this value require premium (last 2 levels)
    static var premiumThreshold: Int {
        let ids = levels.map { $0.id }.sorted()
        guard ids.count > 2 else { return ids.last.map { $0 + 1 } ?? Int.max }
        return ids[ids.count - 2]
    }
}

// MARK: - Ear Training Curriculum

/// The complete Ear Training curriculum with 8 progressive levels
struct EarTrainingCurriculum {
    
    // MARK: - All Levels
    
    static let levels: [LevelDefinition] = [
        // Level 1: Major Basics
        LevelDefinition(
            id: 1,
            title: "Major Basics",
            localizedTitleKey: "et_level_major_basics",
            subtitle: "Learn to recognize basic major chords",
            localizedSubtitleKey: "et_level_major_basics_subtitle",
            icon: "1.circle.fill",
            gradientColors: [.green, .teal],
            chordIdentifiers: [
                (.C, .major),
                (.G, .major),
                (.D, .major)
            ]
        ),
        
        // Level 2: Minor Intro
        LevelDefinition(
            id: 2,
            title: "Minor Intro",
            localizedTitleKey: "et_level_minor_intro",
            subtitle: "Discover the sound of minor chords",
            localizedSubtitleKey: "et_level_minor_intro_subtitle",
            icon: "2.circle.fill",
            gradientColors: [.blue, .purple],
            chordIdentifiers: [
                (.E, .minor),
                (.A, .minor),
                (.D, .minor)
            ]
        ),
        
        // Level 3: Mixed Open
        LevelDefinition(
            id: 3,
            title: "Mixed Open",
            localizedTitleKey: "et_level_mixed_open",
            subtitle: "Distinguish major from minor by ear",
            localizedSubtitleKey: "et_level_mixed_open_subtitle",
            icon: "3.circle.fill",
            gradientColors: [.cyan, .blue],
            chordIdentifiers: [
                (.C, .major),
                (.G, .major),
                (.E, .minor),
                (.A, .minor)
            ]
        ),
        
        // Level 4: Extended Open
        LevelDefinition(
            id: 4,
            title: "Extended Open",
            localizedTitleKey: "et_level_extended_open",
            subtitle: "More major chords to identify",
            localizedSubtitleKey: "et_level_extended_open_subtitle",
            icon: "4.circle.fill",
            gradientColors: [.indigo, .blue],
            chordIdentifiers: [
                (.A, .major),
                (.E, .major),
                (.D, .major),
                (.F, .major)
            ]
        ),
        
        // Level 5: Minor Expansion
        LevelDefinition(
            id: 5,
            title: "Minor Expansion",
            localizedTitleKey: "et_level_minor_expansion",
            subtitle: "Explore more minor chord sounds",
            localizedSubtitleKey: "et_level_minor_expansion_subtitle",
            icon: "5.circle.fill",
            gradientColors: [.purple, .pink],
            chordIdentifiers: [
                (.C, .minor),
                (.G, .minor),
                (.F, .minor),
                (.B, .minor)
            ]
        ),
        
        // Level 6: 7th Chords
        LevelDefinition(
            id: 6,
            title: "7th Chords",
            localizedTitleKey: "et_level_seventh",
            subtitle: "Recognize the jazzy seventh sound",
            localizedSubtitleKey: "et_level_seventh_subtitle",
            icon: "6.circle.fill",
            gradientColors: [.orange, .red],
            chordIdentifiers: [
                (.G, .seventh),
                (.C, .seventh),
                (.D, .seventh),
                (.A, .seventh)
            ]
        ),
        
        // Level 7: Sharp Territory
        LevelDefinition(
            id: 7,
            title: "Sharp Territory",
            localizedTitleKey: "et_level_sharp_territory",
            subtitle: "Sharps and flats challenge your ear",
            localizedSubtitleKey: "et_level_sharp_territory_subtitle",
            icon: "7.circle.fill",
            gradientColors: [.teal, .mint],
            chordIdentifiers: [
                (.Csharp, .major),
                (.Fsharp, .major),
                (.Asharp, .major),
                (.Gsharp, .major)
            ]
        ),
        
        // Level 8: Mixed Review
        LevelDefinition(
            id: 8,
            title: "Mixed Review",
            localizedTitleKey: "et_level_final",
            subtitle: "Test everything you've learned",
            localizedSubtitleKey: "et_level_final_subtitle",
            icon: "star.circle.fill",
            gradientColors: [.yellow, .orange],
            chordIdentifiers: [
                (.G, .major),
                (.A, .minor),
                (.E, .seventh),
                (.D, .minor),
                (.F, .major),
                (.B, .minor)
            ]
        ),

        // Level 9: Seventh Colors
        LevelDefinition(
            id: 9,
            title: "Seventh Colors",
            localizedTitleKey: "et_level_seventh_colors",
            subtitle: "Tell new seventh sounds apart",
            localizedSubtitleKey: "et_level_seventh_colors_subtitle",
            icon: "9.circle.fill",
            gradientColors: [.purple, .indigo],
            chordIdentifiers: [
                (.E, .seventh),
                (.B, .seventh),
                (.F, .seventh),
                (.Fsharp, .seventh)
            ]
        ),

        // Level 10: Sharp Minors
        LevelDefinition(
            id: 10,
            title: "Sharp Minors",
            localizedTitleKey: "et_level_minor_sharps",
            subtitle: "Minor chords in sharp territory",
            localizedSubtitleKey: "et_level_minor_sharps_subtitle",
            icon: "10.circle.fill",
            gradientColors: [.indigo, .purple],
            chordIdentifiers: [
                (.Fsharp, .minor),
                (.Gsharp, .minor),
                (.Csharp, .minor),
                (.Dsharp, .minor)
            ]
        ),

        // Level 11: Grand Finale
        LevelDefinition(
            id: 11,
            title: "Grand Finale",
            localizedTitleKey: "et_level_grand_finale",
            subtitle: "The ultimate listening test",
            localizedSubtitleKey: "et_level_grand_finale_subtitle",
            icon: "trophy.fill",
            gradientColors: [.yellow, .red],
            chordIdentifiers: [
                (.E, .major),
                (.Csharp, .minor),
                (.Fsharp, .seventh),
                (.Asharp, .major),
                (.G, .minor),
                (.Dsharp, .seventh)
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

    /// Levels with id >= this value require premium (last 2 levels)
    static var premiumThreshold: Int {
        let ids = levels.map { $0.id }.sorted()
        guard ids.count > 2 else { return ids.last.map { $0 + 1 } ?? Int.max }
        return ids[ids.count - 2]
    }
}
