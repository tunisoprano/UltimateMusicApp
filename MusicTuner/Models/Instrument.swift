//
//  Instrument.swift
//  MusicTuner
//
//  Created by MusicTuner
//

import Foundation

/// Supported instruments for tuning and exercises
enum Instrument: String, CaseIterable, Identifiable {
    case guitar = "Guitar"
    case bass = "Bass"
    case ukulele = "Ukulele"
    case free = "Free"
    
    var id: String { rawValue }
    
    /// Standard tuning strings for each instrument
    var strings: [InstrumentString] {
        switch self {
        case .guitar:
            return [
                InstrumentString(name: "E", octave: 2, frequency: 82.41, stringNumber: 6),
                InstrumentString(name: "A", octave: 2, frequency: 110.00, stringNumber: 5),
                InstrumentString(name: "D", octave: 3, frequency: 146.83, stringNumber: 4),
                InstrumentString(name: "G", octave: 3, frequency: 196.00, stringNumber: 3),
                InstrumentString(name: "B", octave: 3, frequency: 246.94, stringNumber: 2),
                InstrumentString(name: "E", octave: 4, frequency: 329.63, stringNumber: 1)
            ]
        case .bass:
            return [
                InstrumentString(name: "E", octave: 1, frequency: 41.20, stringNumber: 4),
                InstrumentString(name: "A", octave: 1, frequency: 55.00, stringNumber: 3),
                InstrumentString(name: "D", octave: 2, frequency: 73.42, stringNumber: 2),
                InstrumentString(name: "G", octave: 2, frequency: 98.00, stringNumber: 1)
            ]
        case .ukulele:
            // Standard ukulele tuning: G-C-E-A (re-entrant - G is higher than C)
            return [
                InstrumentString(name: "G", octave: 4, frequency: 392.00, stringNumber: 4),
                InstrumentString(name: "C", octave: 4, frequency: 261.63, stringNumber: 3),
                InstrumentString(name: "E", octave: 4, frequency: 329.63, stringNumber: 2),
                InstrumentString(name: "A", octave: 4, frequency: 440.00, stringNumber: 1)
            ]
        case .free:
            return []
        }
    }
    
    /// Whether this instrument supports string targeting
    var hasStringTargeting: Bool {
        self != .free
    }
    
    /// Frequency range for pitch detection
    var frequencyRange: ClosedRange<Double> {
        switch self {
        case .guitar:
            return 70.0...400.0
        case .bass:
            return 30.0...200.0
        case .ukulele:
            return 200.0...500.0
        case .free:
            return 27.5...4000.0
        }
    }
    
    /// Number of frets typically available
    var totalFrets: Int {
        switch self {
        case .guitar: return 22
        case .bass: return 20
        case .ukulele: return 15
        case .free: return 0
        }
    }
    
    /// Instruments available for exercises
    static var exerciseInstruments: [Instrument] {
        [.guitar, .bass, .ukulele]
    }
}

/// Represents a single string on an instrument
struct InstrumentString: Identifiable, Hashable {
    let name: String
    let octave: Int
    let frequency: Double
    let stringNumber: Int
    
    var id: Int { stringNumber }
    
    var displayName: String {
        "\(name)\(octave)"
    }
    
    func frequencyAtFret(_ fret: Int) -> Double {
        frequency * pow(2.0, Double(fret) / 12.0)
    }
    
    func noteAtFret(_ fret: Int) -> (name: String, octave: Int) {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        
        guard let baseIndex = noteNames.firstIndex(of: name.replacingOccurrences(of: "b", with: "#")) else {
            let flatToSharp: [String: String] = ["Db": "C#", "Eb": "D#", "Gb": "F#", "Ab": "G#", "Bb": "A#"]
            if let sharpName = flatToSharp[name], let index = noteNames.firstIndex(of: sharpName) {
                let newIndex = (index + fret) % 12
                let octaveIncrease = (index + fret) / 12
                return (noteNames[newIndex], octave + octaveIncrease)
            }
            return (name, octave)
        }
        
        let newIndex = (baseIndex + fret) % 12
        let octaveIncrease = (baseIndex + fret) / 12
        return (noteNames[newIndex], octave + octaveIncrease)
    }
}
