import Foundation
import SwiftUI

@MainActor
class ChordMakerViewModel: ObservableObject {
    @Published var state = ChordMakerState()
    @Published var activeTool: ChordMakerTool = .finger
    
    // MIDI notes for open strings E A D G B e
    private let openStringMIDI: [UInt8] = [40, 45, 50, 55, 59, 64]
    
    init() {
        Task {
            await ChordEngine.shared.initialize()
        }
    }
    
    var identifiedChordName: String {
        let midiNotes = currentMidiNotes
        guard !midiNotes.isEmpty else { return L("select_an_item") }
        
        // 1. Try to find an exact fret match in database
        if let match = ChordDatabase.allChords.first(where: { chord in
            guard chord.fretPositions.count == 6 else { return false }
            for i in 0..<6 {
                if chord.fretPositions[i] != state.strings[i] { return false }
            }
            return true
        }) {
            return match.displayName
        }
        
        // 2. Algorithm to detect chord by intervals
        if let algorithmicName = detectChord(from: midiNotes) {
            return algorithmicName
        }
        
        // 3. Fallback to just listing the notes
        let pitchClasses = midiNotes.map { pitchClass(for: $0) }
        let uniqueNotes = Array(Set(pitchClasses)).sorted { 
            pitchClasses.firstIndex(of: $0) ?? 0 < pitchClasses.firstIndex(of: $1) ?? 0 
        }
        let noteNames = uniqueNotes.joined(separator: " - ")
        return L("custom_chord", noteNames)
    }
    
    private func detectChord(from midiNotes: [UInt8]) -> String? {
        let sortedMidi = midiNotes.sorted()
        let bassNote = Int(sortedMidi.first!)
        let bassPC = bassNote % 12
        let uniquePCs = Array(Set(midiNotes.map { Int($0) % 12 })).sorted()
        
        // Formulas for detection
        let formulas: [String: [Int]] = [
            "Major": [0, 4, 7],
            "Minor": [0, 3, 7],
            "5": [0, 7],
            "Dim": [0, 3, 6],
            "Aug": [0, 4, 8],
            "sus2": [0, 2, 7],
            "sus4": [0, 5, 7],
            "maj7": [0, 4, 7, 11],
            "m7": [0, 3, 7, 10],
            "7": [0, 4, 7, 10],
            "m7b5": [0, 3, 6, 10],
            "dim7": [0, 3, 6, 9],
            "add9": [0, 4, 7, 2],
            "m(add9)": [0, 3, 7, 2]
        ]
        
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        
        for rootPC in uniquePCs {
            let intervals = uniquePCs.map { ($0 - rootPC + 12) % 12 }.sorted()
            
            for (name, formula) in formulas {
                if intervals == formula.sorted() {
                    let rootName = noteNames[rootPC]
                    let chordName = "\(rootName)\(name == "Major" ? "" : name == "Minor" ? "m" : name)"
                    
                    if rootPC != bassPC {
                        return "\(chordName)/\(noteNames[bassPC])"
                    }
                    return chordName
                }
            }
        }
        return nil
    }
    
    private func pitchClass(for midi: UInt8) -> String {
        let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        return notes[Int(midi) % 12]
    }
    
    var currentMidiNotes: [UInt8] {
        var notes: [UInt8] = []
        for i in 0..<6 {
            if let fret = state.strings[i] {
                notes.append(openStringMIDI[i] + UInt8(fret))
            }
        }
        return notes
    }
    
    func placeTool(stringIndex: Int, fret: Int) {
        switch activeTool {
        case .finger:
            if fret == 0 {
                // Tapped nut directly (handled by toggleNut normally, but just in case)
                state.strings[stringIndex] = 0
            } else {
                if state.strings[stringIndex] == fret {
                    // Tap on existing finger -> remove it
                    state.strings[stringIndex] = 0
                } else {
                    // Place new finger
                    state.strings[stringIndex] = fret
                    playSingleNote(stringIndex: stringIndex, fret: fret)
                }
            }
            
        case .barre:
            if fret > 0 {
                // If tapping the same fret where barre is, remove the barre
                if state.barreFret == fret {
                    state.barreFret = nil
                    for i in 0..<6 {
                        if state.strings[i] == fret {
                            state.strings[i] = 0
                        }
                    }
                } else {
                    // Place new barre
                    state.barreFret = fret
                    for i in 0..<6 {
                        let currentFret = state.strings[i] ?? -1
                        if currentFret < fret {
                            state.strings[i] = fret
                        }
                    }
                    strum() 
                }
            }
        }
    }
    
    func toggleNut(stringIndex: Int) {
        if state.strings[stringIndex] == nil {
            state.strings[stringIndex] = 0
        } else {
            state.strings[stringIndex] = nil
        }
    }
    
    private func playSingleNote(stringIndex: Int, fret: Int) {
        let note = openStringMIDI[stringIndex] + UInt8(fret)
        ChordEngine.shared.playNote(midiNote: note)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            ChordEngine.shared.stopAllNotes()
        }
    }
    

    var suggestedChords: [ChordDefinition] {
        var suggestions: [ChordDefinition] = []
        
        for chord in ChordDatabase.allChords {
            var isPotentialMatch = true
            var forgotToMuteSomething = false
            var hasPressedFretMatch = false
            
            for i in 0..<6 {
                let dbFret = chord.fretPositions[i]
                let userFret = state.strings[i]
                
                if let dbFret = dbFret {
                    if dbFret != userFret {
                        isPotentialMatch = false
                        break
                    }
                    if dbFret > 0 { hasPressedFretMatch = true }
                } else {
                    if userFret == 0 {
                        forgotToMuteSomething = true
                    } else if userFret != nil {
                        isPotentialMatch = false
                        break
                    }
                }
            }
            
            if isPotentialMatch && forgotToMuteSomething && hasPressedFretMatch {
                suggestions.append(chord)
            }
        }
        
        // Remove duplicates if any (by name)
        var uniqueSuggestions: [ChordDefinition] = []
        var seenNames = Set<String>()
        for s in suggestions {
            if !seenNames.contains(s.displayName) {
                seenNames.insert(s.displayName)
                uniqueSuggestions.append(s)
            }
        }
        return uniqueSuggestions
    }
    
    func applySuggestion(_ chord: ChordDefinition) {
        for i in 0..<6 {
            state.strings[i] = chord.fretPositions[i]
        }
    }

    func strum() {
        ChordEngine.shared.playMidiNotes(currentMidiNotes)
    }
    
    func clearAll() {
        state = ChordMakerState()
    }
}
