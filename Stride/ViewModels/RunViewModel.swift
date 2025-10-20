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

    @Published var targetPaceMinutes: Double
    @Published var targetPaceSeconds: Double
    @Published var paceUnit: PaceUnit

    @Published var currentSpeedMps: Double = 0

    @Published var cueMode: CueMode
    @Published var soundSet: SoundSet
    @Published var enableHaptics: Bool

    // MARK: - Dependencies

    private let metronome: MetronomeEngine
    private let motionService: any MotionServiceProtocol
    private let cadenceModel = CadenceModel()

    private let biometric: Biometric
    private let personalizationDelta: Double

    private var cancellables = Set<AnyCancellable>()
    private var debounceTimer: Timer?

    // MARK: - Computed Properties

    var targetPaceInMinutes: Double {
        targetPaceMinutes + (targetPaceSeconds / 60.0)
    }

    var targetSpeedMps: Double {
        // Convert pace (min/distance) to speed (m/s)
        let totalMinutes = targetPaceInMinutes
        guard totalMinutes > 0 else { return 3.0 }

        switch paceUnit {
        case .minPerKm:
            return 1000.0 / (totalMinutes * 60.0)
        case .minPerMi:
            return 1609.344 / (totalMinutes * 60.0)
        }
    }

    var currentPace: Double {
        return paceUnit.fromMetersPerSecond(currentSpeedMps)
    }

    var displayPace: String {
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
        targetPaceMinutes: Double,
        targetPaceSeconds: Double,
        paceUnit: PaceUnit,
        cueMode: CueMode,
        soundSet: SoundSet,
        enableHaptics: Bool,
        personalizationDelta: Double,
        metronome: MetronomeEngine? = nil,
        motionService: (any MotionServiceProtocol)? = nil
    ) {
        self.biometric = biometric
        self.targetPaceMinutes = targetPaceMinutes
        self.targetPaceSeconds = targetPaceSeconds
        self.paceUnit = paceUnit
        self.cueMode = cueMode
        self.soundSet = soundSet
        self.enableHaptics = enableHaptics
        self.personalizationDelta = personalizationDelta
        self.metronome = metronome ?? MetronomeEngine()
        self.motionService = motionService ?? MotionService()

        // Calculate initial cadence
        updateTargetCadence()
        currentSpeedMps = targetSpeedMps

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

        // Start motion service
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
        motionService.stopTracking()
    }

    // MARK: - Pace Adjustments

    func increasePace() {
        // Increase pace means slower = more time per distance
        targetPaceSeconds += 15
        if targetPaceSeconds >= 60 {
            targetPaceMinutes += 1
            targetPaceSeconds = 0
        }
        onPaceChanged()
    }

    func decreasePace() {
        // Decrease pace means faster = less time per distance
        if targetPaceSeconds >= 15 {
            targetPaceSeconds -= 15
        } else if targetPaceMinutes > 5 {
            targetPaceMinutes -= 1
            targetPaceSeconds = 45
        } else {
            targetPaceSeconds = max(0, targetPaceSeconds - 15)
        }
        onPaceChanged()
    }

    func onPaceChanged() {
        currentSpeedMps = targetSpeedMps
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
        targetCadence = cadenceModel.suggestedCadence(
            biometric: biometric,
            speedMps: targetSpeedMps,
            personalizationDelta: personalizationDelta
        )
    }
}
