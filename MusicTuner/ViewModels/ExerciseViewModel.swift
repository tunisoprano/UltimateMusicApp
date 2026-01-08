//
//  ExerciseViewModel.swift
//  MusicTuner
//
//  Created by MusicTuner
//

import Foundation
import SwiftUI
import AVFoundation
import UIKit
import AudioToolbox

/// ViewModel for the Exercise view (gamified fretboard training)
@MainActor
final class ExerciseViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedInstrument: Instrument = .guitar
    @Published var selectedLevel: ExerciseLevel = .openStrings
    @Published var currentQuestion: ExerciseQuestion?
    @Published var isListening = false
    @Published var isCorrect = false
    @Published var showSuccess = false
    @Published var score: Int = 0
    @Published var totalQuestions: Int = 0
    @Published var errorMessage: String?
    
    // MARK: - Daily Streak (AppStorage)
    @AppStorage("lastExerciseDate") private var lastExerciseDateString: String = ""
    @AppStorage("currentStreak") private var storedStreak: Int = 0
    
    var streakCount: Int {
        storedStreak
    }
    
    // MARK: - Private Properties
    private let audioManager: AudioManager
    private var correctHoldTimer: Timer?
    private var correctHoldDuration: TimeInterval = 0
    private let requiredHoldDuration: TimeInterval = 0.5
    
    private var successSoundID: SystemSoundID = 0
    private var hasRecordedTodaySession = false
    
    // MARK: - Computed Properties
    
    var detectedFrequency: Double {
        audioManager.detectedFrequency
    }
    
    var detectedNote: Note? {
        audioManager.detectedNote
    }
    
    var progressPercentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(score) / Double(totalQuestions) * 100
    }
    
    var isMatchingTarget: Bool {
        guard let question = currentQuestion,
              detectedFrequency > 0 else {
            return false
        }
        
        return NoteUtility.frequencyMatches(detectedFrequency, target: question.targetFrequency, toleranceCents: 15)
    }
    
    // MARK: - Initialization
    
    init(audioManager: AudioManager = .shared) {
        self.audioManager = audioManager
        setupSuccessSound()
        checkAndUpdateStreak()
    }
    
    // MARK: - Sound Setup
    
    private func setupSuccessSound() {
        successSoundID = 1057
    }
    
    private func playSuccessSound() {
        AudioServicesPlaySystemSound(successSoundID)
    }
    
    // MARK: - Streak Management
    
    private func checkAndUpdateStreak() {
        let today = dateString(for: Date())
        
        if lastExerciseDateString.isEmpty {
            // First time user
            return
        }
        
        let yesterday = dateString(for: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        
        if lastExerciseDateString == today {
            // Already exercised today
            return
        } else if lastExerciseDateString == yesterday {
            // Consecutive day - streak continues (will increment when exercise completes)
            return
        } else {
            // Missed a day - reset streak
            storedStreak = 0
        }
    }
    
    private func recordExerciseSession() {
        guard !hasRecordedTodaySession else { return }
        
        let today = dateString(for: Date())
        let yesterday = dateString(for: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        
        if lastExerciseDateString == today {
            // Already recorded today
            return
        } else if lastExerciseDateString == yesterday || lastExerciseDateString.isEmpty {
            // Consecutive day or first exercise - increment streak
            storedStreak += 1
        } else {
            // Missed days - start fresh
            storedStreak = 1
        }
        
        lastExerciseDateString = today
        hasRecordedTodaySession = true
    }
    
    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // MARK: - Actions
    
    func startExercise() async {
        errorMessage = nil
        score = 0
        totalQuestions = 0
        hasRecordedTodaySession = false
        
        do {
            try await audioManager.start()
            isListening = true
            generateNextQuestion()
            startMonitoring()
        } catch {
            errorMessage = error.localizedDescription
            isListening = false
        }
    }
    
    func stopExercise() {
        audioManager.stop()
        isListening = false
        correctHoldTimer?.invalidate()
        correctHoldTimer = nil
        currentQuestion = nil
    }
    
    func generateNextQuestion() {
        let strings = selectedInstrument.strings
        let fretRange = selectedLevel.fretRange
        
        guard let randomString = strings.randomElement() else { return }
        let randomFret = Int.random(in: fretRange)
        
        currentQuestion = ExerciseQuestion(instrumentString: randomString, fret: randomFret)
        isCorrect = false
        showSuccess = false
        correctHoldDuration = 0
    }
    
    func skipQuestion() {
        totalQuestions += 1
        generateNextQuestion()
    }
    
    // MARK: - Monitoring
    
    private func startMonitoring() {
        correctHoldTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPitchMatch()
            }
        }
    }
    
    private func checkPitchMatch() {
        guard isListening, currentQuestion != nil else { return }
        
        if isMatchingTarget {
            correctHoldDuration += 0.05
            
            if correctHoldDuration >= requiredHoldDuration && !isCorrect {
                handleCorrectAnswer()
            }
        } else {
            correctHoldDuration = 0
        }
    }
    
    private func handleCorrectAnswer() {
        isCorrect = true
        showSuccess = true
        score += 1
        totalQuestions += 1
        
        // Record daily streak on first correct answer
        recordExerciseSession()
        
        playSuccessSound()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.showSuccess = false
            self?.generateNextQuestion()
        }
    }
    
    // MARK: - Level Selection
    
    func selectLevel(_ level: ExerciseLevel) {
        selectedLevel = level
        if isListening {
            generateNextQuestion()
        }
    }
    
    // MARK: - Instrument Selection
    
    func selectInstrument(_ instrument: Instrument) {
        selectedInstrument = instrument
        if isListening {
            generateNextQuestion()
        }
    }
}
