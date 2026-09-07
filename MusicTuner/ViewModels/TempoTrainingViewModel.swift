//
//  TempoTrainingViewModel.swift
//  MusicTuner
//
//  Game logic for Tempo Training: plays a hidden random tempo, checks the
//  player's guess within a tolerance, and auto-advances to the next round.
//

import Foundation

/// Time signature mode the player picks before starting a session
enum TempoSignatureChoice: String, CaseIterable, Identifiable {
    case twoFour = "2/4"
    case threeFour = "3/4"
    case fourFour = "4/4"
    case mixed

    var id: String { rawValue }

    private static let selectable: [TimeSignature] = [.twoFour, .threeFour, .fourFour]

    /// Resolves this choice to a concrete engine time signature, re-rolling each call for `.mixed`
    func randomSignature() -> TimeSignature {
        switch self {
        case .twoFour: return .twoFour
        case .threeFour: return .threeFour
        case .fourFour: return .fourFour
        case .mixed: return Self.selectable.randomElement()!
        }
    }

    var localizedTitle: String {
        self == .mixed ? L("mixed") : rawValue
    }
}

@MainActor
final class TempoTrainingViewModel: ObservableObject {
    let engine = MetronomeEngine()

    struct RoundResult {
        let isCorrect: Bool
        let actualBPM: Int
        let guessedBPM: Int
    }

    @Published var guessBPM: Double = 120
    @Published private(set) var targetBPM: Int = 120
    @Published private(set) var lastResult: RoundResult? = nil
    @Published private(set) var correctCount: Int = 0
    @Published private(set) var totalCount: Int = 0

    private let tolerance = 5
    private let autoAdvanceDelay: TimeInterval = 1.8
    private var signatureChoice: TempoSignatureChoice = .fourFour
    private var advanceWorkItem: DispatchWorkItem?

    func begin(with choice: TempoSignatureChoice) {
        signatureChoice = choice
        correctCount = 0
        totalCount = 0
        startNewRound()
    }

    func startNewRound() {
        advanceWorkItem?.cancel()
        lastResult = nil
        guessBPM = 120
        targetBPM = Int.random(in: Int(engine.minBPM)...Int(engine.maxBPM))
        engine.timeSignature = signatureChoice.randomSignature()
        engine.setBPM(Double(targetBPM))
        if !engine.isPlaying {
            engine.start()
        }
    }

    func submitGuess() {
        guard lastResult == nil else { return }

        let guessed = Int(guessBPM.rounded())
        let isCorrect = abs(guessed - targetBPM) <= tolerance

        lastResult = RoundResult(isCorrect: isCorrect, actualBPM: targetBPM, guessedBPM: guessed)
        totalCount += 1
        if isCorrect { correctCount += 1 }

        let workItem = DispatchWorkItem { [weak self] in
            self?.startNewRound()
        }
        advanceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + autoAdvanceDelay, execute: workItem)
    }

    func togglePlayback() {
        engine.toggle()
    }

    func cleanup() {
        advanceWorkItem?.cancel()
        engine.cleanup()
    }
}
