import Foundation
import SwiftUI

/// ViewModel for the setup screen
@MainActor
class SetupViewModel: ObservableObject {
    // MARK: - Published Properties

    // Biometric inputs
    @Published var heightFeet: Int = 5
    @Published var heightInches: Int = 9
    @Published var heightUnit: HeightUnit = .ftIn
    @Published var weightValue: Double = 155
    @Published var weightUnit: WeightUnit = .lbs

    // Pace inputs (minutes per distance)
    @Published var targetPaceMinutes: Double = 10.0  // Default: 10:00 min/mile
    @Published var targetPaceSeconds: Double = 0.0
    @Published var paceUnit: PaceUnit = .minPerMi

    // Metronome settings
    @Published var cueMode: CueMode = .everyStep
    @Published var soundSet: SoundSet = .click
    @Published var enableHaptics: Bool = false

    // Personalization
    @Published var personalizationDelta: Double = 0  // ±10 spm

    // Suggested cadence
    @Published var suggestedCadence: Double = 0

    // Services
    private lazy var healthService: HealthServiceProtocol = HealthService()
    private let cadenceModel = CadenceModel()

    // MARK: - Computed Properties

    var heightInMeters: Double {
        let decimalFeet = HeightUnit.inchesToFeet(heightFeet, heightInches)
        return heightUnit.toMeters(decimalFeet)
    }

    var weightInKg: Double {
        weightUnit.toKilograms(weightValue)
    }

    var targetPaceInMinutes: Double {
        targetPaceMinutes + (targetPaceSeconds / 60.0)
    }

    var targetSpeedMps: Double {
        // Convert pace (min/distance) to speed (m/s)
        let totalMinutes = targetPaceInMinutes
        guard totalMinutes > 0 else { return 3.0 } // Default fallback

        switch paceUnit {
        case .minPerKm:
            // If pace is X min/km, speed is 1000m / (X * 60s)
            return 1000.0 / (totalMinutes * 60.0)
        case .minPerMi:
            // If pace is X min/mile, speed is 1609.344m / (X * 60s)
            return 1609.344 / (totalMinutes * 60.0)
        }
    }

    var biometric: Biometric {
        Biometric(heightMeters: heightInMeters, weightKg: weightInKg)
    }

    // MARK: - Initialization

    init() {
        updateSuggestedCadence()
    }

    // MARK: - Methods

    func loadBiometricsFromHealth() async {
        guard healthService.isAvailable else { return }

        do {
            try await healthService.requestPermission()

            if let height = try await healthService.readHeight() {
                let decimalFeet = heightUnit.fromMeters(height)
                let components = HeightUnit.feetToComponents(decimalFeet)
                heightFeet = components.feet
                heightInches = components.inches
            }

            if let weight = try await healthService.readWeight() {
                weightValue = weightUnit.fromKilograms(weight)
            }

            updateSuggestedCadence()
        } catch {
            print("Failed to load HealthKit data: \(error)")
        }
    }

    func updateSuggestedCadence() {
        suggestedCadence = cadenceModel.suggestedCadence(
            biometric: biometric,
            speedMps: targetSpeedMps,
            personalizationDelta: personalizationDelta
        )
    }

    func onHeightChanged() {
        updateSuggestedCadence()
    }

    func onPaceChanged() {
        updateSuggestedCadence()
    }

    func onPersonalizationChanged() {
        updateSuggestedCadence()
    }

    // MARK: - Unit Conversions

    func convertHeightUnit(to newUnit: HeightUnit) {
        let meters = heightInMeters
        heightUnit = newUnit
        let decimalFeet = newUnit.fromMeters(meters)
        let components = HeightUnit.feetToComponents(decimalFeet)
        heightFeet = components.feet
        heightInches = components.inches
    }

    func convertWeightUnit(to newUnit: WeightUnit) {
        let kg = weightInKg
        weightUnit = newUnit
        weightValue = newUnit.fromKilograms(kg)
    }

    func convertPaceUnit(to newUnit: PaceUnit) {
        let mps = targetSpeedMps
        paceUnit = newUnit
        let totalMinutes = newUnit.fromMetersPerSecond(mps)
        targetPaceMinutes = floor(totalMinutes)
        targetPaceSeconds = (totalMinutes - targetPaceMinutes) * 60.0
    }
}
