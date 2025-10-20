import Foundation
import SwiftUI

/// ViewModel for the setup screen
@MainActor
class SetupViewModel: ObservableObject {
    // MARK: - Published Properties

    // Biometric inputs
    @Published var heightValue: Double = 170
    @Published var heightUnit: HeightUnit = .cm
    @Published var weightValue: Double = 70
    @Published var weightUnit: WeightUnit = .kg

    // Speed inputs
    @Published var targetSpeedValue: Double = 6.0
    @Published var speedUnit: SpeedUnit = .mph

    // Metronome settings
    @Published var cueMode: CueMode = .everyStep
    @Published var soundSet: SoundSet = .click
    @Published var enableHaptics: Bool = false

    // Personalization
    @Published var personalizationDelta: Double = 0  // ±10 spm

    // Suggested cadence
    @Published var suggestedCadence: Double = 0

    // Services
    private let healthService: HealthServiceProtocol
    private let cadenceModel = CadenceModel()

    // MARK: - Computed Properties

    var heightInMeters: Double {
        heightUnit.toMeters(heightValue)
    }

    var weightInKg: Double {
        weightUnit.toKilograms(weightValue)
    }

    var targetSpeedMps: Double {
        speedUnit.toMetersPerSecond(targetSpeedValue)
    }

    var biometric: Biometric {
        Biometric(heightMeters: heightInMeters, weightKg: weightInKg)
    }

    // MARK: - Initialization

    init(healthService: HealthServiceProtocol = HealthService()) {
        self.healthService = healthService
        updateSuggestedCadence()
    }

    // MARK: - Methods

    func loadBiometricsFromHealth() async {
        guard healthService.isAvailable else { return }

        do {
            try await healthService.requestPermission()

            if let height = try await healthService.readHeight() {
                heightValue = heightUnit.fromMeters(height)
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

    func onSpeedChanged() {
        updateSuggestedCadence()
    }

    func onPersonalizationChanged() {
        updateSuggestedCadence()
    }

    // MARK: - Unit Conversions

    func convertHeightUnit(to newUnit: HeightUnit) {
        let meters = heightInMeters
        heightUnit = newUnit
        heightValue = newUnit.fromMeters(meters)
    }

    func convertWeightUnit(to newUnit: WeightUnit) {
        let kg = weightInKg
        weightUnit = newUnit
        weightValue = newUnit.fromKilograms(kg)
    }

    func convertSpeedUnit(to newUnit: SpeedUnit) {
        let mps = targetSpeedMps
        speedUnit = newUnit
        targetSpeedValue = newUnit.fromMetersPerSecond(mps)
    }
}
