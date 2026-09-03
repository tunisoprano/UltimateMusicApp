import Foundation

/// Defines the tools available in the Chord Maker
enum ChordMakerTool: Equatable {
    case finger
    case barre
}

/// Represents the state of the Fretboard
struct ChordMakerState {
    /// 6 strings: Index 0 is Low E (6th string), Index 5 is High e (1st string).
    /// Value is the fret number pressed. 0 means open. nil means muted.
    var strings: [Int?] = [0, 0, 0, 0, 0, 0]
    
    /// Optional: track a barre.
    var barreFret: Int?
}
