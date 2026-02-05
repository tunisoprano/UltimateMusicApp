//
//  ChordMasteryViewModel.swift
//  MusicTuner
//
//  ViewModel for Chord Mastery gamified learning module
//  Manages state machine: idle, teaching, quizzing, completed
//

import Foundation
import SwiftUI

// MARK: - Mastery State

/// State machine for Chord Mastery learning flow
enum MasteryState: Equatable {
    case idle
    case teaching(level: LevelDefinition, chordIndex: Int)
    case quizzing(level: LevelDefinition, questionIndex: Int, currentChord: ChordDefinition)
    case completed(level: LevelDefinition, score: Int, total: Int, passed: Bool)
    
    static func == (lhs: MasteryState, rhs: MasteryState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case let (.teaching(l1, i1), .teaching(l2, i2)):
            return l1.id == l2.id && i1 == i2
        case let (.quizzing(l1, i1, _), .quizzing(l2, i2, _)):
            return l1.id == l2.id && i1 == i2
        case let (.completed(l1, s1, t1, p1), .completed(l2, s2, t2, p2)):
            return l1.id == l2.id && s1 == s2 && t1 == t2 && p1 == p2
        default:
            return false
        }
    }
}

// MARK: - Quiz Question

struct QuizQuestion: Identifiable {
    let id = UUID()
    let correctChord: ChordDefinition
    let options: [ChordDefinition]
}

// MARK: - ViewModel

@MainActor
final class ChordMasteryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var state: MasteryState = .idle
    @Published private(set) var currentUnlockedLevel: Int = 1
    @Published private(set) var completedLevels: Set<Int> = []
    
    // Quiz State
    @Published private(set) var score: Int = 0
    @Published private(set) var totalQuestions: Int = 0
    @Published private(set) var questionNumber: Int = 0
    @Published var lastAnswerCorrect: Bool? = nil
    @Published var showingCorrectAnswer: Bool = false
    @Published private(set) var correctAnswerChord: ChordDefinition? = nil
    
    // Teaching State
    @Published private(set) var currentChordIndex: Int = 0
    @Published private(set) var currentLevel: LevelDefinition? = nil
    
    // MARK: - Dependencies
    
    private let progressService: ProgressServiceProtocol
    private let chordEngine = ChordEngine.shared
    
    // Quiz tracking
    private var questions: [QuizQuestion] = []
    private var currentQuestionIndex: Int = 0
    
    // MARK: - Initialization
    
    init(progressService: ProgressServiceProtocol = LocalProgressService.shared) {
        self.progressService = progressService
        loadProgress()
    }
    
    // MARK: - Public Methods
    
    /// Load current progress from storage
    func loadProgress() {
        currentUnlockedLevel = progressService.getUnlockedLevel()
        completedLevels = Set(ChordCurriculum.levels.filter { 
            progressService.isLevelCompleted($0.id) 
        }.map { $0.id })
    }
    
    /// Check if a level is unlocked
    func isLevelUnlocked(_ level: LevelDefinition) -> Bool {
        return progressService.isLevelUnlocked(level.id)
    }
    
    /// Check if a level is completed
    func isLevelCompleted(_ level: LevelDefinition) -> Bool {
        return completedLevels.contains(level.id)
    }
    
    /// Start learning a specific level
    func startLevel(_ level: LevelDefinition) {
        guard isLevelUnlocked(level) else { return }
        
        currentLevel = level
        currentChordIndex = 0
        score = 0
        questionNumber = 0
        lastAnswerCorrect = nil
        
        state = .teaching(level: level, chordIndex: 0)
        
        // Play first chord
        playCurrentChord()
    }
    
    /// Move to next chord in teaching phase
    func nextChord() {
        guard case .teaching(let level, let index) = state else { return }
        
        let nextIndex = index + 1
        if nextIndex < level.chords.count {
            currentChordIndex = nextIndex
            state = .teaching(level: level, chordIndex: nextIndex)
            playCurrentChord()
        } else {
            // Teaching complete, start quiz
            startQuiz(for: level)
        }
    }
    
    /// Move to previous chord in teaching phase
    func previousChord() {
        guard case .teaching(let level, let index) = state else { return }
        
        let prevIndex = index - 1
        if prevIndex >= 0 {
            currentChordIndex = prevIndex
            state = .teaching(level: level, chordIndex: prevIndex)
            playCurrentChord()
        }
    }
    
    /// Play the current chord sound
    func playCurrentChord() {
        guard let level = currentLevel,
              currentChordIndex < level.chords.count else { return }
        
        let chord = level.chords[currentChordIndex]
        chordEngine.playChord(chord)
    }
    
    /// Submit answer for current quiz question
    func submitAnswer(_ selectedChord: ChordDefinition) {
        guard case .quizzing(let level, let qIndex, let correctChord) = state else { return }
        
        let isCorrect = selectedChord.rootNote == correctChord.rootNote && 
                        selectedChord.type == correctChord.type
        
        lastAnswerCorrect = isCorrect
        
        if isCorrect {
            score += 1
            // Haptic feedback for correct
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } else {
            // Show correct answer and vibrate for wrong
            correctAnswerChord = correctChord
            showingCorrectAnswer = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
        
        // Move to next question after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + (isCorrect ? 0.8 : 1.5)) { [weak self] in
            self?.moveToNextQuestion(level: level, currentIndex: qIndex)
        }
    }
    
    /// Reset to idle state
    func reset() {
        state = .idle
        currentLevel = nil
        currentChordIndex = 0
        score = 0
        totalQuestions = 0
        questionNumber = 0
        lastAnswerCorrect = nil
        showingCorrectAnswer = false
        correctAnswerChord = nil
        questions = []
        currentQuestionIndex = 0
    }
    
    // MARK: - Private Methods
    
    private func startQuiz(for level: LevelDefinition) {
        // Generate quiz questions
        questions = generateQuestions(for: level)
        totalQuestions = questions.count
        currentQuestionIndex = 0
        questionNumber = 1
        score = 0
        lastAnswerCorrect = nil
        showingCorrectAnswer = false
        
        if let firstQuestion = questions.first {
            state = .quizzing(level: level, questionIndex: 0, currentChord: firstQuestion.correctChord)
        }
    }
    
    private func generateQuestions(for level: LevelDefinition) -> [QuizQuestion] {
        var questions: [QuizQuestion] = []
        let levelChords = level.chords
        
        // Each chord appears twice in the quiz
        for _ in 0..<2 {
            for chord in levelChords {
                // Generate wrong options from other level chords + some random chords
                var options = [chord]
                
                // Add other chords from this level
                let otherLevelChords = levelChords.filter { $0 != chord }
                options.append(contentsOf: otherLevelChords.shuffled().prefix(2))
                
                // If we need more options, add from other levels
                if options.count < 4 {
                    let allOtherChords = ChordDatabase.allChords.filter { 
                        !options.contains($0) && $0.type == chord.type
                    }
                    options.append(contentsOf: allOtherChords.shuffled().prefix(4 - options.count))
                }
                
                // Ensure we have exactly 4 options
                while options.count < 4 {
                    if let randomChord = ChordDatabase.allChords.filter({ !options.contains($0) }).randomElement() {
                        options.append(randomChord)
                    }
                }
                
                questions.append(QuizQuestion(
                    correctChord: chord,
                    options: options.shuffled()
                ))
            }
        }
        
        return questions.shuffled()
    }
    
    private func moveToNextQuestion(level: LevelDefinition, currentIndex: Int) {
        showingCorrectAnswer = false
        correctAnswerChord = nil
        lastAnswerCorrect = nil
        
        let nextIndex = currentIndex + 1
        if nextIndex < questions.count {
            currentQuestionIndex = nextIndex
            questionNumber = nextIndex + 1
            let nextQuestion = questions[nextIndex]
            state = .quizzing(level: level, questionIndex: nextIndex, currentChord: nextQuestion.correctChord)
        } else {
            // Quiz complete
            finishQuiz(level: level)
        }
    }
    
    private func finishQuiz(level: LevelDefinition) {
        let passed = Double(score) / Double(totalQuestions) >= level.passThreshold
        
        state = .completed(level: level, score: score, total: totalQuestions, passed: passed)
        
        if passed {
            // Mark level as completed
            progressService.markLevelCompleted(level.id)
            completedLevels.insert(level.id)
            
            // Unlock next level
            if let nextLevel = ChordCurriculum.nextLevel(after: level) {
                progressService.saveUnlockedLevel(nextLevel.id)
                currentUnlockedLevel = progressService.getUnlockedLevel()
            }
            
            // Success haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Get current teaching chord
    var currentTeachingChord: ChordDefinition? {
        guard case .teaching(let level, let index) = state else { return nil }
        return level.chords.indices.contains(index) ? level.chords[index] : nil
    }
    
    /// Get current quiz question
    var currentQuizQuestion: QuizQuestion? {
        guard case .quizzing(_, let index, _) = state else { return nil }
        return questions.indices.contains(index) ? questions[index] : nil
    }
    
    /// Score percentage
    var scorePercentage: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int((Double(score) / Double(totalQuestions)) * 100)
    }
}
