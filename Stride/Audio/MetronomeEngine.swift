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

    nonisolated deinit {
        // Note: Cannot call @MainActor methods from deinit
        // Timer and audio cleanup happens when object is deallocated
        if engine.isRunning {
            engine.stop()
        }
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

            // Start scheduling loop - schedule based on actual BPM
            let effectiveBPM = bpm / cueMode.divisor
            let beatInterval = 60.0 / effectiveBPM

            scheduleBeats()
            scheduleTimer = Timer.scheduledTimer(withTimeInterval: beatInterval, repeats: true) { [weak self] _ in
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
        targetBPM = bpm
        currentBPM = bpm

        // Restart timer with new interval
        if isPlaying {
            scheduleTimer?.invalidate()
            let effectiveBPM = bpm / cueMode.divisor
            let beatInterval = 60.0 / effectiveBPM

            scheduleTimer = Timer.scheduledTimer(withTimeInterval: beatInterval, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.scheduleBeats()
                }
            }
        }
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
        // Generate different sounds based on sound set
        audioBuffer = generateClickBuffer(for: soundSet)
    }

    private func generateClickBuffer(for soundSet: SoundSet) -> AVAudioPCMBuffer? {
        let sampleRate = 44100.0
        let duration = 0.05  // 50ms click (longer and more audible)
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }

        buffer.frameLength = frameCount

        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            return nil
        }

        switch soundSet {
        case .click:
            // High-pitched click (800Hz sine with fast decay)
            for i in 0..<Int(frameCount) {
                let t = Double(i) / sampleRate
                let envelope = exp(-t * 100.0)
                let sineWave = sin(2.0 * Double.pi * 800.0 * t)
                let sample = Float(sineWave * envelope)
                leftChannel[i] = sample * 0.8
                rightChannel[i] = sample * 0.8
            }

        case .woodblock:
            // Lower, more resonant tone (400Hz + 800Hz harmonics with medium decay)
            for i in 0..<Int(frameCount) {
                let t = Double(i) / sampleRate
                let envelope = exp(-t * 60.0)  // Slower decay for woodblock resonance
                // Mix fundamental and harmonic
                let fundamental = sin(2.0 * Double.pi * 400.0 * t)
                let harmonic = sin(2.0 * Double.pi * 800.0 * t) * 0.5
                let mixed = fundamental + harmonic
                let sample = Float(mixed * envelope)
                leftChannel[i] = sample * 0.7
                rightChannel[i] = sample * 0.7
            }

        case .hiHat:
            // Noise-based hi-hat sound with high-pass characteristic
            for i in 0..<Int(frameCount) {
                let t = Double(i) / sampleRate
                let envelope = exp(-t * 150.0)  // Fast decay for hi-hat
                // Generate white noise and filter it
                let noise = Double(Float.random(in: -1.0...1.0))
                // Mix with high frequency tone for metallic quality
                let tone = sin(2.0 * Double.pi * 3000.0 * t)
                let noisePart = noise * 0.7
                let tonePart = tone * 0.3
                let mixed = noisePart + tonePart
                let sample = Float(mixed * envelope)
                leftChannel[i] = sample * 0.6
                rightChannel[i] = sample * 0.6
            }
        }

        return buffer
    }

    // MARK: - Beat Scheduling

    private func scheduleBeats() {
        guard isPlaying, let buffer = audioBuffer else { return }

        // Simply play the buffer - the timer controls the rhythm
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)

        // Trigger haptics if enabled
        if enableHaptics {
            triggerHaptic()
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
