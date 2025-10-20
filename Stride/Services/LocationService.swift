import Foundation
import CoreLocation
import Combine

/// Protocol for location services (enables mocking)
protocol LocationServiceProtocol {
    var currentSpeedMps: Double { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    func requestPermission()
    func startUpdatingLocation()
    func stopUpdatingLocation()
}

/// CoreLocation wrapper for GPS-based pace tracking
@MainActor
class LocationService: NSObject, ObservableObject, LocationServiceProtocol {
    @Published var currentSpeedMps: Double = 0
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()
    private var speedSamples: [Double] = []
    private let smoothingWindowSize = 5  // Average last 5 samples

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5  // Update every 5 meters
        authorizationStatus = locationManager.authorizationStatus
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        speedSamples.removeAll()
        currentSpeedMps = 0
    }

    private func updateSmoothedSpeed(_ newSpeed: Double) {
        speedSamples.append(newSpeed)
        if speedSamples.count > smoothingWindowSize {
            speedSamples.removeFirst()
        }

        // Average the samples for smoother readings
        currentSpeedMps = speedSamples.reduce(0, +) / Double(speedSamples.count)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.speed >= 0 else { return }

        Task { @MainActor in
            // CoreLocation speed is in m/s
            updateSmoothedSpeed(location.speed)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}

// MARK: - Mock for Previews

@MainActor
class MockLocationService: LocationServiceProtocol {
    var currentSpeedMps: Double = 2.5
    var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse

    func requestPermission() {}
    func startUpdatingLocation() {}
    func stopUpdatingLocation() {}
}
