# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Stride** is a Swift/SwiftUI iOS proof-of-concept app that helps runners maintain optimal cadence. It:
- Calculates personalized running cadence (steps per minute) based on biometrics and target speed
- Plays a precise, adjustable metronome beat that continues in background (even with screen locked)
- Adapts in real-time as the runner adjusts pace or follows GPS speed
- Provides haptic feedback and tracks actual cadence via CoreMotion

This is a single-target iOS app with no backend, focusing on clean architecture and modular code.

## Development Commands

### Opening the Project
```bash
# Open in Xcode (create new iOS App project first if needed)
open Stride/App/StrideApp.swift
```

Since this is a SwiftUI app without a traditional Xcode project file (`.xcodeproj`), you'll need to:
1. Create a new iOS App project in Xcode
2. Replace the default SwiftUI files with the Stride directory structure
3. Add all Swift files to the project target

### Building
```bash
# Build in Xcode: Cmd+B
# Or via command line (if you have xcodebuild configured):
xcodebuild -scheme Stride -destination 'platform=iOS Simulator,name=iPhone 15' build
```

### Running the Application
```bash
# Run in Xcode: Cmd+R
# Select a target device (physical device strongly recommended for GPS/Motion/Haptics)
```

**Important**: Many features require a physical device:
- GPS location tracking (CoreLocation)
- Motion/pedometer data (CoreMotion)
- Haptic feedback (CoreHaptics)
- Background audio (works in simulator but better tested on device)

### Testing
```bash
# Currently no test target exists
# To add tests: File > New > Target > iOS Unit Testing Bundle

# Unit tests should cover:
# - Unit conversions (Units.swift)
# - Cadence calculations (CadenceModel.swift)
# - Edge cases: very slow/fast speeds, different heights
```

### Code Quality
No linter configured. Consider adding SwiftLint:
```bash
# Install SwiftLint
brew install swiftlint

# Run manually
swiftlint
```

## Architecture

### Core Components

**MVVM Pattern**:
- **Models**: Pure data and business logic (no UI dependencies)
- **ViewModels**: Observable objects that connect models to views
- **Views**: SwiftUI views that observe ViewModels
- **Services**: Protocol-based wrappers for system frameworks (Location, Motion, Health)

**Audio Engine**:
- `MetronomeEngine` uses AVAudioEngine + AVAudioPlayerNode for sample-accurate beat scheduling
- Schedules beats 500ms ahead in a continuous loop
- Handles dynamic BPM changes with phase alignment to avoid audio gaps

**Cadence Calculation**:
- `CadenceModel` implements a biomechanical heuristic:
  - Base cadence: 170 spm at easy pace (~3 m/s)
  - Adjusts by 8 spm per 1 m/s speed change
  - Validates stride length against estimated leg length (0.53 × height)
  - Clamps to 155-195 spm range
  - Supports personalization offset (±10 spm)

### Key Directories

```
Stride/
├── Models/              # Data models and business logic
│   ├── Biometric.swift       # Height, weight, leg length
│   ├── CadenceModel.swift    # Cadence calculation algorithm
│   └── Units.swift           # Speed/height/weight conversions
│
├── Audio/               # Metronome audio engine
│   ├── MetronomeEngine.swift # AVAudioEngine wrapper
│   └── ClickAssets/          # WAV files (optional, currently generated programmatically)
│
├── Services/            # System framework wrappers (protocol-based for mocking)
│   ├── PaceSource.swift      # Enum: manual vs GPS
│   ├── LocationService.swift # CoreLocation for GPS speed
│   ├── MotionService.swift   # CoreMotion for actual cadence
│   └── HealthService.swift   # HealthKit for height/weight
│
├── ViewModels/          # MVVM ViewModels
│   ├── SetupViewModel.swift  # Setup screen logic
│   └── RunViewModel.swift    # Run screen logic, metronome control
│
├── Views/               # SwiftUI views
│   ├── SetupView.swift       # Biometrics, speed, settings input
│   └── RunView.swift         # Live run with metronome controls
│
└── App/                 # App entry point
    └── StrideApp.swift
```

### Data Flow

**Setup Flow**:
1. User enters height/weight (or loads from HealthKit) → `SetupViewModel`
2. User sets target speed → `SetupViewModel.updateSuggestedCadence()`
3. `CadenceModel.suggestedCadence()` calculates optimal cadence
4. Display updates reactively via `@Published` properties
5. User taps "Start Run" → push `RunView` with initialized `RunViewModel`

**Run Flow**:
1. `RunViewModel.startRun()` initiates:
   - `MetronomeEngine.start()` with calculated cadence
   - `LocationService.startUpdatingLocation()` if GPS mode enabled
   - `MotionService.startTracking()` for actual cadence
2. User adjusts speed slider → debounced (300ms) → `MetronomeEngine.setBPM()`
3. GPS updates → smoothed (5-sample average) → debounced (3s) → cadence recalculation
4. Actual cadence from pedometer → displayed alongside target cadence
5. User taps "End Run" → stop all services, dismiss view

**Audio Scheduling**:
- Timer fires every 100ms (`minScheduleInterval`)
- Checks if more beats need scheduling (within 500ms `scheduleAheadTime`)
- Schedules AVAudioPCMBuffer at precise sample times
- BPM changes apply to next scheduled beats (phase-aligned)

### Important Patterns

**Dependency Injection**:
- Services use protocols (`LocationServiceProtocol`, etc.)
- ViewModels accept service instances in `init()`
- Mock services provided for SwiftUI previews (`MockLocationService`, etc.)
- Enables testing without real GPS/Motion/Health hardware

**Actor Isolation**:
- `@MainActor` on ViewModels and services that publish to UI
- Ensures thread-safe updates to `@Published` properties

**Combine Integration**:
- Services publish updates via `@Published` properties
- ViewModels use `.sink()` to react to location/motion changes
- Debouncing prevents jittery GPS data from causing rapid BPM changes

**Configuration Over Hardcoding**:
- `CadenceModelConfig` struct centralizes all algorithm constants
- Easy to tweak: base cadence, slope, min/max, leg length factor
- Well-documented with comments explaining each constant

**Fallback Strategy**:
- Audio: generates click programmatically if WAV files missing
- HealthKit: manual input if permission denied
- GPS: manual speed slider if location unavailable
- Motion: show target-only if pedometer unavailable

## Dependencies and Integrations

### System Frameworks (No External Packages)
- **SwiftUI**: UI layer
- **AVFoundation**: Audio playback (AVAudioEngine, AVAudioPlayerNode)
- **CoreLocation**: GPS speed tracking
- **CoreMotion**: Pedometer for actual cadence (CMPedometer)
- **HealthKit**: Optional read of height/weight (HKHealthStore)
- **CoreHaptics**: Haptic feedback synchronized to beats (CHHapticEngine)

### Required Permissions (Info.plist)
- `NSLocationWhenInUseUsageDescription`: GPS pace tracking
- `NSMotionUsageDescription`: Pedometer cadence measurement
- `NSHealthShareUsageDescription`: Read height/weight (optional)

### Required Capabilities
- **Background Modes > Audio**: Metronome continues with screen locked

## Configuration

### Tweaking Cadence Algorithm

Edit `Stride/Models/CadenceModel.swift`:

```swift
struct CadenceModelConfig {
    let baseCadence: Double = 170        // Cadence at 3 m/s (easy jog)
    let cadenceSlope: Double = 8         // spm increase per 1 m/s speed increase
    let minCadence: Double = 155         // Lower clamp
    let maxCadence: Double = 195         // Upper clamp
    let legLengthFactor: Double = 0.53   // Leg length = 0.53 × height
    let strideLenLowerFactor: Double = 0.7  // Min stride = 0.7 × leg length
    let strideLenUpperFactor: Double = 1.3  // Max stride = 1.3 × leg length
    let strideNudge: Double = 2.0        // Cadence adjustment if stride out of bounds
}
```

### Metronome Timing Parameters

Edit `Stride/Audio/MetronomeEngine.swift`:

```swift
private let scheduleAheadTime: TimeInterval = 0.5  // Schedule beats 500ms ahead
private let minScheduleInterval: TimeInterval = 0.1  // Check for scheduling every 100ms
```

Increase `scheduleAheadTime` if experiencing audio dropouts on slower devices.

### Audio Session Configuration

Background audio is configured in `MetronomeEngine.configureAudioSession()`:

```swift
try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
```

- `.mixWithOthers`: Allows music/podcasts to play concurrently
- `.playback`: Enables background audio

### Custom Sound Files

To replace programmatic click generation:
1. Add WAV files to `Stride/Audio/ClickAssets/`
2. Update `MetronomeEngine.loadSound()` per instructions in `ClickAssets/README.md`

### GPS Smoothing

Edit `Stride/Services/LocationService.swift`:

```swift
private let smoothingWindowSize = 5  // Average last 5 GPS samples
```

Increase for smoother but less responsive GPS pace; decrease for faster response but more jitter.

### Pace Update Debouncing

Edit `Stride/ViewModels/RunViewModel.swift`:

```swift
debounceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, ...)  // 3s debounce for GPS
```

Adjust GPS debounce (default 3s) vs manual speed debounce (default 300ms).

## Common Development Tasks

### Adding a New Unit Type
1. Add enum to `Models/Units.swift` (e.g., `DistanceUnit`)
2. Implement `toBaseUnit()` and `fromBaseUnit()` methods
3. Add picker to relevant view
4. Add `@Published` property to ViewModel
5. Add unit conversion helper method

### Changing Metronome Behavior
- **BPM range**: Edit `CadenceModelConfig` min/max values
- **Sound accent**: Modify `MetronomeEngine.scheduleBeats()` to accent every 4th beat
- **Timing precision**: Adjust `scheduleAheadTime` / `minScheduleInterval`

### Adding HealthKit Write Support
1. Add `HKObjectType` write types to `HealthService.typesToWrite`
2. Request write authorization in `requestPermission()`
3. Create `HKWorkout` objects for completed runs
4. Call `healthStore.save()` with workout data

### Debugging Audio Issues
- Check `AVAudioSession.sharedInstance().category` in debugger
- Verify `engine.isRunning` is `true`
- Print `playerNode.lastRenderTime?.sampleTime` to confirm scheduling
- Use Audio Queue Inspector in Xcode (Debug > Audio > Audio Queue)

### Testing on Simulator vs Device
- **Simulator limitations**: No GPS, no motion data, no haptics
- **Use mocks**: `MockLocationService`, `MockMotionService` for development
- **Device required for**: Full feature testing, background audio verification

## Code Style Conventions

- Use `// MARK: - Section` to organize code within files
- ViewModels: `@Published` properties at top, computed properties next, methods last
- Services: Protocol definition first, concrete implementation second, mock at bottom
- Accessibility: Add `.accessibilityLabel()` to all interactive elements
- Comments: Explain "why" not "what"; algorithm details get doc comments

## Known Limitations

- **Cadence algorithm**: Heuristic-based, not personalized machine learning
- **GPS accuracy**: Urban canyons / indoors will have poor signal
- **Pedometer availability**: Requires iPhone 6+ for cadence data
- **No workout persistence**: Runs are not saved (future enhancement)
- **Single unit system**: Can't mix mph with min/km (either imperial or metric)

## Troubleshooting Tips

- **"Metronome doesn't play"**: Check Background Modes capability, audio session category
- **"GPS not updating"**: Verify location permission, test outdoors
- **"Actual cadence shows nil"**: Check motion permission, requires physical device
- **"BPM changes have gaps"**: Increase `scheduleAheadTime`, reduce background CPU load
- **"HealthKit data missing"**: Grant permission, ensure data exists in Health app
