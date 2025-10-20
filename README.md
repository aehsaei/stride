# Stride

A Swift/SwiftUI iOS app that helps runners maintain optimal cadence by providing a real-time metronome that adapts to your running speed and biometrics.

## Features

### Core Functionality
- **Biometric-based cadence suggestions**: Input height and weight (or sync from HealthKit) to get personalized cadence recommendations
- **Precise metronome**: Sample-accurate audio scheduling using AVAudioEngine that plays continuously, even with screen locked
- **Real-time adjustments**: Modify target pace mid-run with smooth BPM transitions (no audio gaps or clicks)
- **GPS-based auto-adjustment**: Optional GPS tracking that automatically adjusts cadence based on your current running speed
- **Actual cadence tracking**: Uses CoreMotion pedometer to compare your real cadence vs. target
- **Multiple cue modes**: Choose "Every Step" or "Every Other Step" metronome beats
- **Haptic feedback**: Optional haptic taps synchronized with audio beats (on supported devices)

### Technical Features
- Background audio playback (continues when device is locked)
- Unit conversion support (mph/km/h, cm/in, kg/lbs, min/km, min/mi)
- Personalization offset (±10 spm adjustment based on user preference)
- Accessible VoiceOver support
- Clean MVVM architecture with dependency injection for testability

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+
- Physical device recommended for:
  - GPS/Location tracking
  - Motion/Pedometer data
  - Haptic feedback

## Installation

### 1. Clone the Repository
```bash
git clone <repository-url>
cd stride
```

### 2. Open in Xcode
```bash
open Stride/StrideApp.swift
```

Or manually:
1. Launch Xcode
2. Select "Open a project or file"
3. Navigate to the `stride` directory
4. Select the `Stride` folder

### 3. Configure Project Settings

Create an Xcode project if one doesn't exist:

1. **File > New > Project**
2. Select **iOS > App**
3. Product Name: `Stride`
4. Interface: **SwiftUI**
5. Language: **Swift**
6. Save in the `stride` directory

Then add all source files:
- Drag the `Stride` folder into the Xcode project navigator
- Ensure "Copy items if needed" is checked
- Ensure the target is selected

### 4. Enable Background Audio

1. Select the project in Xcode
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **Background Modes**
5. Check **Audio, AirPlay, and Picture in Picture**

### 5. Add Info.plist Entries

The `Info.plist` file is included with necessary permission strings:
- Location (when in use)
- Motion & Fitness
- Health Share (for height/weight)

### 6. Build and Run

1. Select a target device (physical device recommended)
2. Press **Cmd+R** or click the **Run** button
3. Grant permissions when prompted:
   - Location access (for GPS pace tracking)
   - Motion & Fitness (for pedometer cadence)
   - Health (for reading height/weight - optional)

## Usage

### Setup Screen

1. **Enter Biometrics**:
   - Height (cm or inches)
   - Weight (kg or lbs)
   - Or tap "Load from Health" to sync from HealthKit

2. **Set Target Speed**:
   - Use slider or text field
   - Toggle between mph and km/h

3. **Configure Metronome**:
   - **Cue Mode**: Every step (full cadence) or every other step (half cadence)
   - **Sound**: Choose click, woodblock, or hi-hat
   - **Haptic Cues**: Enable vibration with beats

4. **Personalization** (optional):
   - Adjust cadence offset (±10 spm) after your first run

5. **Review Suggested Cadence**: Based on your inputs, the app calculates optimal cadence

6. **Tap "Start Run"**

### Run Screen

1. **Main Display**:
   - Large target cadence (spm)
   - Current pace (min/km or min/mi)
   - Actual cadence (if available from pedometer)

2. **Controls**:
   - **Play/Pause**: Pause/resume metronome
   - **Follow GPS Pace**: Toggle to auto-adjust cadence based on GPS speed
   - **Speed Slider**: Manually adjust target speed (when not following GPS)
   - **± Buttons**: Fine-tune speed in 0.5 increments
   - **Settings**: Change cue mode, sound, or haptics on the fly

3. **Live Adjustments**:
   - Changes to speed/settings update metronome within ~300ms
   - BPM changes are phase-aligned to avoid audio artifacts

4. **End Run**: Tap "End Run" to stop and return to setup

### Background Operation

- The metronome continues playing when you:
  - Lock your screen
  - Switch to another app
  - Take a call (pauses automatically, resumes after)

- To ensure background audio:
  - Don't force-quit the app
  - Keep audio session active (automatic)

## Cadence Calculation Algorithm

The app uses a practical heuristic that balances biomechanics with real-world running data:

### Formula

```
baseCadence = 170 spm (typical at ~3 m/s easy pace)
cadence = baseCadence + cadenceSlope × (speed_mps - 3.0)
cadence = clamp(cadence, 155, 195)
```

Where:
- `cadenceSlope` = 8 spm per 1 m/s speed change
- `speed_mps` = target speed in meters per second

### Stride Length Validation

```
legLength ≈ 0.53 × height (in meters)
strideLength = speed × 60 / cadence

If strideLength < 0.7 × legLength: decrease cadence slightly
If strideLength > 1.3 × legLength: increase cadence slightly
```

This ensures the suggested cadence results in a biomechanically reasonable stride.

### Personalization

After your first run, adjust the "Cadence Offset" slider to match your preference. This adds/subtracts up to 10 spm from the calculated value.

### Limitations

- This is a **heuristic model**, not medical advice
- Individual biomechanics vary significantly
- Factors not considered: fitness level, terrain, fatigue, footwear, running form
- Recommended range: 155-195 spm (typical for most runners)

### Tweaking Constants

Edit `Stride/Models/CadenceModel.swift`:

```swift
struct CadenceModelConfig {
    let baseCadence: Double = 170        // Baseline at easy pace
    let cadenceSlope: Double = 8         // spm per m/s
    let minCadence: Double = 155         // Lower bound
    let maxCadence: Double = 195         // Upper bound
    let legLengthFactor: Double = 0.53   // Leg length estimation
    // ...
}
```

## Custom Audio Sounds

### Current Implementation
The app generates a simple click sound programmatically. No external audio files are required.

### Adding Custom Sounds

1. Create or download short WAV files:
   - `click.wav`
   - `woodblock.wav`
   - `hihat.wav`

2. Add to project:
   - Drag files into `Stride/Audio/ClickAssets/` in Xcode
   - Ensure "Copy items if needed" is checked
   - Ensure files are added to the app target

3. Update `MetronomeEngine.swift`:
   - Replace `generateClickBuffer()` call with file loading
   - See `Stride/Audio/ClickAssets/README.md` for code snippet

### Audio Specifications
- Format: WAV (uncompressed PCM)
- Sample rate: 44100 Hz
- Duration: 10-50ms (short transients work best)

## Architecture

### Project Structure

```
Stride/
├── Models/
│   ├── Biometric.swift          # User biometric data model
│   ├── CadenceModel.swift       # Cadence calculation logic
│   └── Units.swift              # Unit conversion utilities
├── Audio/
│   ├── MetronomeEngine.swift    # AVAudioEngine metronome
│   └── ClickAssets/             # Audio files (optional)
├── Services/
│   ├── PaceSource.swift         # Manual vs GPS enum
│   ├── LocationService.swift    # CoreLocation wrapper
│   ├── MotionService.swift      # CoreMotion wrapper
│   └── HealthService.swift      # HealthKit wrapper
├── ViewModels/
│   ├── SetupViewModel.swift     # Setup screen logic
│   └── RunViewModel.swift       # Run screen logic
├── Views/
│   ├── SetupView.swift          # Setup UI
│   └── RunView.swift            # Run UI
└── App/
    └── StrideApp.swift    # App entry point
```

### Design Patterns
- **MVVM**: Clean separation of UI and business logic
- **Protocol-oriented**: Services use protocols for testability/mocking
- **Dependency Injection**: ViewModels accept service dependencies
- **Combine**: Reactive updates for location/motion data

### Key Components

**MetronomeEngine**:
- AVAudioEngine with AVAudioPlayerNode for sample-accurate scheduling
- Schedules beats 500ms ahead in a loop
- Handles BPM changes with phase alignment
- Optional CoreHaptics integration

**CadenceModel**:
- Calculates optimal cadence from biometrics and speed
- Validates stride length against leg length
- Applies personalization offsets

**Services**:
- LocationService: GPS speed tracking with smoothing
- MotionService: Real-time cadence from CMPedometer
- HealthService: Read height/weight from HealthKit

## Testing

### Unit Tests (Future)
Create `StrideTests` target and test:
- Unit conversions (`Units.swift`)
- Cadence calculations at edge cases (1.5 m/s, 5 m/s, different heights)
- Stride length validation logic

Example:
```swift
func testCadenceSuggestionAtSlowPace() {
    let model = CadenceModel()
    let bio = Biometric(heightMeters: 1.75, weightKg: 70)
    let cadence = model.suggestedCadence(biometric: bio, speedMps: 2.0)
    XCTAssertGreaterThan(cadence, 155)
    XCTAssertLessThan(cadence, 175)
}
```

### Metronome Timing Test
Use audio analysis tools to verify inter-beat interval accuracy (±5ms at 180 spm).

### Preview Providers
Both views include SwiftUI preview providers with mocked services:
```swift
#Preview {
    SetupView(viewModel: SetupViewModel(healthService: MockHealthService()))
}
```

## Troubleshooting

### Audio doesn't play in background
- Verify **Background Modes > Audio** is enabled in project capabilities
- Check that audio session is set to `.playback` category
- Ensure app is not force-quit

### Location not updating
- Grant "When In Use" location permission
- Check that GPS is enabled on device
- Test outdoors with clear sky view

### Pedometer not working
- Grant Motion & Fitness permission
- CMPedometer requires physical device (not simulator)
- Not all devices support cadence (iPhone 6+ required)

### HealthKit not loading data
- Grant Health app read permission
- Ensure height/weight data exists in Health app
- HealthKit only works on physical devices

### Audio stuttering or gaps
- Reduce other background processes
- Check `scheduleAheadTime` in MetronomeEngine (default 0.5s)
- Ensure device has sufficient CPU/memory

## Roadmap / Future Enhancements

Potential features for future versions:
- [ ] Run history and statistics
- [ ] Training plans with progressive cadence goals
- [ ] Audio cues for pace zones (e.g., "Speed up" voice prompts)
- [ ] Apple Watch companion app with haptics
- [ ] Workout integration (save runs to HealthKit)
- [ ] Advanced biomechanical modeling (VO2 max, stride asymmetry)
- [ ] Cloud sync and social features
- [ ] Bluetooth heart rate monitor integration

## Contributing

This is a proof-of-concept app. Contributions welcome:
1. Fork the repository
2. Create a feature branch
3. Make changes with clear comments
4. Test on physical device
5. Submit a pull request

## License

[Add your license here - e.g., MIT, Apache 2.0, etc.]

## Disclaimer

**This app is for educational and fitness purposes only. It is not medical advice.**

Consult with a healthcare professional before starting any running program. The cadence suggestions are based on general biomechanical heuristics and may not be appropriate for all individuals.

## Credits

- Built with Swift, SwiftUI, AVFoundation, CoreLocation, CoreMotion, and HealthKit
- Cadence algorithm based on research from running biomechanics literature
- Proof-of-concept developed as a technical demonstration

## Support

For issues or questions:
1. Check the Troubleshooting section
2. Review code comments for implementation details
3. Open an issue on GitHub (if applicable)

---

**Happy running! 🏃‍♂️🎵**
