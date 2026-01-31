//
//  EarTrainingViewModel.swift
//  MusicTuner
//
//  Game logic for Ear Training with level progression and intro flow
//

import Foundation
import SwiftUI
import Combine

// MARK: - Game State

enum EarTrainingState: Equatable {
    case selectingLevel
    case learningIntro
    case quizzing
    case summary
}

// MARK: - Game Mode

enum EarTrainingMode: String, CaseIterable {
    case learn = "Learn"
    case quiz = "Quiz"
}

// MARK: - Level Model

struct EarTrainingLevel: Identifiable {
    let id: Int
    let name: String
    let chords: [ChordDefinition]
    let requiredAccuracy: Double
    
    var isLocked: Bool {
        @AppStorage("unlockedLevel") var unlockedLevel = 1
        return id > unlockedLevel
    }
    
    static let allLevels: [EarTrainingLevel] = [
        EarTrainingLevel(id: 1, name: "Beginner", chords: ChordDatabase.earTrainingChords, requiredAccuracy: 0.7),
        EarTrainingLevel(id: 2, name: "Easy", chords: ChordDatabase.earTrainingChords, requiredAccuracy: 0.75),
        EarTrainingLevel(id: 3, name: "Medium", chords: ChordDatabase.earTrainingChords, requiredAccuracy: 0.8),
        EarTrainingLevel(id: 4, name: "Hard", chords: ChordDatabase.earTrainingChords, requiredAccuracy: 0.85),
        EarTrainingLevel(id: 5, name: "Expert", chords: ChordDatabase.earTrainingChords, requiredAccuracy: 0.9)
    ]
}

// MARK: - Quiz Result

struct QuizResult {
    let totalQuestions: Int
    let correctAnswers: Int
    let accuracy: Double
    let passed: Bool
    let unlockedNextLevel: Bool
}

// MARK: - ViewModel

@MainActor
final class EarTrainingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var gameState: EarTrainingState = .selectingLevel
    @Published var currentMode: EarTrainingMode = .learn
    @Published var selectedLevel: EarTrainingLevel = EarTrainingLevel.allLevels[0]
    @Published private(set) var unlockedLevel: Int = 1
    
    // Intro State
    @Published var introChordIndex: Int = 0
    @Published var currentIntroChord: ChordDefinition?
    
    // Quiz State
    @Published var isQuizActive = false
    @Published var timeRemaining: Int = 30
    @Published var currentChord: ChordDefinition?
    @Published var score: Int = 0
    @Published var totalQuestions: Int = 0
    @Published var lastAnswerCorrect: Bool?
    @Published var showResult: Bool = false
    @Published var quizResult: QuizResult?
    
    // MARK: - Private Properties
    private let chordEngine = ChordEngine.shared
    private var quizTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    @AppStorage("unlockedLevel") private var storedUnlockedLevel = 1
    
    // MARK: - Computed Properties
    
    var availableChords: [ChordDefinition] {
        selectedLevel.chords
    }
    
    var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(score) / Double(totalQuestions)
    }
    
    var accuracyPercentage: Int {
        Int(accuracy * 100)
    }
    
    var isLastIntroChord: Bool {
        introChordIndex >= availableChords.count - 1
    }
    
    var introProgress: String {
        "\(introChordIndex + 1) / \(availableChords.count)"
    }
    
    // MARK: - Initialization
    
    init() {
        unlockedLevel = storedUnlockedLevel
        
        Task {
            await chordEngine.initialize()
        }
    }
    
    // MARK: - Level Selection
    
    func selectLevel(_ level: EarTrainingLevel) {
        guard !level.isLocked else { return }
        selectedLevel = level
    }
    
    func isLevelUnlocked(_ level: EarTrainingLevel) -> Bool {
        level.id <= unlockedLevel
    }
    
    // MARK: - Learn Mode
    
    func playChord(_ chord: ChordDefinition) {
        currentChord = chord
        chordEngine.playChord(chord)
    }
    
    // MARK: - Learning Intro Flow
    
    func startLearningIntro() {
        guard !selectedLevel.isLocked else { return }
        
        introChordIndex = 0
        gameState = .learningIntro
        
        // Set and play first chord
        if !availableChords.isEmpty {
            currentIntroChord = availableChords[0]
            playIntroChord()
        }
    }
    
    func nextIntroChord() {
        guard introChordIndex < availableChords.count - 1 else { return }
        
        introChordIndex += 1
        currentIntroChord = availableChords[introChordIndex]
        playIntroChord()
    }
    
    func replayIntroChord() {
        playIntroChord()
    }
    
    private func playIntroChord() {
        guard let chord = currentIntroChord else { return }
        chordEngine.playChord(chord)
    }
    
    func finishIntroAndStartQuiz() {
        gameState = .quizzing
        startQuiz()
    }
    
    // MARK: - Quiz Mode
    
    func startQuiz() {
        guard !selectedLevel.isLocked else { return }
        
        // Reset state
        score = 0
        totalQuestions = 0
        timeRemaining = 30
        lastAnswerCorrect = nil
        showResult = false
        quizResult = nil
        isQuizActive = true
        gameState = .quizzing
        
        // Play first chord
        playRandomChord()
        
        // Start timer
        quizTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.timerTick()
            }
        }
    }
    
    private func timerTick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            endQuiz()
        }
    }
    
    func submitAnswer(_ chord: ChordDefinition) {
        guard isQuizActive, let current = currentChord else { return }
        
        totalQuestions += 1
        
        if chord.name == current.name {
            score += 1
            lastAnswerCorrect = true
        } else {
            lastAnswerCorrect = false
        }
        
        // Visual feedback duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.lastAnswerCorrect = nil
            self?.playRandomChord()
        }
    }
    
    private func playRandomChord() {
        guard let randomChord = availableChords.randomElement() else { return }
        currentChord = randomChord
        chordEngine.playChord(randomChord)
    }
    
    func replayCurrentChord() {
        guard let chord = currentChord else { return }
        chordEngine.playChord(chord)
    }
    
    func endQuiz() {
        quizTimer?.invalidate()
        quizTimer = nil
        isQuizActive = false
        gameState = .summary
        
        let passed = accuracy >= selectedLevel.requiredAccuracy
        var unlockedNext = false
        
        // Check if we should unlock next level
        if passed && selectedLevel.id == unlockedLevel && unlockedLevel < 5 {
            unlockedLevel += 1
            storedUnlockedLevel = unlockedLevel
            unlockedNext = true
        }
        
        quizResult = QuizResult(
            totalQuestions: totalQuestions,
            correctAnswers: score,
            accuracy: accuracy,
            passed: passed,
            unlockedNextLevel: unlockedNext
        )
        showResult = true
    }
    
    func dismissResult() {
        showResult = false
        quizResult = nil
        gameState = .selectingLevel
    }
    
    func backToLevelSelection() {
        cleanup()
        gameState = .selectingLevel
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        quizTimer?.invalidate()
        quizTimer = nil
        chordEngine.stopAllNotes()
        isQuizActive = false
        introChordIndex = 0
        currentIntroChord = nil
    }
}
