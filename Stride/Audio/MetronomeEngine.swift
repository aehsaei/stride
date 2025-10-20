import AVFoundation
import CoreHaptics

/// Metronome cue mode
enum CueMode: String, CaseIterable, Identifiable {
    case everyStep = "Every Step"
    case everyOtherStep = "Every Other Step"

    var id: String { rawValue }

    /// Divisor applied to cadence to get beat frequency
    var divisor: Double {
        switch self {
        case .everyStep:
            return 1.0
        case .everyOtherStep:
            return 2.0
        }
    }
}

/// Sound set for metronome clicks
enum SoundSet: String, CaseIterable, Identifiable {
    case click = "Click"
    case woodblock = "Woodblock"
    case hiHat = "Hi-Hat"

    var id: String { rawValue }

    var fileName: String {
        switch self {
        case .click:
            return "click.wav"
        case .woodblock:
            return "woodblock.wav"
        case .hiHat:
            return "hihat.wav"
        }
    }
}

/// Precise metronome engine using AVAudioEngine for sample-accurate scheduling
@MainActor
class MetronomeEngine: ObservableObject {
    @Published var isPlaying = false
    @Published var currentBPM: Double = 0

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var audioFile: AVAudioFile?
    private var audioBuffer: AVAudioPCMBuffer?

    private var cueMode: CueMode = .everyStep
    private var soundSet: SoundSet = .click
    private var enableHaptics: Bool = false

    private var targetBPM: Double = 0
    private var beatCounter: Int = 0
    private var scheduleTimer: Timer?

    // Haptic engine
    private var hapticEngine: CHHapticEngine?

    // Scheduling parameters
    private let scheduleAheadTime: TimeInterval = 0.5  // Schedule 0.5s ahead
    private let minScheduleInterval: TimeInterval = 0.1  // Check every 100ms

    init() {
        setupAudioEngine()
        setupHaptics()
    }

    deinit {
        stop()
        engine.stop()
    }

    // MARK: - Setup

    private func setupAudioEngine() {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: nil)
        engine.prepare()
    }

    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine creation failed: \(error)")
        }
    }

    // MARK: - Public API

    func start(bpm: Double, cueMode: CueMode, soundSet: SoundSet, enableHaptics: Bool) {
        self.targetBPM = bpm
        self.cueMode = cueMode
        self.soundSet = soundSet
        self.enableHaptics = enableHaptics
        self.currentBPM = bpm

        loadSound(soundSet: soundSet)

        do {
            if !engine.isRunning {
                try engine.start()
            }

            playerNode.play()
            isPlaying = true
            beatCounter = 0

            // Start scheduling loop
            scheduleBeats()
            scheduleTimer = Timer.scheduledTimer(withTimeInterval: minScheduleInterval, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.scheduleBeats()
                }
            }
        } catch {
            print("Failed to start metronome: \(error)")
        }
    }

    func stop() {
        isPlaying = false
        scheduleTimer?.invalidate()
        scheduleTimer = nil
        playerNode.stop()
        beatCounter = 0
    }

    func setBPM(_ bpm: Double) {
        // Apply phase-aligned BPM change
        // For PoC, we simply update target and let next schedule pick it up
        // A more sophisticated approach would calculate phase offset
        targetBPM = bpm
        currentBPM = bpm
    }

    func setCueMode(_ mode: CueMode) {
        cueMode = mode
        // Recalculate scheduling on next iteration
    }

    func setSoundSet(_ sound: SoundSet) {
        soundSet = sound
        loadSound(soundSet: sound)
    }

    func setEnableHaptics(_ enabled: Bool) {
        enableHaptics = enabled
    }

    // MARK: - Audio Loading

    private func loadSound(soundSet: SoundSet) {
        // For PoC, we'll generate a simple click sound programmatically
        // In production, load from bundle: Bundle.main.url(forResource: soundSet.fileName, withExtension: nil)
        audioBuffer = generateClickBuffer()
    }

    private func generateClickBuffer() -> AVAudioPCMBuffer? {
        let sampleRate = 44100.0
        let duration = 0.01  // 10ms click
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }

        buffer.frameLength = frameCount

        // Generate short impulse with decay (simple click sound)
        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            return nil
        }

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = exp(-t * 400.0)  // Exponential decay
            let sample = Float(sin(2.0 * .pi * 1000.0 * t) * envelope)
            leftChannel[i] = sample * 0.5
            rightChannel[i] = sample * 0.5
        }

        return buffer
    }

    // MARK: - Beat Scheduling

    private func scheduleBeats() {
        guard isPlaying, let buffer = audioBuffer else { return }

        let bpm = targetBPM / cueMode.divisor
        guard bpm > 0 else { return }

        let beatInterval = 60.0 / bpm

        // Calculate how many beats to schedule based on current player time
        let currentTime = playerNode.lastRenderTime?.sampleTime ?? 0
        let sampleRate = engine.mainMixerNode.outputFormat(forBus: 0).sampleRate

        var scheduleTime = AVAudioTime(sampleTime: currentTime, atRate: sampleRate)

        // Schedule multiple beats ahead
        let beatsToSchedule = Int(scheduleAheadTime / beatInterval) + 1

        for i in 0..<beatsToSchedule {
            let offset = beatInterval * Double(i)
            let time = AVAudioTime(
                sampleTime: currentTime + AVAudioFramePosition(offset * sampleRate),
                atRate: sampleRate
            )

            playerNode.scheduleBuffer(buffer, at: time, options: [], completionHandler: nil)

            // Trigger haptics if enabled (approximation, not sample-accurate)
            if enableHaptics && i == 0 {
                triggerHaptic()
            }
        }
    }

    // MARK: - Haptics

    private func triggerHaptic() {
        guard enableHaptics, let engine = hapticEngine else { return }

        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Haptic playback failed: \(error)")
        }
    }

    // MARK: - Audio Session Configuration

    static func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
}
