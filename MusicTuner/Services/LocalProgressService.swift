//
//  LocalProgressService.swift
//  MusicTuner
//
//  Concrete implementation of ProgressServiceProtocol using UserDefaults
//

import Foundation
import SwiftUI

/// Local implementation of ProgressServiceProtocol using UserDefaults/AppStorage
final class LocalProgressService: ProgressServiceProtocol {
    
    // MARK: - Keys
    private enum Keys {
        static let unlockedLevel = "chordMastery_unlockedLevel"
        static let completedLevels = "chordMastery_completedLevels"
        static let etUnlockedLevel = "earTraining_unlockedLevel"
        static let etCompletedLevels = "earTraining_completedLevels"
        static let fbUnlockedLevel = "fretboard_unlockedLevel"
        static let fbCompletedLevels = "fretboard_completedLevels"
    }
    
    // MARK: - Storage
    private let defaults = UserDefaults.standard
    
    // MARK: - Singleton (optional, can also use DI)
    static let shared = LocalProgressService()
    
    init() {}
    
    // MARK: - ProgressServiceProtocol
    
    func getUnlockedLevel() -> Int {
        let level = defaults.integer(forKey: Keys.unlockedLevel)
        // Default to level 1 if not set
        return level > 0 ? level : 1
    }
    
    func saveUnlockedLevel(_ level: Int) {
        let currentLevel = getUnlockedLevel()
        // Only save if new level is higher
        if level > currentLevel {
            defaults.set(level, forKey: Keys.unlockedLevel)
        }
    }
    
    func isLevelUnlocked(_ level: Int) -> Bool {
        return level <= getUnlockedLevel()
    }
    
    func isLevelCompleted(_ level: Int) -> Bool {
        let completedLevels = getCompletedLevels()
        return completedLevels.contains(level)
    }
    
    func markLevelCompleted(_ level: Int) {
        var completedLevels = getCompletedLevels()
        if !completedLevels.contains(level) {
            completedLevels.append(level)
            defaults.set(completedLevels, forKey: Keys.completedLevels)
        }
    }
    
    // MARK: - Ear Training Progress
    
    func getEarTrainingUnlockedLevel() -> Int {
        let level = defaults.integer(forKey: Keys.etUnlockedLevel)
        return level > 0 ? level : 1
    }
    
    func saveEarTrainingUnlockedLevel(_ level: Int) {
        let currentLevel = getEarTrainingUnlockedLevel()
        if level > currentLevel {
            defaults.set(level, forKey: Keys.etUnlockedLevel)
        }
    }
    
    func isEarTrainingLevelUnlocked(_ level: Int) -> Bool {
        return level <= getEarTrainingUnlockedLevel()
    }
    
    func isEarTrainingLevelCompleted(_ level: Int) -> Bool {
        let completed = defaults.array(forKey: Keys.etCompletedLevels) as? [Int] ?? []
        return completed.contains(level)
    }
    
    func markEarTrainingLevelCompleted(_ level: Int) {
        var completed = defaults.array(forKey: Keys.etCompletedLevels) as? [Int] ?? []
        if !completed.contains(level) {
            completed.append(level)
            defaults.set(completed, forKey: Keys.etCompletedLevels)
        }
    }
    
    // MARK: - Fretboard Progress
    
    func getFretboardUnlockedLevel() -> Int {
        let level = defaults.integer(forKey: Keys.fbUnlockedLevel)
        return level > 0 ? level : 1
    }
    
    func saveFretboardUnlockedLevel(_ level: Int) {
        let currentLevel = getFretboardUnlockedLevel()
        if level > currentLevel {
            defaults.set(level, forKey: Keys.fbUnlockedLevel)
        }
    }
    
    func isFretboardLevelUnlocked(_ level: Int) -> Bool {
        return level <= getFretboardUnlockedLevel()
    }
    
    func isFretboardLevelCompleted(_ level: Int) -> Bool {
        let completed = defaults.array(forKey: Keys.fbCompletedLevels) as? [Int] ?? []
        return completed.contains(level)
    }
    
    func markFretboardLevelCompleted(_ level: Int) {
        var completed = defaults.array(forKey: Keys.fbCompletedLevels) as? [Int] ?? []
        if !completed.contains(level) {
            completed.append(level)
            defaults.set(completed, forKey: Keys.fbCompletedLevels)
        }
    }
    
    // MARK: - Private Helpers
    
    private func getCompletedLevels() -> [Int] {
        return defaults.array(forKey: Keys.completedLevels) as? [Int] ?? []
    }
}
