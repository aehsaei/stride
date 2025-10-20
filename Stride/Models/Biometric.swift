import Foundation

/// User biometric data
struct Biometric: Codable {
    var heightMeters: Double
    var weightKg: Double?

    init(heightMeters: Double, weightKg: Double? = nil) {
        self.heightMeters = heightMeters
        self.weightKg = weightKg
    }

    /// Estimated leg length using standard biomechanical factor
    var legLengthMeters: Double {
        CadenceModelConfig.shared.legLengthFactor * heightMeters
    }
}
