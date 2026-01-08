//
//  NoteDisplayView.swift
//  MusicTuner
//
//  Created by MusicTuner
//

import SwiftUI

/// Large note name display component
struct NoteDisplayView: View {
    let note: Note?
    let tuningState: TuningState
    
    var body: some View {
        ZStack {
            // Glow effect
            if note != nil {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [glowColor.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .animation(.easeInOut(duration: 0.3), value: tuningState)
            }
            
            // Main circle
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 160, height: 160)
                .overlay(
                    Circle()
                        .stroke(borderGradient, lineWidth: 3)
                )
            
            // Note content
            if let note = note {
                VStack(spacing: 4) {
                    // Note name (formatted based on user preference)
                    HStack(alignment: .top, spacing: 2) {
                        Text(formattedNoteLetter)
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        // Accidental (sharp/flat)
                        if let accidental = noteAccidental {
                            Text(accidental)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white.opacity(0.8))
                                .offset(y: 8)
                        }
                    }
                    
                    // Octave
                    Text("\(note.octave)")
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .foregroundStyle(.gray)
                }
            } else {
                // No note detected
                VStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray)
                    Text("--")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.gray)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Formatted note letter using NoteFormatter (supports English/Solfege)
    private var formattedNoteLetter: String {
        guard let note = note else { return "--" }
        let baseLetter = String(note.name.prefix(1))
        return NoteFormatter.format(baseLetter)
    }
    
    private var noteAccidental: String? {
        guard let note = note, note.name.count > 1 else { return nil }
        let suffix = String(note.name.dropFirst())
        switch suffix {
        case "#": return "♯"
        case "b": return "♭"
        default: return suffix
        }
    }
    
    private var glowColor: Color {
        switch tuningState {
        case .inTune:
            return .green
        case .close:
            return .yellow
        case .sharp, .flat:
            return .red
        case .noSignal:
            return .gray
        }
    }
    
    private var borderGradient: some ShapeStyle {
        switch tuningState {
        case .inTune:
            return AnyShapeStyle(LinearGradient(
                colors: [.green, .green.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        case .close:
            return AnyShapeStyle(LinearGradient(
                colors: [.yellow, .yellow.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        case .sharp, .flat:
            return AnyShapeStyle(LinearGradient(
                colors: [.red, .red.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        case .noSignal:
            return AnyShapeStyle(Color.gray.opacity(0.3))
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 40) {
            NoteDisplayView(
                note: Note(name: "A", octave: 4, frequency: 440),
                tuningState: .inTune
            )
            NoteDisplayView(
                note: Note(name: "C#", octave: 3, frequency: 277.18),
                tuningState: .sharp
            )
            NoteDisplayView(
                note: nil,
                tuningState: .noSignal
            )
        }
    }
}
