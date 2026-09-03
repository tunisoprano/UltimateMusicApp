//
//  ExerciseViewModel.swift
//  MusicTuner
//
//  ViewModel for Fretboard Training
//  State machine: idle → teaching → quizzing → completed
//  Uses AudioManager for microphone pitch detection
//

import Foundation
import SwiftUI
import AVFoundation
import UIKit
import AudioToolbox

// MARK: - Fretboard State

enum FretboardState: Equatable {
    case idle
    case teaching(level: FretboardLevel, noteIndex: Int)
    case quizzing(level: FretboardLevel, questionIndex: Int, question: ExerciseQuestion)
    case completed(level: FretboardLevel, score: Int, total: Int, passed: Bool)
    
    static func == (lhs: FretboardState, rhs: FretboardState) -> Bool {
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

// MARK: - ViewModel

@MainActor
final class ExerciseViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var state: FretboardState = .idle
    @Published private(set) var currentUnlockedLevel: Int = 1
    @Published private(set) var completedLevels: Set<Int> = []
    
    // Instrument
    @Published var selectedInstrument: Instrument = .guitar
    
    // Quiz State
    @Published private(set) var score: Int = 0
    @Published private(set) var totalQuestions: Int = 0
    @Published private(set) var questionNumber: Int = 0
    @Published var isCorrect: Bool = false
    @Published var showSuccess: Bool = false
    @Published var isMatchingTarget: Bool = false
    
    // Teaching State
    @Published private(set) var currentNoteIndex: Int = 0
    @Published private(set) var currentLevel: FretboardLevel? = nil
    
    // Audio
    @Published private(set) var isListening: Bool = false
    @Published var errorMessage: String? = nil
    
    // MARK: - Streak
    var streakCount: Int {
        StreakManager.shared.currentStreak
    }
    
    // MARK: - Dependencies
    
    private let progressService: ProgressServiceProtocol
    private let audioManager: AudioManager
    
    // Quiz tracking
    private var questions: [ExerciseQuestion] = []
    private var currentQuestionIndex: Int = 0
    private var monitorTimer: Timer?
    private var correctHoldDuration: TimeInterval = 0
    private let requiredHoldDuration: TimeInterval = 0.5
    private var missedTickStreak: Int = 0
    private let maxMissedTicksBeforeReset: Int = 3 // ~150ms of grace for brief mic dropouts/vibrato
    private var successSoundID: SystemSoundID = 1057
    private var hasRecordedTodaySession = false
    private let noteAnnouncer = NoteAnnouncer()
    @AppStorage("handsFreeModeEnabled") private var handsFreeModeEnabled: Bool = false
    
    // Teaching notes
    private var teachingNotes: [ExerciseQuestion] = []
    
    // MARK: - Computed Properties
    
    var detectedFrequency: Double { audioManager.detectedFrequency }
    var detectedNote: Note? { audioManager.detectedNote }
    
    var scorePercentage: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int((Double(score) / Double(totalQuestions)) * 100)
    }
    
    var progressPercentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(score) / Double(totalQuestions) * 100
    }
    
    // MARK: - Initialization
    
    init(progressService: ProgressServiceProtocol = LocalProgressService.shared,
         audioManager: AudioManager = .shared) {
        self.progressService = progressService
        self.audioManager = audioManager
        loadProgress()
    }
    
    // MARK: - Progress
    
    func loadProgress() {
        currentUnlockedLevel = progressService.getFretboardUnlockedLevel()
        completedLevels = Set(FretboardCurriculum.levels.filter {
            progressService.isFretboardLevelCompleted($0.id)
        }.map { $0.id })
    }
    
    func isLevelUnlocked(_ level: FretboardLevel) -> Bool {
        progressService.isFretboardLevelUnlocked(level.id)
    }
    
    func isLevelCompleted(_ level: FretboardLevel) -> Bool {
        completedLevels.contains(level.id)
    }
    
    // MARK: - Instrument Selection
    
    func selectInstrument(_ instrument: Instrument) {
        selectedInstrument = instrument
        audioManager.configureForInstrument(instrument)
    }
    
    // MARK: - Start Level (Teaching Phase)
    
    func startLevel(_ level: FretboardLevel) {
        guard isLevelUnlocked(level) else { return }
        
        currentLevel = level
        currentNoteIndex = 0
        score = 0
        questionNumber = 0
        isCorrect = false
        showSuccess = false
        
        // Generate teaching notes (one per string/fret combo for this level)
        teachingNotes = generateTeachingNotes(for: level)
        
        state = .teaching(level: level, noteIndex: 0)
    }
    
    private func generateTeachingNotes(for level: FretboardLevel) -> [ExerciseQuestion] {
        let strings = selectedInstrument.strings
        var notes: [ExerciseQuestion] = []
        
        // Show key notes for each string in this fret range
        for string in strings {
            // Show 0, middle, and max fret for the range
            let frets = Set([level.fretRange.lowerBound, level.fretRange.upperBound])
            for fret in frets.sorted() {
                notes.append(ExerciseQuestion(instrumentString: string, fret: fret))
            }
        }
        
        return notes
    }
    
    /// Move to next note in teaching phase
    func nextTeachingNote() {
        guard case .teaching(let level, let index) = state else { return }
        
        let nextIndex = index + 1
        if nextIndex < teachingNotes.count {
            currentNoteIndex = nextIndex
            state = .teaching(level: level, noteIndex: nextIndex)
        }
    }
    
    /// Move to previous note in teaching phase
    func previousTeachingNote() {
        guard case .teaching(let level, let index) = state else { return }
        
        if index > 0 {
            currentNoteIndex = index - 1
            state = .teaching(level: level, noteIndex: index - 1)
        }
    }
    
    /// Current teaching note
    var currentTeachingNote: ExerciseQuestion? {
        guard case .teaching(_, let index) = state else { return nil }
        return teachingNotes.indices.contains(index) ? teachingNotes[index] : nil
    }
    
    // MARK: - Start Quiz
    
    func startQuiz(for level: FretboardLevel) async {
        // Generate quiz questions
        questions = generateQuizQuestions(for: level)
        totalQuestions = questions.count
        currentQuestionIndex = 0
        questionNumber = 1
        score = 0
        isCorrect = false
        showSuccess = false
        hasRecordedTodaySession = false
        errorMessage = nil
        
        // Start audio
        do {
            audioManager.configureForInstrument(selectedInstrument)
            try await audioManager.start()
            isListening = true
            
            if let first = questions.first {
                state = .quizzing(level: level, questionIndex: 0, question: first)
                announceIfEnabled(first)
            }

            // Start pitch monitoring
            startMonitoring()
        } catch {
            errorMessage = error.localizedDescription
            isListening = false
        }
    }
    
    private func generateQuizQuestions(for level: FretboardLevel) -> [ExerciseQuestion] {
        let strings = selectedInstrument.strings
        var qs: [ExerciseQuestion] = []
        
        // Generate random questions covering the fret range
        let questionCount = max(8, strings.count * 2)
        
        for _ in 0..<questionCount {
            guard let randomString = strings.randomElement() else { continue }
            let randomFret = Int.random(in: level.fretRange)
            qs.append(ExerciseQuestion(instrumentString: randomString, fret: randomFret))
        }
        
        return qs.shuffled()
    }
    
    // MARK: - Monitoring
    
    private func startMonitoring() {
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPitchMatch()
            }
        }
    }
    
    private func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }
    
    private func checkPitchMatch() {
        guard isListening,
              case .quizzing(_, _, let question) = state else { return }

        guard detectedFrequency > 0 else {
            registerMissedTick()
            return
        }

        let matches = NoteUtility.frequencyMatches(detectedFrequency, target: question.targetFrequency, toleranceCents: 15)
        isMatchingTarget = matches

        if matches {
            missedTickStreak = 0
            correctHoldDuration += 0.05

            if correctHoldDuration >= requiredHoldDuration && !isCorrect {
                handleCorrectAnswer()
            }
        } else {
            registerMissedTick()
        }
    }

    /// A brief mic dropout, vibrato wobble, or transient octave-jump correction
    /// shouldn't wipe out an otherwise-sustained correct hold. Only reset after
    /// a short streak of consecutive misses.
    private func registerMissedTick() {
        isMatchingTarget = false
        missedTickStreak += 1
        if missedTickStreak >= maxMissedTicksBeforeReset {
            correctHoldDuration = 0
        }
    }
    
    private func handleCorrectAnswer() {
        guard case .quizzing(let level, let qIndex, _) = state else { return }

        isCorrect = true
        showSuccess = true
        score += 1
        noteAnnouncer.stopRepeating()
        
        // Streak
        if !hasRecordedTodaySession {
            hasRecordedTodaySession = true
            StreakManager.shared.markDailyActivity()
        }
        
        // Sound + haptic
        AudioServicesPlaySystemSound(successSoundID)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Next question after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.moveToNextQuestion(level: level, currentIndex: qIndex)
        }
    }
    
    func skipQuestion() {
        guard case .quizzing(let level, let qIndex, _) = state else { return }
        moveToNextQuestion(level: level, currentIndex: qIndex)
    }
    
    private func moveToNextQuestion(level: FretboardLevel, currentIndex: Int) {
        isCorrect = false
        showSuccess = false
        isMatchingTarget = false
        correctHoldDuration = 0
        missedTickStreak = 0
        noteAnnouncer.stopRepeating()

        let nextIndex = currentIndex + 1
        if nextIndex < questions.count {
            currentQuestionIndex = nextIndex
            questionNumber = nextIndex + 1
            let nextQuestion = questions[nextIndex]
            state = .quizzing(level: level, questionIndex: nextIndex, question: nextQuestion)
            announceIfEnabled(nextQuestion)
        } else {
            finishQuiz(level: level)
        }
    }

    /// Speaks the target string + note aloud when Hands-Free Mode is enabled,
    /// so the player doesn't need to look at the screen to know what to play.
    private func announceIfEnabled(_ question: ExerciseQuestion) {
        guard handsFreeModeEnabled else { return }
        noteAnnouncer.announce(stringNumber: question.instrumentString.stringNumber, noteName: question.noteName)
    }

    private func finishQuiz(level: FretboardLevel) {
        stopMonitoring()
        noteAnnouncer.stopRepeating()
        audioManager.stop()
        isListening = false
        
        let passed = Double(score) / Double(totalQuestions) >= level.passThreshold
        
        state = .completed(level: level, score: score, total: totalQuestions, passed: passed)
        
        if passed {
            progressService.markFretboardLevelCompleted(level.id)
            completedLevels.insert(level.id)
            
            if let next = FretboardCurriculum.nextLevel(after: level) {
                progressService.saveFretboardUnlockedLevel(next.id)
                currentUnlockedLevel = progressService.getFretboardUnlockedLevel()
            }
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        
        AdsManager.shared.showInterstitial()
        StreakManager.shared.markDailyActivity()
    }
    
    // MARK: - Reset
    
    func reset() {
        stopMonitoring()
        noteAnnouncer.stopRepeating()
        if isListening {
            audioManager.stop()
            isListening = false
        }
        state = .idle
        currentLevel = nil
        currentNoteIndex = 0
        score = 0
        totalQuestions = 0
        questionNumber = 0
        isCorrect = false
        showSuccess = false
        isMatchingTarget = false
        correctHoldDuration = 0
        missedTickStreak = 0
        questions = []
        teachingNotes = []
        errorMessage = nil
    }
    
    func stopExercise() {
        reset()
    }
}
