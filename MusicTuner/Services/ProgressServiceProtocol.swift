//
//  ProgressServiceProtocol.swift
//  MusicTuner
//
//  Protocol for chord mastery progress persistence
//  Abstracted for future iCloud sync support
//

import Foundation

/// Protocol for managing Chord Mastery learning progress
/// Abstracted to allow swapping implementations (Local, iCloud, etc.)
protocol ProgressServiceProtocol {
    /// Get the current highest unlocked level (1-based)
    func getUnlockedLevel() -> Int
    
    /// Save unlocked level (only updates if higher than current)
    func saveUnlockedLevel(_ level: Int)
    
    /// Check if a specific level is unlocked
    func isLevelUnlocked(_ level: Int) -> Bool
    
    /// Get completion status for a level (optional, for showing checkmarks)
    func isLevelCompleted(_ level: Int) -> Bool
    
    /// Mark a level as completed
    func markLevelCompleted(_ level: Int)
}
