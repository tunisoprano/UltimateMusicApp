//
//  Note.swift
//  MusicTuner
//
//  Created by MusicTuner
//

import Foundation

/// Represents a musical note with its properties
struct Note: Identifiable, Equatable {
    let name: String
    let octave: Int
    let frequency: Double
    
    var id: String { "\(name)\(octave)" }
    
    /// Full display name with octave
    var displayName: String {
        "\(name)\(octave)"
    }
    
    /// Just the note name without octave (for large display)
    var shortName: String {
        name
    }
}

/// Static utility for note/frequency calculations
enum NoteUtility {
    /// All note names in chromatic order
    static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    
    /// Reference frequency for A4
    static let a4Frequency: Double = 440.0
    
    /// A4 is the 49th key on a piano (0-indexed: 48)
    static let a4MidiNumber: Int = 69
    
    /// Minimum detectable frequency (below E1 for bass)
    static let minFrequency: Double = 30.0
    
    /// Maximum detectable frequency (above E6)
    static let maxFrequency: Double = 1400.0
    
    /// Convert a frequency to the nearest note with cents deviation
    /// - Parameter frequency: The detected frequency in Hz
    /// - Returns: Tuple containing the nearest note and cents deviation (-50 to +50)
    static func frequencyToNote(_ frequency: Double) -> (note: Note, cents: Double)? {
        guard frequency >= minFrequency && frequency <= maxFrequency else {
            return nil
        }
        
        // Calculate the number of semitones from A4
        let semitones = 12.0 * log2(frequency / a4Frequency)
        
        // Round to get the nearest note
        let nearestSemitone = round(semitones)
        
        // Calculate cents deviation (how far from the nearest note)
        let cents = (semitones - nearestSemitone) * 100.0
        
        // Calculate MIDI number and convert to note
        let midiNumber = Int(nearestSemitone) + a4MidiNumber
        
        // Calculate octave and note index
        let noteIndex = ((midiNumber % 12) + 12) % 12 // Handle negative modulo
        let octave = (midiNumber / 12) - 1
        
        let noteName = noteNames[noteIndex]
        let noteFrequency = a4Frequency * pow(2.0, nearestSemitone / 12.0)
        
        let note = Note(name: noteName, octave: octave, frequency: noteFrequency)
        
        return (note, cents)
    }
    
    /// Convert a note to its frequency
    /// - Parameters:
    ///   - name: Note name (e.g., "A", "C#")
    ///   - octave: Octave number
    /// - Returns: Frequency in Hz
    static func noteToFrequency(name: String, octave: Int) -> Double? {
        guard let noteIndex = noteNames.firstIndex(of: name) else {
            return nil
        }
        
        // Calculate MIDI number
        let midiNumber = (octave + 1) * 12 + noteIndex
        
        // Calculate semitones from A4
        let semitones = Double(midiNumber - a4MidiNumber)
        
        // Calculate frequency
        return a4Frequency * pow(2.0, semitones / 12.0)
    }
    
    /// Check if a frequency matches a target frequency within tolerance
    /// - Parameters:
    ///   - detected: Detected frequency
    ///   - target: Target frequency
    ///   - toleranceCents: Tolerance in cents (default: 10)
    /// - Returns: True if frequencies match within tolerance
    static func frequencyMatches(_ detected: Double, target: Double, toleranceCents: Double = 10.0) -> Bool {
        let cents = 1200.0 * log2(detected / target)
        return abs(cents) <= toleranceCents
    }
    
    /// Get cents deviation between two frequencies
    static func centsDeviation(from detected: Double, to target: Double) -> Double {
        return 1200.0 * log2(detected / target)
    }
}
