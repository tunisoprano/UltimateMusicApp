//
//  PitchDetector.swift
//  MusicTuner
//
//  Created by MusicTuner
//

import Foundation
import Accelerate

/// Result of pitch detection containing frequency and confidence
struct PitchResult {
    let frequency: Double?
    let confidence: Double
    
    static let noDetection = PitchResult(frequency: nil, confidence: 0)
}

/// Optimized YIN Algorithm implementation for pitch detection
final class PitchDetector {
    
    // MARK: - Configuration
    
    /// Minimum detectable frequency (Hz)
    var minF0: Double = 30.0
    
    /// Maximum detectable frequency (Hz)
    var maxF0: Double = 1400.0
    
    /// Threshold for peak detection in CMND
    private let threshold: Double = 0.15
    
    /// CALIBRATION: Offset correction in cents (negative = lower the reading)
    /// User reported +10 cents sharp, so we subtract 10
    let calibrationOffsetCents: Double = -10.0
    
    // MARK: - Pitch Detection
    
    /// Detect pitch using optimized YIN algorithm
    func detectPitch(buffer: [Float], sampleRate: Double) -> PitchResult {
        let bufferSize = buffer.count
        
        // Calculate lag range based on frequency limits
        // For low bass E (~41Hz), need large maxLag: 44100/41 ≈ 1075
        let minLag = max(2, Int(sampleRate / maxF0))
        let maxLag = min(Int(sampleRate / minF0), bufferSize / 2)
        
        guard maxLag > minLag, bufferSize > maxLag else {
            return .noDetection
        }
        
        // Calculate CMND
        let cmnd = calculateCMNDOptimized(buffer: buffer, maxLag: maxLag)
        
        // Find the best lag
        guard let (lag, confidence) = findBestLag(cmnd: cmnd, minLag: minLag, maxLag: maxLag) else {
            return .noDetection
        }
        
        // Parabolic interpolation
        let refinedLag = parabolicInterpolation(cmnd: cmnd, lag: lag, maxLag: maxLag)
        
        // Convert lag to frequency
        let frequency = sampleRate / refinedLag
        
        // Validate frequency range
        guard frequency >= minF0 && frequency <= maxF0 else {
            return .noDetection
        }
        
        return PitchResult(frequency: frequency, confidence: confidence)
    }
    
    // MARK: - YIN Algorithm
    
    private func calculateCMNDOptimized(buffer: [Float], maxLag: Int) -> [Float] {
        let n = buffer.count
        var cmnd = [Float](repeating: 1.0, count: maxLag)
        var runningSum: Float = 0
        
        for tau in 1..<maxLag {
            var sum: Float = 0
            let count = n - tau
            
            if count > 0 {
                // Manual difference calculation (faster for this use case)
                for j in 0..<count {
                    let diff = buffer[j] - buffer[j + tau]
                    sum += diff * diff
                }
            }
            
            runningSum += sum
            
            if runningSum > 0 {
                cmnd[tau] = sum / (runningSum / Float(tau))
            }
        }
        
        return cmnd
    }
    
    private func findBestLag(cmnd: [Float], minLag: Int, maxLag: Int) -> (lag: Int, confidence: Double)? {
        var bestLag: Int?
        var bestValue: Float = Float.greatestFiniteMagnitude
        
        // Find first dip below threshold
        var i = minLag
        while i < maxLag - 1 {
            if cmnd[i] < Float(threshold) {
                // Find local minimum
                while i + 1 < maxLag && cmnd[i + 1] < cmnd[i] {
                    i += 1
                }
                bestLag = i
                bestValue = cmnd[i]
                break
            }
            i += 1
        }
        
        // If no threshold crossing, find global minimum
        if bestLag == nil {
            for tau in minLag..<maxLag {
                if cmnd[tau] < bestValue {
                    bestValue = cmnd[tau]
                    bestLag = tau
                }
            }
        }
        
        guard let lag = bestLag else { return nil }
        
        let confidence = Double(1.0 - min(bestValue, 1.0))
        
        // Lower confidence threshold for better detection
        guard confidence > 0.35 else { return nil }
        
        return (lag, confidence)
    }
    
    private func parabolicInterpolation(cmnd: [Float], lag: Int, maxLag: Int) -> Double {
        guard lag > 0 && lag < maxLag - 1 else {
            return Double(lag)
        }
        
        let alpha = Double(cmnd[lag - 1])
        let beta = Double(cmnd[lag])
        let gamma = Double(cmnd[lag + 1])
        
        let denominator = 2.0 * (alpha - 2.0 * beta + gamma)
        
        guard abs(denominator) > 0.0001 else {
            return Double(lag)
        }
        
        let delta = (alpha - gamma) / denominator
        return Double(lag) + delta
    }
}

// MARK: - Frequency Range Presets

extension PitchDetector {
    func configureForGuitar() {
        minF0 = 70.0
        maxF0 = 400.0
    }
    
    func configureForBass() {
        minF0 = 30.0   // E1 is ~41Hz, need headroom
        maxF0 = 200.0
    }
    
    func configureForFreeMode() {
        minF0 = 27.5
        maxF0 = 2000.0
    }
}
