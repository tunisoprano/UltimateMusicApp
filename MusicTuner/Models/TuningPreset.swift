//
//  TuningPreset.swift
//  MusicTuner
//
//  Alternate tunings (Drop D, Half-Step Down, Open G, DADGAD, Low G...)
//  Applied as a per-string semitone offset on top of an instrument's
//  standard tuning, shifting both the target frequency and note name.
//

import Foundation

/// A named alternate tuning for an instrument — a semitone offset per string,
/// applied in the same order as `Instrument.strings` (low to high).
struct TuningPreset: Identifiable, Hashable {
    let id: String
    let nameKey: String
    let semitoneOffsets: [Int]

    var displayName: String { L(nameKey) }

    /// Applies this preset's offsets to a base set of instrument strings,
    /// returning new strings with shifted frequency, name and octave.
    func apply(to strings: [InstrumentString]) -> [InstrumentString] {
        guard semitoneOffsets.count == strings.count else { return strings }
        return zip(strings, semitoneOffsets).map { $0.shifted(bySemitones: $1) }
    }

    /// A neutral "no offset" preset, used as a safe fallback.
    static var standard: TuningPreset {
        TuningPreset(id: "standard", nameKey: "tuning_standard", semitoneOffsets: [])
    }

    /// All available presets for a given instrument, standard tuning first.
    static func presets(for instrument: Instrument) -> [TuningPreset] {
        switch instrument {
        case .guitar:
            return [
                TuningPreset(id: "guitar_standard", nameKey: "tuning_standard", semitoneOffsets: [0, 0, 0, 0, 0, 0]),
                TuningPreset(id: "guitar_drop_d", nameKey: "tuning_drop_d", semitoneOffsets: [-2, 0, 0, 0, 0, 0]),
                TuningPreset(id: "guitar_half_step_down", nameKey: "tuning_half_step_down", semitoneOffsets: [-1, -1, -1, -1, -1, -1]),
                TuningPreset(id: "guitar_open_g", nameKey: "tuning_open_g", semitoneOffsets: [-2, -2, 0, 0, 0, -2]),
                TuningPreset(id: "guitar_dadgad", nameKey: "tuning_dadgad", semitoneOffsets: [-2, 0, 0, 0, -2, -2])
            ]
        case .bass:
            return [
                TuningPreset(id: "bass_standard", nameKey: "tuning_standard", semitoneOffsets: [0, 0, 0, 0]),
                TuningPreset(id: "bass_drop_d", nameKey: "tuning_drop_d", semitoneOffsets: [-2, 0, 0, 0]),
                TuningPreset(id: "bass_half_step_down", nameKey: "tuning_half_step_down", semitoneOffsets: [-1, -1, -1, -1])
            ]
        case .ukulele:
            return [
                TuningPreset(id: "uke_standard", nameKey: "tuning_standard", semitoneOffsets: [0, 0, 0, 0]),
                TuningPreset(id: "uke_low_g", nameKey: "tuning_low_g", semitoneOffsets: [-12, 0, 0, 0])
            ]
        case .free:
            return []
        }
    }
}

extension InstrumentString {
    /// Returns a new string shifted by the given number of semitones,
    /// recalculating frequency, note name and octave (handles negative
    /// offsets / octave rollover correctly).
    func shifted(bySemitones semitones: Int) -> InstrumentString {
        guard semitones != 0 else { return self }

        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let flatToSharp: [String: String] = ["Db": "C#", "Eb": "D#", "Gb": "F#", "Ab": "G#", "Bb": "A#"]
        let sharpName = flatToSharp[name] ?? name.replacingOccurrences(of: "b", with: "#")

        guard let baseIndex = noteNames.firstIndex(of: sharpName) else { return self }

        let total = baseIndex + semitones
        let newIndex = ((total % 12) + 12) % 12
        let octaveShift = Int(floor(Double(total) / 12.0))
        let newFrequency = frequency * pow(2.0, Double(semitones) / 12.0)

        return InstrumentString(
            name: noteNames[newIndex],
            octave: octave + octaveShift,
            frequency: newFrequency,
            stringNumber: stringNumber
        )
    }
}
