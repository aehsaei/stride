import Foundation

/// Configuration constants for cadence calculation heuristic
struct CadenceModelConfig {
    static let shared = CadenceModelConfig()

    /// Baseline preferred cadence at easy pace (~3 m/s)
    let baseCadence: Double = 170

    /// Cadence adjustment per 1 m/s speed change
    let cadenceSlope: Double = 8

    /// Minimum suggested cadence (spm)
    let minCadence: Double = 155

    /// Maximum suggested cadence (spm)
    let maxCadence: Double = 195

    /// Factor to estimate leg length from height
    let legLengthFactor: Double = 0.53

    /// Lower bound for stride length as fraction of leg length
    let strideLenLowerFactor: Double = 0.7

    /// Upper bound for stride length as fraction of leg length
    let strideLenUpperFactor: Double = 1.3

    /// Nudge amount when stride is out of bounds (spm)
    let strideNudge: Double = 2.0
}

/// Cadence calculation engine
struct CadenceModel {
    private let config = CadenceModelConfig.shared

    /// Calculate optimal cadence based on biometrics and target speed
    /// - Parameters:
    ///   - biometric: User's biometric data
    ///   - speedMps: Target speed in meters per second
    ///   - personalizationDelta: User's preferred offset (±10 spm typically)
    /// - Returns: Suggested cadence in steps per minute
    func suggestedCadence(
        biometric: Biometric,
        speedMps: Double,
        personalizationDelta: Double = 0
    ) -> Double {
        let legLen = biometric.legLengthMeters

        // Start with baseline and adjust by speed
        var cadence = config.baseCadence + config.cadenceSlope * (speedMps - 3.0)

        // Clamp to reasonable range
        cadence = min(max(cadence, config.minCadence), config.maxCadence)

        // Stride length sanity check: stride = speed * 60 / cadence (in meters)
        var strideLength = speedMps * 60.0 / cadence

        // Nudge cadence if stride is unrealistic for leg length
        if strideLength < config.strideLenLowerFactor * legLen {
            // Stride too short → decrease cadence to lengthen it
            cadence -= config.strideNudge
        } else if strideLength > config.strideLenUpperFactor * legLen {
            // Stride too long → increase cadence to shorten it
            cadence += config.strideNudge
        }

        // Apply user personalization
        cadence += personalizationDelta

        // Final clamp
        return min(max(cadence, config.minCadence), config.maxCadence)
    }

    /// Calculate stride length for given speed and cadence
    func strideLength(speedMps: Double, cadence: Double) -> Double {
        guard cadence > 0 else { return 0 }
        return speedMps * 60.0 / cadence
    }

    /// Validate if stride length is reasonable for given leg length
    func isStrideLengthReasonable(strideMeters: Double, legLengthMeters: Double) -> Bool {
        let lower = config.strideLenLowerFactor * legLengthMeters
        let upper = config.strideLenUpperFactor * legLengthMeters
        return strideMeters >= lower && strideMeters <= upper
    }
}
