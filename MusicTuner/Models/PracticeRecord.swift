//
//  PracticeRecord.swift
//  MusicTuner
//
//  SwiftData models for the Practice Insights screen — the app previously
//  discarded every quiz's per-question results once the screen closed.
//

import Foundation
import SwiftData

/// Which training module a session belongs to.
enum PracticeModule: String, Codable, CaseIterable {
    case earTraining
    case fretboard
    case chordMastery
    case tempoTraining

    var displayName: String {
        switch self {
        case .earTraining: return L("ear_training")
        case .fretboard: return L("fretboard")
        case .chordMastery: return L("learn_chord_diagrams")
        case .tempoTraining: return L("tempo_training")
        }
    }
}

@Model
final class PracticeSession {
    var id: UUID
    var moduleRaw: String
    var date: Date
    var durationSeconds: Double
    var score: Int
    var total: Int

    @Relationship(deleteRule: .cascade, inverse: \PracticeAttempt.session)
    var attempts: [PracticeAttempt] = []

    var module: PracticeModule {
        PracticeModule(rawValue: moduleRaw) ?? .earTraining
    }

    init(module: PracticeModule, date: Date = Date(), durationSeconds: Double, score: Int, total: Int) {
        self.id = UUID()
        self.moduleRaw = module.rawValue
        self.date = date
        self.durationSeconds = durationSeconds
        self.score = score
        self.total = total
    }
}

@Model
final class PracticeAttempt {
    var id: UUID
    /// Human-readable label for what was asked, e.g. "C Major", "E string · fret 0".
    var itemLabel: String
    var isCorrect: Bool
    var timestamp: Date
    var session: PracticeSession?

    init(itemLabel: String, isCorrect: Bool, timestamp: Date = Date()) {
        self.id = UUID()
        self.itemLabel = itemLabel
        self.isCorrect = isCorrect
        self.timestamp = timestamp
    }
}
