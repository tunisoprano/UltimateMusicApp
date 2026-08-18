//
//  PitchDetector.swift
//  MusicTuner
//
//  NSDF/MPM (McLeod Pitch Method) pitch detection
//  with vDSP acceleration, median filtering, and octave protection.
//
//  Uses autocorrelation-based NSDF instead of YIN's CMND because:
//  - NSDF peaks are symmetric → parabolic interpolation is unbiased
//  - YIN's CMND minima can be asymmetric → biases frequency sharp
//  - MPM peak selection is more robust than YIN's threshold approach
//

import Foundation
import Accelerate

/// Result of pitch detection containing frequency and confidence
struct PitchResult {
    let frequency: Double?
    let confidence: Double
    
    static let noDetection = PitchResult(frequency: nil, confidence: 0)
}

/// NSDF/MPM pitch detection algorithm
/// McLeod & Wyvill (2005): "A Smarter Way to Find Pitch"
/// Thread-safe: all mutable state is protected by NSLock
final class PitchDetector {
    
    // MARK: - Thread Safety
    private let lock = NSLock()
    
    // MARK: - Configuration (protected by lock)
    
    /// Minimum detectable frequency (Hz)
    private var _minF0: Double = 30.0
    var minF0: Double {
        get { lock.withLock { _minF0 } }
        set { lock.withLock { _minF0 = newValue } }
    }
    
    /// Maximum detectable frequency (Hz)
    private var _maxF0: Double = 1400.0
    var maxF0: Double {
        get { lock.withLock { _maxF0 } }
        set { lock.withLock { _maxF0 = newValue } }
    }
    
    /// User-adjustable calibration offset in cents
    private var _calibrationOffsetCents: Double = 0.0
    var calibrationOffsetCents: Double {
        get { lock.withLock { _calibrationOffsetCents } }
        set { lock.withLock { _calibrationOffsetCents = newValue } }
    }
    
    /// MPM peak selection threshold (0.0 - 1.0)
    /// Higher = more selective (fewer false positives)
    /// MPM selects the first peak above (threshold × highest_peak_value)
    private let mpmThreshold: Double = 0.88
    
    /// Minimum confidence to accept a detection
    private let confidenceThreshold: Double = 0.40
    
    // MARK: - State (protected by lock)
    
    private var _medianBuffer: [Double] = []
    private let medianBufferSize = 5
    
    private var _previousFrequency: Double = 0.0
    private var _octaveJumpCounter: Int = 0
    private let octaveJumpConfirmCount = 3
    
    // MARK: - Pitch Detection
    
    func detectPitch(buffer: [Float], sampleRate: Double) -> PitchResult {
        let n = buffer.count
        
        let (currentMinF0, currentMaxF0, calOffset) = lock.withLock {
            (_minF0, _maxF0, _calibrationOffsetCents)
        }
        
        let minLag = max(2, Int(sampleRate / currentMaxF0))
        let maxLag = min(Int(sampleRate / currentMinF0), n / 2)
        
        guard maxLag > minLag, n > maxLag else {
            return .noDetection
        }
        
        // Step 1: Compute NSDF using vDSP-accelerated autocorrelation
        let nsdf = computeNSDF(buffer: buffer, maxLag: maxLag)
        
        // Step 2: Find key maxima (peaks) in NSDF
        let peaks = findKeyMaxima(nsdf: nsdf, minLag: minLag, maxLag: maxLag)
        
        guard !peaks.isEmpty else { return .noDetection }
        
        // Step 3: MPM peak selection — pick the first peak above threshold
        guard let selectedPeak = selectBestPeak(peaks: peaks) else {
            return .noDetection
        }
        
        // Step 4: Parabolic interpolation on the NSDF peak
        // NSDF peaks are symmetric → interpolation is unbiased
        let refinedLag = parabolicPeakInterpolation(nsdf: nsdf, lag: selectedPeak.lag, maxLag: maxLag)
        
        // Step 5: Convert lag to frequency
        var frequency = sampleRate / refinedLag
        
        // Step 6: Apply calibration offset
        if calOffset != 0.0 {
            frequency = frequency * pow(2.0, calOffset / 1200.0)
        }
        
        // Validate range
        guard frequency >= currentMinF0 && frequency <= currentMaxF0 else {
            return .noDetection
        }
        
        let confidence = Double(selectedPeak.value)
        guard confidence > confidenceThreshold else { return .noDetection }
        
        // Step 7: Octave protection
        frequency = applyOctaveProtection(frequency: frequency, nsdf: nsdf, lag: selectedPeak.lag, maxLag: maxLag)
        
        guard frequency >= currentMinF0 && frequency <= currentMaxF0 else {
            return .noDetection
        }
        
        // Step 8: Median filter
        let filteredFrequency = applyMedianFilter(frequency: frequency)
        
        return PitchResult(frequency: filteredFrequency, confidence: confidence)
    }
    
    // MARK: - NSDF Computation (vDSP-accelerated)
    
    /// Compute the Normalized Square Difference Function
    /// nsdf(τ) = 2r(τ) / m(τ)
    /// where r(τ) = autocorrelation, m(τ) = running energy sum
    private func computeNSDF(buffer: [Float], maxLag: Int) -> [Float] {
        let n = buffer.count
        var nsdf = [Float](repeating: 0, count: maxLag)
        
        // Precompute cumulative energy from the right: cumRight[k] = Σ x[j]² for j=k..n-1
        // This allows O(1) computation of energy sums for each lag
        var cumRight = [Float](repeating: 0, count: n + 1)
        for j in stride(from: n - 1, through: 0, by: -1) {
            cumRight[j] = cumRight[j + 1] + buffer[j] * buffer[j]
        }
        
        // Also need cumulative energy from left: cumLeft[k] = Σ x[j]² for j=0..k-1
        var cumLeft = [Float](repeating: 0, count: n + 1)
        for j in 0..<n {
            cumLeft[j + 1] = cumLeft[j] + buffer[j] * buffer[j]
        }
        
        for tau in 0..<maxLag {
            let count = n - tau
            guard count > 0 else { continue }
            
            // Autocorrelation: r(τ) = Σ buffer[j] * buffer[j+τ] for j=0..<count
            var acf: Float = 0
            buffer.withUnsafeBufferPointer { bufPtr in
                vDSP_dotpr(bufPtr.baseAddress!, 1,
                           bufPtr.baseAddress! + tau, 1,
                           &acf, vDSP_Length(count))
            }
            
            // Energy normalization: m(τ) = Σ x[j]² for j=0..<count + Σ x[j]² for j=τ..<n
            // Using precomputed cumulative sums for O(1) lookup
            let m = cumLeft[count] + cumRight[tau]
            
            if m > 0 {
                nsdf[tau] = 2.0 * acf / m
            }
        }
        
        return nsdf
    }
    
    // MARK: - Peak Finding
    
    private struct NSDFPeak {
        let lag: Int
        let value: Float
    }
    
    /// Find all "key maxima" in the NSDF
    /// A key maximum is where the NSDF transitions from positive-slope to negative-slope
    /// and the value is positive (above zero crossing)
    private func findKeyMaxima(nsdf: [Float], minLag: Int, maxLag: Int) -> [NSDFPeak] {
        var peaks: [NSDFPeak] = []
        
        // Start from minLag, look for peaks where nsdf > 0
        var i = minLag
        while i < maxLag - 1 {
            // Find positive region
            if nsdf[i] > 0 {
                // Walk to the peak of this positive region
                var peakLag = i
                var peakValue = nsdf[i]
                
                while i + 1 < maxLag && nsdf[i + 1] > 0 {
                    i += 1
                    if nsdf[i] > peakValue {
                        peakValue = nsdf[i]
                        peakLag = i
                    }
                }
                
                peaks.append(NSDFPeak(lag: peakLag, value: peakValue))
            }
            i += 1
        }
        
        return peaks
    }
    
    /// MPM peak selection: find the first key maximum whose value is
    /// above (mpmThreshold × highest_peak_value)
    private func selectBestPeak(peaks: [NSDFPeak]) -> NSDFPeak? {
        guard !peaks.isEmpty else { return nil }
        
        // Find the highest peak value
        let maxPeakValue = peaks.max(by: { $0.value < $1.value })!.value
        
        // The threshold is relative to the highest peak
        let selectionThreshold = Float(mpmThreshold) * maxPeakValue
        
        // Return the FIRST peak that exceeds this threshold
        // This is the key insight of MPM: it picks the first "good enough" peak,
        // which corresponds to the fundamental frequency (not a harmonic)
        for peak in peaks {
            if peak.value >= selectionThreshold {
                return peak
            }
        }
        
        // Fallback: return the highest peak
        return peaks.max(by: { $0.value < $1.value })
    }
    
    // MARK: - Parabolic Interpolation (on NSDF peak)
    
    /// Parabolic interpolation around an NSDF MAXIMUM (not minimum like YIN)
    /// NSDF peaks are symmetric for periodic signals → unbiased interpolation
    private func parabolicPeakInterpolation(nsdf: [Float], lag: Int, maxLag: Int) -> Double {
        guard lag > 0 && lag < maxLag - 1 else {
            return Double(lag)
        }
        
        let s0 = Double(nsdf[lag - 1])
        let s1 = Double(nsdf[lag])
        let s2 = Double(nsdf[lag + 1])
        
        // For a maximum: delta = (s0 - s2) / (2 * (s0 - 2*s1 + s2))
        let denominator = 2.0 * (s0 - 2.0 * s1 + s2)
        
        guard abs(denominator) > 1e-12 else {
            return Double(lag)
        }
        
        let delta = (s0 - s2) / denominator
        
        // Clamp to prevent going beyond neighbors
        let clampedDelta = max(-1.0, min(1.0, delta))
        
        return Double(lag) + clampedDelta
    }
    
    // MARK: - Octave Jump Protection
    
    private func applyOctaveProtection(frequency: Double, nsdf: [Float], lag: Int, maxLag: Int) -> Double {
        let previousFreq = lock.withLock { _previousFrequency }
        
        guard previousFreq > 0 else {
            lock.withLock { _previousFrequency = frequency }
            return frequency
        }
        
        let ratio = frequency / previousFreq
        let isOctaveUp = ratio > 1.8 && ratio < 2.2
        let isOctaveDown = ratio > 0.45 && ratio < 0.55
        
        if isOctaveUp || isOctaveDown {
            var correctedFrequency = frequency
            
            if isOctaveUp {
                // Check if the sub-harmonic (double lag) has a better NSDF value
                let doubleLag = lag * 2
                if doubleLag < maxLag && nsdf[doubleLag] > nsdf[lag] * 0.8 {
                    correctedFrequency = frequency / 2.0
                }
            } else if isOctaveDown {
                let halfLag = lag / 2
                if halfLag >= 2 && halfLag < maxLag && nsdf[halfLag] > nsdf[lag] * 0.8 {
                    correctedFrequency = frequency * 2.0
                }
            }
            
            lock.withLock {
                if correctedFrequency != frequency {
                    _octaveJumpCounter = 0
                    _previousFrequency = correctedFrequency
                } else {
                    _octaveJumpCounter += 1
                    if _octaveJumpCounter >= octaveJumpConfirmCount {
                        _previousFrequency = frequency
                        _octaveJumpCounter = 0
                    }
                }
            }
            
            return correctedFrequency
        }
        
        lock.withLock {
            _previousFrequency = frequency
            _octaveJumpCounter = 0
        }
        
        return frequency
    }
    
    // MARK: - Median Filter
    
    private func applyMedianFilter(frequency: Double) -> Double {
        lock.withLock {
            _medianBuffer.append(frequency)
            if _medianBuffer.count > medianBufferSize {
                _medianBuffer.removeFirst()
            }
            
            guard _medianBuffer.count >= 3 else {
                return frequency
            }
            
            let sorted = _medianBuffer.sorted()
            return sorted[sorted.count / 2]
        }
    }
    
    // MARK: - Reset
    
    func resetState() {
        lock.withLock {
            _medianBuffer.removeAll()
            _previousFrequency = 0.0
            _octaveJumpCounter = 0
        }
    }
}

// MARK: - Frequency Range Presets

extension PitchDetector {
    func configureForGuitar() {
        minF0 = 70.0
        maxF0 = 400.0
        resetState()
    }
    
    func configureForBass() {
        minF0 = 30.0
        maxF0 = 200.0
        resetState()
    }
    
    func configureForFreeMode() {
        minF0 = 27.5
        maxF0 = 2000.0
        resetState()
    }
}
