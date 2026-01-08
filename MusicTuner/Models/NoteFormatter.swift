//
//  NoteFormatter.swift
//  MusicTuner
//
//  Created by MusicTuner
//

import Foundation
import SwiftUI

/// Note naming style preference
enum NoteNamingStyle: String, CaseIterable, Identifiable {
    case english = "English"     // C, D, E, F, G, A, B
    case solfege = "Solfege"     // Do, Re, Mi, Fa, Sol, La, Si
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .english:
            return "C, D, E, F, G, A, B"
        case .solfege:
            return "Do, Re, Mi, Fa, Sol, La, Si"
        }
    }
}

/// Helper for formatting note names based on user preference
struct NoteFormatter {
    
    /// User's selected note naming style (persisted)
    @AppStorage("noteNamingStyle") static var styleRawValue: String = NoteNamingStyle.english.rawValue
    
    /// Current style as enum
    static var style: NoteNamingStyle {
        get { NoteNamingStyle(rawValue: styleRawValue) ?? .english }
        set { styleRawValue = newValue.rawValue }
    }
    
    /// English to Solfege mapping
    private static let solfegeMap: [String: String] = [
        "C": "Do",
        "D": "Re",
        "E": "Mi",
        "F": "Fa",
        "G": "Sol",
        "A": "La",
        "B": "Si"
    ]
    
    /// Format a note name according to user preference
    /// - Parameter noteName: Note name in English format (e.g., "C", "C#", "Db")
    /// - Returns: Formatted note name
    static func format(_ noteName: String) -> String {
        guard style == .solfege else {
            return noteName
        }
        
        // Handle accidentals
        if noteName.count > 1 {
            let letter = String(noteName.prefix(1))
            let accidental = String(noteName.dropFirst())
            
            if let solfege = solfegeMap[letter] {
                return solfege + accidental
            }
        } else {
            if let solfege = solfegeMap[noteName] {
                return solfege
            }
        }
        
        return noteName
    }
    
    /// Format a Note object
    static func format(_ note: Note) -> String {
        format(note.name)
    }
    
    /// Get just the letter part formatted
    static func formatLetter(_ noteName: String) -> String {
        let letter = String(noteName.prefix(1))
        return format(letter)
    }
    
    /// Get the accidental part (unchanged)
    static func getAccidental(_ noteName: String) -> String? {
        guard noteName.count > 1 else { return nil }
        return String(noteName.dropFirst())
    }
}
