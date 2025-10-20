import XCTest
@testable import Stride

final class CadenceModelTests: XCTestCase {
    var cadenceModel: CadenceModel!

    override func setUp() {
        super.setUp()
        cadenceModel = CadenceModel()
    }

    override func tearDown() {
        cadenceModel = nil
        super.tearDown()
    }

    // MARK: - Cadence Calculation Tests

    func testSuggestedCadence_WalkingSpeed() {
        // Given: Walking speed (1.5 m/s ~ 3.4 mph)
        let biometric = Biometric(heightMeters: 1.75, weightKg: 70)
        let speedMps = 1.5

        // When: Calculate suggested cadence
        let cadence = cadenceModel.suggestedCadence(
            biometric: biometric,
            speedMps: speedMps,
            personalizationDelta: 0
        )

        // Then: Should be significantly below base cadence
        // At 1.5 m/s, that's -1.5 m/s from baseline of 3.0 m/s
        // With slope of ±8 spm per m/s: 170 - (8 * 1.5) = 158 spm
        XCTAssertEqual(cadence, 158.0, accuracy: 2.0)
    }

    func testSuggestedCadence_JoggingSpeed() {
        // Given: Jogging speed (3.0 m/s ~ 6.7 mph)
        let biometric = Biometric(heightMeters: 1.75, weightKg: 70)
        let speedMps = 3.0

        // When: Calculate suggested cadence
        let cadence = cadenceModel.suggestedCadence(
            biometric: biometric,
            speedMps: speedMps,
            personalizationDelta: 0
        )

        // Then: Should be at base cadence (170 spm)
        XCTAssertEqual(cadence, 170.0, accuracy: 2.0)
    }

    func testSuggestedCadence_RunningSpeed() {
        // Given: Running speed (4.5 m/s ~ 10 mph)
        let biometric = Biometric(heightMeters: 1.75, weightKg: 70)
        let speedMps = 4.5

        // When: Calculate suggested cadence
        let cadence = cadenceModel.suggestedCadence(
            biometric: biometric,
            speedMps: speedMps,
            personalizationDelta: 0
        )

        // Then: Should be above base cadence
        // At 4.5 m/s, that's +1.5 m/s from baseline
        // With slope of ±8 spm per m/s: 170 + (8 * 1.5) = 182 spm
        XCTAssertEqual(cadence, 182.0, accuracy: 2.0)
    }

    func testSuggestedCadence_WithPersonalizationDelta() {
        // Given: Standard biometric with +5 personalization
        let biometric = Biometric(heightMeters: 1.75, weightKg: 70)
        let speedMps = 3.0

        // When: Calculate with personalization delta
        let cadence = cadenceModel.suggestedCadence(
            biometric: biometric,
            speedMps: speedMps,
            personalizationDelta: 5
        )

        // Then: Should be base + personalization (170 + 5 = 175)
        XCTAssertEqual(cadence, 175.0, accuracy: 1.0)
    }

    func testSuggestedCadence_WithNegativePersonalizationDelta() {
        // Given: Standard biometric with -5 personalization
        let biometric = Biometric(heightMeters: 1.75, weightKg: 70)
        let speedMps = 3.0

        // When: Calculate with negative personalization delta
        let cadence = cadenceModel.suggestedCadence(
            biometric: biometric,
            speedMps: speedMps,
            personalizationDelta: -5
        )

        // Then: Should be base - personalization (170 - 5 = 165)
        XCTAssertEqual(cadence, 165.0, accuracy: 1.0)
    }

    // MARK: - Cadence Range Tests

    func testSuggestedCadence_MinimumClamp() {
        // Given: Very slow speed
        let biometric = Biometric(heightMeters: 1.75, weightKg: 70)
        let speedMps = 0.5

        // When: Calculate suggested cadence
        let cadence = cadenceModel.suggestedCadence(
            biometric: biometric,
            speedMps: speedMps,
            personalizationDelta: 0
        )

        // Then: Should be clamped to minimum (150 spm)
        XCTAssertGreaterThanOrEqual(cadence, 150.0)
    }

    func testSuggestedCadence_MaximumClamp() {
        // Given: Very fast speed
        let biometric = Biometric(heightMeters: 1.75, weightKg: 70)
        let speedMps = 10.0

        // When: Calculate suggested cadence
        let cadence = cadenceModel.suggestedCadence(
            biometric: biometric,
            speedMps: speedMps,
            personalizationDelta: 0
        )

        // Then: Should be clamped to maximum (190 spm)
        XCTAssertLessThanOrEqual(cadence, 190.0)
    }

    // MARK: - Real World Pace Tests

    func testCadenceForTypicalPaces() {
        let biometric = Biometric(heightMeters: 1.75, weightKg: 70)

        // Test common running paces
        let testCases: [(paceMin: Double, unit: PaceUnit, expectedCadence: Double)] = [
            // Easy pace: 12:00 min/mile = 2.24 m/s
            (12.0, .minPerMi, 164),
            // Moderate pace: 10:00 min/mile = 2.68 m/s
            (10.0, .minPerMi, 168),
            // Fast pace: 8:00 min/mile = 3.35 m/s
            (8.0, .minPerMi, 173),
            // Very fast pace: 7:00 min/mile = 3.83 m/s
            (7.0, .minPerMi, 177),
            // Easy pace: 7:00 min/km = 2.38 m/s
            (7.0, .minPerKm, 165),
            // Moderate pace: 6:00 min/km = 2.78 m/s
            (6.0, .minPerKm, 168),
            // Fast pace: 5:00 min/km = 3.33 m/s
            (5.0, .minPerKm, 173),
        ]

        for testCase in testCases {
            // Convert pace to speed
            let speedMps: Double
            switch testCase.unit {
            case .minPerKm:
                speedMps = 1000.0 / (testCase.paceMin * 60.0)
            case .minPerMi:
                speedMps = 1609.344 / (testCase.paceMin * 60.0)
            }

            let cadence = cadenceModel.suggestedCadence(
                biometric: biometric,
                speedMps: speedMps,
                personalizationDelta: 0
            )

            XCTAssertEqual(
                cadence,
                testCase.expectedCadence,
                accuracy: 5.0,
                "Pace: \(testCase.paceMin) \(testCase.unit.rawValue), Speed: \(speedMps) m/s"
            )
        }
    }

    // MARK: - Stride Length Validation Tests

    func testStrideLength_WithinReasonableBounds() {
        // Given: Standard biometric
        let biometric = Biometric(heightMeters: 1.75, weightKg: 70)
        let speedMps = 3.0

        // When: Calculate cadence
        let cadence = cadenceModel.suggestedCadence(
            biometric: biometric,
            speedMps: speedMps,
            personalizationDelta: 0
        )

        // Then: Calculate resulting stride length
        let stepsPerSecond = cadence / 60.0
        let strideLength = speedMps / stepsPerSecond

        // Stride length should be reasonable (0.5 to 2.0 meters)
        XCTAssertGreaterThan(strideLength, 0.5)
        XCTAssertLessThan(strideLength, 2.0)

        // More specifically, for 1.75m height at moderate pace:
        // Should be around 1.05 meters
        XCTAssertEqual(strideLength, 1.06, accuracy: 0.2)
    }

    func testStrideLength_TallerRunner() {
        // Given: Taller runner (1.90m ~ 6'3")
        let biometric = Biometric(heightMeters: 1.90, weightKg: 80)
        let speedMps = 3.0

        // When: Calculate cadence
        let cadence = cadenceModel.suggestedCadence(
            biometric: biometric,
            speedMps: speedMps,
            personalizationDelta: 0
        )

        // Then: Should still be in reasonable range
        // Taller runners typically have longer strides, so might have slightly lower cadence
        // But the model should keep cadence relatively consistent
        XCTAssertGreaterThanOrEqual(cadence, 165.0)
        XCTAssertLessThanOrEqual(cadence, 175.0)
    }

    func testStrideLength_ShorterRunner() {
        // Given: Shorter runner (1.60m ~ 5'3")
        let biometric = Biometric(heightMeters: 1.60, weightKg: 60)
        let speedMps = 3.0

        // When: Calculate cadence
        let cadence = cadenceModel.suggestedCadence(
            biometric: biometric,
            speedMps: speedMps,
            personalizationDelta: 0
        )

        // Then: Should still be in reasonable range
        // Shorter runners typically have shorter strides
        // But the model should keep cadence relatively consistent
        XCTAssertGreaterThanOrEqual(cadence, 165.0)
        XCTAssertLessThanOrEqual(cadence, 175.0)
    }

    // MARK: - Edge Cases

    func testSuggestedCadence_ZeroSpeed() {
        let biometric = Biometric(heightMeters: 1.75, weightKg: 70)
        let cadence = cadenceModel.suggestedCadence(
            biometric: biometric,
            speedMps: 0,
            personalizationDelta: 0
        )

        // Should return minimum cadence or base cadence
        XCTAssertGreaterThanOrEqual(cadence, 150.0)
        XCTAssertLessThanOrEqual(cadence, 170.0)
    }

    func testSuggestedCadence_NegativeSpeed() {
        // Edge case: negative speed (shouldn't happen in practice)
        let biometric = Biometric(heightMeters: 1.75, weightKg: 70)
        let cadence = cadenceModel.suggestedCadence(
            biometric: biometric,
            speedMps: -1.0,
            personalizationDelta: 0
        )

        // Should still return valid cadence
        XCTAssertGreaterThanOrEqual(cadence, 150.0)
        XCTAssertLessThanOrEqual(cadence, 190.0)
    }
}
