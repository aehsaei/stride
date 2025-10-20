import Foundation
import SwiftUI
import Combine

/// ViewModel for the run screen
@MainActor
class RunViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isRunning = false
    @Published var currentBPM: Double = 0
    @Published var targetCadence: Double = 0
    @Published var actualCadence: Double? = nil

    @Published var targetSpeedValue: Double
    @Published var speedUnit: SpeedUnit

    @Published var paceSource: PaceSource = .manual
    @Published var currentSpeedMps: Double = 0

    @Published var cueMode: CueMode
    @Published var soundSet: SoundSet
    @Published var enableHaptics: Bool

    // MARK: - Dependencies

    private let metronome: MetronomeEngine
    private let locationService: any LocationServiceProtocol
    private let motionService: any MotionServiceProtocol
    private let cadenceModel = CadenceModel()

    private let biometric: Biometric
    private let personalizationDelta: Double

    private var cancellables = Set<AnyCancellable>()
    private var debounceTimer: Timer?

    // MARK: - Computed Properties

    var targetSpeedMps: Double {
        speedUnit.toMetersPerSecond(targetSpeedValue)
    }

    var displayPace: String {
        let paceUnit: PaceUnit = speedUnit == .mph ? .minPerMi : .minPerKm
        let pace = paceUnit.fromMetersPerSecond(currentSpeedMps)
        return paceUnit.formatPace(pace)
    }

    var cadenceComparison: String {
        guard let actual = actualCadence else { return "—" }
        let delta = actual - targetCadence
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(Int(delta)) spm"
    }

    // MARK: - Initialization

    init(
        biometric: Biometric,
        targetSpeedValue: Double,
        speedUnit: SpeedUnit,
        cueMode: CueMode,
        soundSet: SoundSet,
        enableHaptics: Bool,
        personalizationDelta: Double,
        metronome: MetronomeEngine = MetronomeEngine(),
        locationService: any LocationServiceProtocol = LocationService(),
        motionService: any MotionServiceProtocol = MotionService()
    ) {
        self.biometric = biometric
        self.targetSpeedValue = targetSpeedValue
        self.speedUnit = speedUnit
        self.cueMode = cueMode
        self.soundSet = soundSet
        self.enableHaptics = enableHaptics
        self.personalizationDelta = personalizationDelta
        self.metronome = metronome
        self.locationService = locationService
        self.motionService = motionService

        // Calculate initial cadence
        updateTargetCadence()
        currentSpeedMps = targetSpeedMps

        // Subscribe to location updates if using GPS
        if let locationService = locationService as? LocationService {
            locationService.$currentSpeedMps
                .sink { [weak self] speed in
                    self?.onLocationSpeedUpdated(speed)
                }
                .store(in: &cancellables)
        }

        // Subscribe to motion updates for actual cadence
        if let motionService = motionService as? MotionService {
            motionService.$currentCadence
                .sink { [weak self] cadence in
                    self?.actualCadence = cadence
                }
                .store(in: &cancellables)
        }
    }

    // MARK: - Run Control

    func startRun() {
        isRunning = true

        // Start services
        if paceSource == .gps {
            locationService.requestPermission()
            locationService.startUpdatingLocation()
        }

        if motionService.isAvailable {
            motionService.requestPermission()
            motionService.startTracking()
        }

        // Start metronome
        updateTargetCadence()
        metronome.start(
            bpm: targetCadence,
            cueMode: cueMode,
            soundSet: soundSet,
            enableHaptics: enableHaptics
        )
        currentBPM = targetCadence
    }

    func pauseRun() {
        isRunning = false
        metronome.stop()
    }

    func resumeRun() {
        isRunning = true
        metronome.start(
            bpm: targetCadence,
            cueMode: cueMode,
            soundSet: soundSet,
            enableHaptics: enableHaptics
        )
    }

    func endRun() {
        isRunning = false
        metronome.stop()
        locationService.stopUpdatingLocation()
        motionService.stopTracking()
    }

    // MARK: - Speed Adjustments

    func increaseSpeed() {
        targetSpeedValue += 0.5
        onSpeedChanged()
    }

    func decreaseSpeed() {
        targetSpeedValue = max(1.0, targetSpeedValue - 0.5)
        onSpeedChanged()
    }

    func onSpeedChanged() {
        updateTargetCadence()

        if isRunning {
            // Apply debouncing to avoid rapid BPM changes
            debounceTimer?.invalidate()
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.metronome.setBPM(self.targetCadence)
                    self.currentBPM = self.targetCadence
                }
            }
        }
    }

    func togglePaceSource() {
        paceSource = paceSource == .manual ? .gps : .manual

        if paceSource == .gps && isRunning {
            locationService.startUpdatingLocation()
        } else if paceSource == .manual {
            locationService.stopUpdatingLocation()
            currentSpeedMps = targetSpeedMps
        }
    }

    // MARK: - Settings Changes

    func onCueModeChanged(_ mode: CueMode) {
        cueMode = mode
        if isRunning {
            metronome.setCueMode(mode)
        }
    }

    func onSoundSetChanged(_ sound: SoundSet) {
        soundSet = sound
        if isRunning {
            metronome.setSoundSet(sound)
        }
    }

    func onHapticsChanged(_ enabled: Bool) {
        enableHaptics = enabled
        if isRunning {
            metronome.setEnableHaptics(enabled)
        }
    }

    // MARK: - Private Helpers

    private func updateTargetCadence() {
        let speed = paceSource == .gps ? currentSpeedMps : targetSpeedMps
        targetCadence = cadenceModel.suggestedCadence(
            biometric: biometric,
            speedMps: speed,
            personalizationDelta: personalizationDelta
        )
    }

    private func onLocationSpeedUpdated(_ speed: Double) {
        guard paceSource == .gps, speed > 0 else { return }

        currentSpeedMps = speed

        // Debounce cadence updates to avoid jitter (2-5s)
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.updateTargetCadence()
                if self.isRunning {
                    self.metronome.setBPM(self.targetCadence)
                    self.currentBPM = self.targetCadence
                }
            }
        }
    }
}
