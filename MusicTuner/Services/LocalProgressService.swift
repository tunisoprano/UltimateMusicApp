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
    
    // MARK: - Private Helpers
    
    private func getCompletedLevels() -> [Int] {
        return defaults.array(forKey: Keys.completedLevels) as? [Int] ?? []
    }
}
