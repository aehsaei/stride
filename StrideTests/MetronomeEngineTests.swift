import XCTest
import AVFoundation
@testable import Stride

@MainActor
final class MetronomeEngineTests: XCTestCase {
    var metronome: MetronomeEngine!

    override func setUp() async throws {
        try await super.setUp()
        metronome = MetronomeEngine()
        MetronomeEngine.configureAudioSession()
    }

    override func tearDown() async throws {
        metronome.stop()
        metronome = nil
        try await super.tearDown()
    }

    // MARK: - Beat Timing Tests

    func testMetronomeBeatsPerMinute_180BPM_EveryStep() async throws {
        // Given: 180 BPM cadence with every step cue mode
        let targetBPM = 180.0
        let cueMode = CueMode.everyStep
        let expectedInterval = 60.0 / targetBPM  // Should be ~0.333 seconds

        // When: Start metronome
        metronome.start(
            bpm: targetBPM,
            cueMode: cueMode,
            soundSet: .click,
            enableHaptics: false
        )

        // Then: Verify it's playing at correct BPM
        XCTAssertTrue(metronome.isPlaying)
        XCTAssertEqual(metronome.currentBPM, targetBPM, accuracy: 0.01)

        // Wait and verify timing over 3 seconds
        // At 180 BPM, should get 9 beats in 3 seconds
        let startTime = Date()
        try await Task.sleep(nanoseconds: 3_000_000_000)  // 3 seconds
        let elapsed = Date().timeIntervalSince(startTime)

        // Verify elapsed time is approximately 3 seconds
        XCTAssertEqual(elapsed, 3.0, accuracy: 0.1)

        // Verify expected beat interval
        XCTAssertEqual(expectedInterval, 0.333, accuracy: 0.001)
    }

    func testMetronomeBeatsPerMinute_180BPM_EveryOtherStep() async throws {
        // Given: 180 BPM cadence with every other step (half tempo)
        let targetBPM = 180.0
        let cueMode = CueMode.everyOtherStep
        let effectiveBPM = targetBPM / cueMode.divisor  // Should be 90 BPM
        let expectedInterval = 60.0 / effectiveBPM  // Should be ~0.667 seconds

        // When: Start metronome
        metronome.start(
            bpm: targetBPM,
            cueMode: cueMode,
            soundSet: .click,
            enableHaptics: false
        )

        // Then: Verify it's playing at correct effective BPM
        XCTAssertTrue(metronome.isPlaying)
        XCTAssertEqual(metronome.currentBPM, targetBPM, accuracy: 0.01)

        // At 90 effective BPM, should get 4.5 beats in 3 seconds
        let expectedBeats = (effectiveBPM / 60.0) * 3.0
        XCTAssertEqual(expectedBeats, 4.5, accuracy: 0.1)

        // Verify expected beat interval
        XCTAssertEqual(expectedInterval, 0.667, accuracy: 0.001)
    }

    func testMetronomeBeatsPerMinute_160BPM_EveryStep() async throws {
        // Given: 160 BPM cadence (common running cadence)
        let targetBPM = 160.0
        let cueMode = CueMode.everyStep
        let expectedInterval = 60.0 / targetBPM  // Should be 0.375 seconds

        // When: Start metronome
        metronome.start(
            bpm: targetBPM,
            cueMode: cueMode,
            soundSet: .click,
            enableHaptics: false
        )

        // Then: Verify correct timing
        XCTAssertTrue(metronome.isPlaying)
        XCTAssertEqual(metronome.currentBPM, targetBPM, accuracy: 0.01)

        // At 160 BPM, should get ~26.67 beats in 10 seconds
        let duration = 10.0
        let expectedBeats = (targetBPM / 60.0) * duration
        XCTAssertEqual(expectedBeats, 26.67, accuracy: 0.1)

        // Verify expected beat interval
        XCTAssertEqual(expectedInterval, 0.375, accuracy: 0.001)
    }

    func testMetronomeBeatsPerMinute_170BPM_EveryStep() async throws {
        // Given: 170 BPM cadence (optimal running cadence)
        let targetBPM = 170.0
        let cueMode = CueMode.everyStep
        let expectedInterval = 60.0 / targetBPM  // Should be ~0.353 seconds

        // When: Start metronome
        metronome.start(
            bpm: targetBPM,
            cueMode: cueMode,
            soundSet: .click,
            enableHaptics: false
        )

        // Then: Verify correct timing
        XCTAssertTrue(metronome.isPlaying)
        XCTAssertEqual(metronome.currentBPM, targetBPM, accuracy: 0.01)

        // At 170 BPM, should get 28.33 beats in 10 seconds
        let duration = 10.0
        let expectedBeats = (targetBPM / 60.0) * duration
        XCTAssertEqual(expectedBeats, 28.33, accuracy: 0.1)

        // Verify expected beat interval
        XCTAssertEqual(expectedInterval, 0.353, accuracy: 0.001)
    }

    // MARK: - BPM Change Tests

    func testMetronomeBPMChange() async throws {
        // Given: Metronome running at 160 BPM
        metronome.start(
            bpm: 160.0,
            cueMode: .everyStep,
            soundSet: .click,
            enableHaptics: false
        )

        XCTAssertEqual(metronome.currentBPM, 160.0, accuracy: 0.01)

        // When: Change to 180 BPM
        metronome.setBPM(180.0)

        // Wait for debounce
        try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

        // Then: BPM should be updated
        XCTAssertEqual(metronome.currentBPM, 180.0, accuracy: 0.01)
    }

    // MARK: - Cue Mode Tests

    func testCueModeEveryStepDivisor() {
        let mode = CueMode.everyStep
        XCTAssertEqual(mode.divisor, 1.0)
    }

    func testCueModeEveryOtherStepDivisor() {
        let mode = CueMode.everyOtherStep
        XCTAssertEqual(mode.divisor, 2.0)
    }

    func testEffectiveBPMCalculation_EveryStep() {
        // Given: 180 BPM with every step
        let targetBPM = 180.0
        let cueMode = CueMode.everyStep

        // When: Calculate effective BPM
        let effectiveBPM = targetBPM / cueMode.divisor

        // Then: Should be same as target
        XCTAssertEqual(effectiveBPM, 180.0)
    }

    func testEffectiveBPMCalculation_EveryOtherStep() {
        // Given: 180 BPM with every other step
        let targetBPM = 180.0
        let cueMode = CueMode.everyOtherStep

        // When: Calculate effective BPM
        let effectiveBPM = targetBPM / cueMode.divisor

        // Then: Should be half
        XCTAssertEqual(effectiveBPM, 90.0)
    }

    // MARK: - Beat Interval Calculation Tests

    func testBeatIntervalCalculation() {
        let testCases: [(bpm: Double, cueMode: CueMode, expectedInterval: Double)] = [
            (180.0, .everyStep, 0.333),
            (180.0, .everyOtherStep, 0.667),
            (170.0, .everyStep, 0.353),
            (170.0, .everyOtherStep, 0.706),
            (160.0, .everyStep, 0.375),
            (160.0, .everyOtherStep, 0.750),
            (150.0, .everyStep, 0.400),
            (150.0, .everyOtherStep, 0.800),
        ]

        for testCase in testCases {
            let effectiveBPM = testCase.bpm / testCase.cueMode.divisor
            let beatInterval = 60.0 / effectiveBPM

            XCTAssertEqual(
                beatInterval,
                testCase.expectedInterval,
                accuracy: 0.001,
                "BPM: \(testCase.bpm), CueMode: \(testCase.cueMode.rawValue)"
            )
        }
    }

    // MARK: - Beats Per Second Tests

    func testBeatsPerSecond_180BPM_EveryStep() {
        // Given: 180 BPM with every step
        let targetBPM = 180.0
        let cueMode = CueMode.everyStep

        // When: Calculate beats per second
        let effectiveBPM = targetBPM / cueMode.divisor
        let beatsPerSecond = effectiveBPM / 60.0

        // Then: Should be 3 beats per second
        XCTAssertEqual(beatsPerSecond, 3.0, accuracy: 0.01)
    }

    func testBeatsPerSecond_180BPM_EveryOtherStep() {
        // Given: 180 BPM with every other step
        let targetBPM = 180.0
        let cueMode = CueMode.everyOtherStep

        // When: Calculate beats per second
        let effectiveBPM = targetBPM / cueMode.divisor
        let beatsPerSecond = effectiveBPM / 60.0

        // Then: Should be 1.5 beats per second
        XCTAssertEqual(beatsPerSecond, 1.5, accuracy: 0.01)
    }

    func testBeatsPerSecond_170BPM_EveryStep() {
        // Given: 170 BPM with every step (optimal running cadence)
        let targetBPM = 170.0
        let cueMode = CueMode.everyStep

        // When: Calculate beats per second
        let effectiveBPM = targetBPM / cueMode.divisor
        let beatsPerSecond = effectiveBPM / 60.0

        // Then: Should be ~2.83 beats per second
        XCTAssertEqual(beatsPerSecond, 2.833, accuracy: 0.01)
    }

    func testBeatsPerSecond_160BPM_EveryStep() {
        // Given: 160 BPM with every step
        let targetBPM = 160.0
        let cueMode = CueMode.everyStep

        // When: Calculate beats per second
        let effectiveBPM = targetBPM / cueMode.divisor
        let beatsPerSecond = effectiveBPM / 60.0

        // Then: Should be ~2.67 beats per second
        XCTAssertEqual(beatsPerSecond, 2.667, accuracy: 0.01)
    }
}
