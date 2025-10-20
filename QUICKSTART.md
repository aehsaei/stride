# Quick Start - Open in Xcode

## ✅ Ready to Run!

The Xcode project is now fully configured. Simply:

1. **Double-click** `Stride.xcodeproj` in Finder
   - Or run: `open Stride.xcodeproj`

2. **Select a target device** from the dropdown (next to the Run button):
   - iPhone Simulator (any model)
   - Your physical iPhone (connected via USB)

3. **Press Cmd+R** (or click the Play button) to build and run

## First Launch

When the app first runs, it will request permissions:
- **Location**: For GPS-based pace tracking (optional)
- **Motion & Fitness**: For pedometer cadence measurement (optional)
- **Health**: To read height/weight (optional)

You can deny these and still use the app with manual inputs.

## Project Structure

```
stride/
├── Stride.xcodeproj          ← Double-click this to open in Xcode
├── Stride/                   ← Source code directory
│   ├── App/
│   ├── Views/
│   ├── ViewModels/
│   ├── Models/
│   ├── Audio/
│   ├── Services/
│   ├── Assets.xcassets/
│   └── Info.plist
├── README.md                 ← Full documentation
├── CLAUDE.md                 ← Architecture guide
└── SETUP.md                  ← Manual setup guide (not needed)
```

## Next Steps

- **Simulator**: Works for basic testing, but GPS/Motion/Haptics won't function
- **Physical Device**: Recommended for full feature testing
  - Connect iPhone via USB
  - Trust the computer if prompted
  - Select your device from the target dropdown
  - May need to enable "Developer Mode" in Settings > Privacy & Security

## Capabilities Already Configured

✅ Background Audio enabled (metronome continues with screen locked)
✅ All permissions configured in Info.plist
✅ iOS 16.0+ deployment target
✅ SwiftUI enabled
✅ All source files added to target

## Troubleshooting

**"Signing for Stride requires a development team"**
- Select the project in navigator
- Go to Signing & Capabilities
- Select your Apple ID in the "Team" dropdown
- Or use "Sign to Run Locally" (Xcode 15+)

**Build fails**
- Try Product > Clean Build Folder (Shift+Cmd+K)
- Make sure you're running Xcode 15+
- Check the build log for specific errors

**Can't select physical device**
- Make sure iPhone is unlocked and "Trust This Computer" is confirmed
- Check that USB cable supports data transfer
- In Xcode, go to Window > Devices and Simulators to verify connection

## Features to Test

1. **Setup Screen**: Enter biometrics, adjust target speed, see suggested cadence
2. **Start Run**: Tap "Start Run" to begin metronome
3. **Live Adjustments**: Use speed slider/buttons to change BPM in real-time
4. **GPS Mode**: Toggle "Follow GPS Pace" (requires location permission + outdoor running)
5. **Background Audio**: Lock screen while metronome is playing
6. **Haptics**: Enable in settings (requires physical device)

---

**Happy running! 🏃‍♂️🎵**

For detailed documentation, see **README.md**
