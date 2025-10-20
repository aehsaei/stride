# Stride Testing Guide

This document describes the test suite for the Stride running cadence app.

## Test Structure

The test suite is organized into two main test files:

### 1. MetronomeEngineTests.swift

Tests the metronome audio engine to ensure beats are played at the correct frequency.

#### Key Test Categories:

**Beat Timing Tests**
- `testMetronomeBeatsPerMinute_180BPM_EveryStep` - Verifies 180 BPM = 3 beats/second
- `testMetronomeBeatsPerMinute_180BPM_EveryOtherStep` - Verifies 180 BPM with half tempo = 1.5 beats/second
- `testMetronomeBeatsPerMinute_160BPM_EveryStep` - Tests common running cadence (160 spm)
- `testMetronomeBeatsPerMinute_170BPM_EveryStep` - Tests optimal running cadence (170 spm)

**Beat Interval Calculation Tests**
- `testBeatIntervalCalculation` - Tests multiple BPM/cue mode combinations:
  - 180 BPM, every step → 0.333 second intervals
  - 180 BPM, every other step → 0.667 second intervals
  - 170 BPM, every step → 0.353 second intervals
  - 160 BPM, every step → 0.375 second intervals
  - And more...

**Beats Per Second Tests**
- `testBeatsPerSecond_180BPM_EveryStep` - Verifies 180 BPM = 3.0 beats/second
- `testBeatsPerSecond_180BPM_EveryOtherStep` - Verifies 90 effective BPM = 1.5 beats/second
- `testBeatsPerSecond_170BPM_EveryStep` - Verifies 170 BPM = 2.83 beats/second
- `testBeatsPerSecond_160BPM_EveryStep` - Verifies 160 BPM = 2.67 beats/second

**Cue Mode Tests**
- `testCueModeEveryStepDivisor` - Verifies divisor = 1.0
- `testCueModeEveryOtherStepDivisor` - Verifies divisor = 2.0
- `testEffectiveBPMCalculation_EveryStep` - Tests BPM calculation
- `testEffectiveBPMCalculation_EveryOtherStep` - Tests half-tempo BPM

**BPM Change Tests**
- `testMetronomeBPMChange` - Verifies metronome responds to BPM changes during playback

### 2. CadenceModelTests.swift

Tests the cadence calculation algorithm that determines optimal steps per minute based on speed and biometrics.

#### Key Test Categories:

**Cadence Calculation Tests**
- `testSuggestedCadence_WalkingSpeed` - Tests 1.5 m/s (~3.4 mph) → ~158 spm
- `testSuggestedCadence_JoggingSpeed` - Tests 3.0 m/s (~6.7 mph) → ~170 spm
- `testSuggestedCadence_RunningSpeed` - Tests 4.5 m/s (~10 mph) → ~182 spm
- `testSuggestedCadence_WithPersonalizationDelta` - Tests +5 adjustment
- `testSuggestedCadence_WithNegativePersonalizationDelta` - Tests -5 adjustment

**Cadence Range Tests**
- `testSuggestedCadence_MinimumClamp` - Verifies minimum 150 spm
- `testSuggestedCadence_MaximumClamp` - Verifies maximum 190 spm

**Real World Pace Tests**
- Tests common running paces:
  - 12:00 min/mile (easy pace) → ~164 spm
  - 10:00 min/mile (moderate) → ~168 spm
  - 8:00 min/mile (fast) → ~173 spm
  - 7:00 min/mile (very fast) → ~177 spm
  - Various min/km paces

**Stride Length Validation Tests**
- `testStrideLength_WithinReasonableBounds` - Verifies stride length 0.5-2.0 meters
- `testStrideLength_TallerRunner` - Tests 1.90m height (~6'3")
- `testStrideLength_ShorterRunner` - Tests 1.60m height (~5'3")

**Edge Cases**
- `testSuggestedCadence_ZeroSpeed` - Handles zero speed gracefully
- `testSuggestedCadence_NegativeSpeed` - Handles invalid negative speed

## Running the Tests

### In Xcode

1. Open `Stride.xcodeproj` in Xcode
2. Select the test scheme from the scheme selector
3. Press `Cmd+U` to run all tests
4. Or click the diamond icon next to individual test methods to run specific tests

### Using xcodebuild (Command Line)

```bash
# Run all tests
xcodebuild test -project Stride.xcodeproj -scheme StrideTests -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test class
xcodebuild test -project Stride.xcodeproj -scheme StrideTests -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:StrideTests/MetronomeEngineTests

# Run specific test method
xcodebuild test -project Stride.xcodeproj -scheme StrideTests -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:StrideTests/MetronomeEngineTests/testBeatsPerSecond_180BPM_EveryStep
```

## Test Assertions

### Metronome Timing Assertions

The metronome tests verify:

1. **Beat Interval Accuracy**: Ensures intervals between beats match the formula `60.0 / effectiveBPM`
2. **Beats Per Second**: Verifies `effectiveBPM / 60.0` calculation is correct
3. **Effective BPM**: Confirms cue mode divisor is applied correctly
4. **State Management**: Checks `isPlaying` and `currentBPM` properties

Example calculation for 180 BPM, every step:
- Effective BPM = 180 / 1.0 = 180
- Beat interval = 60.0 / 180 = 0.333 seconds
- Beats per second = 180 / 60.0 = 3.0

Example calculation for 180 BPM, every other step:
- Effective BPM = 180 / 2.0 = 90
- Beat interval = 60.0 / 90 = 0.667 seconds
- Beats per second = 90 / 60.0 = 1.5

### Cadence Model Assertions

The cadence model tests verify:

1. **Algorithm Correctness**: Base cadence (170 spm) ± 8 spm per m/s deviation from 3.0 m/s baseline
2. **Range Clamping**: Cadence stays within 150-190 spm
3. **Personalization**: Delta adjustment applied correctly
4. **Stride Length**: Resulting stride length is biomechanically reasonable (0.5-2.0m)

Example calculation for 4.5 m/s speed:
- Speed delta from baseline = 4.5 - 3.0 = 1.5 m/s
- Cadence adjustment = 8 * 1.5 = 12 spm
- Suggested cadence = 170 + 12 = 182 spm

## Test Coverage

### What's Tested
✅ Beat timing calculations
✅ Beats per second accuracy
✅ Cue mode divisor logic
✅ BPM change responsiveness
✅ Cadence calculation algorithm
✅ Range clamping (150-190 spm)
✅ Personalization offsets
✅ Real-world pace conversions
✅ Stride length validation
✅ Edge cases (zero/negative speeds)

### What's Not Tested (Manual Testing Required)
❌ Actual audio output from speakers/headphones
❌ Haptic feedback timing
❌ GPS location tracking
❌ CoreMotion pedometer integration
❌ HealthKit biometric reading
❌ Background audio continuation
❌ Screen lock behavior

## Important Notes

### Audio Testing Limitations

The unit tests verify that:
- Beat intervals are calculated correctly
- The timer fires at the correct frequency
- BPM changes update the timer interval

However, they **cannot verify**:
- Whether audio actually plays from the speakers
- Audio volume levels
- Audio quality or click characteristics
- Sample-accurate timing of AVAudioPlayerNode

To test actual audio playback:
1. Run the app on a physical device or simulator
2. Start a run with a known BPM (e.g., 180 = 3 beats/second)
3. Use a stopwatch or metronome app to verify the beat frequency
4. Try different cue modes and BPM values

### Expected Test Results

All tests should pass with these tolerances:
- Time-based tests: ±0.1 second accuracy
- BPM tests: ±0.01 BPM accuracy
- Beat interval tests: ±0.001 second accuracy
- Cadence tests: ±2-5 spm accuracy (algorithm approximation)

## Debugging Failed Tests

If tests fail:

1. **Check test tolerance values** - Timing tests may need wider accuracy margins on slower systems
2. **Verify formula correctness** - Ensure beat interval = 60.0 / effectiveBPM
3. **Check async timing** - Tests use `Task.sleep` which may be affected by system load
4. **Verify MainActor isolation** - MetronomeEngine must run on MainActor

## Contributing New Tests

When adding new tests:

1. Follow the existing test naming convention: `test<Component><Scenario>`
2. Include clear Given/When/Then comments
3. Use appropriate XCTAssert accuracy tolerances
4. Test edge cases and boundary conditions
5. Add documentation to this README
