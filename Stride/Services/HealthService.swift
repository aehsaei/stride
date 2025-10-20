import Foundation
import HealthKit

/// Protocol for HealthKit services (enables mocking)
@MainActor
protocol HealthServiceProtocol {
    var isAvailable: Bool { get }
    func requestPermission() async throws
    func readHeight() async throws -> Double?
    func readWeight() async throws -> Double?
}

/// HealthKit wrapper for reading biometric data
@MainActor
class HealthService: HealthServiceProtocol {
    private let healthStore = HKHealthStore()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private let typesToRead: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let height = HKObjectType.quantityType(forIdentifier: .height) {
            types.insert(height)
        }
        if let weight = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(weight)
        }
        return types
    }()

    func requestPermission() async throws {
        guard isAvailable else { return }
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }

    func readHeight() async throws -> Double? {
        guard let heightType = HKQuantityType.quantityType(forIdentifier: .height) else {
            return nil
        }

        let samples = try await querySample(for: heightType)
        guard let sample = samples.first else { return nil }

        // Return height in meters
        return sample.quantity.doubleValue(for: .meter())
    }

    func readWeight() async throws -> Double? {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return nil
        }

        let samples = try await querySample(for: weightType)
        guard let sample = samples.first else { return nil }

        // Return weight in kilograms
        return sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
    }

    private func querySample(for type: HKQuantityType) async throws -> [HKQuantitySample] {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
                }
            }
            healthStore.execute(query)
        }
    }
}

// MARK: - Mock for Previews

@MainActor
class MockHealthService: HealthServiceProtocol {
    var isAvailable: Bool = true

    func requestPermission() async throws {}

    func readHeight() async throws -> Double? {
        return 1.75  // 175 cm
    }

    func readWeight() async throws -> Double? {
        return 70.0  // 70 kg
    }
}
