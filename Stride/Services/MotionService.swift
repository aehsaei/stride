import Foundation
import CoreMotion
import Combine

/// Protocol for motion/pedometer services (enables mocking)
protocol MotionServiceProtocol {
    var currentCadence: Double? { get }
    var isAvailable: Bool { get }
    func requestPermission()
    func startTracking()
    func stopTracking()
}

/// CoreMotion wrapper for pedometer-based cadence tracking
@MainActor
class MotionService: ObservableObject, MotionServiceProtocol {
    @Published var currentCadence: Double? = nil
    @Published var isAvailable: Bool = false

    private let pedometer = CMPedometer()

    init() {
        isAvailable = CMPedometer.isCadenceAvailable()
    }

    func requestPermission() {
        // Permissions are requested automatically when startUpdates is called
    }

    func startTracking() {
        guard isAvailable else { return }

        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            guard let self = self, let data = data, error == nil else { return }

            Task { @MainActor in
                // CMPedometer provides cadence in steps per second; convert to steps per minute
                if let cadence = data.currentCadence?.doubleValue {
                    self.currentCadence = cadence * 60.0
                }
            }
        }
    }

    func stopTracking() {
        pedometer.stopUpdates()
        currentCadence = nil
    }
}

// MARK: - Mock for Previews

@MainActor
class MockMotionService: MotionServiceProtocol {
    var currentCadence: Double? = 175.0
    var isAvailable: Bool = true

    func requestPermission() {}
    func startTracking() {}
    func stopTracking() {}
}
