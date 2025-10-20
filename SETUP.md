# Quick Setup Guide for Stride

## Step 1: Create Xcode Project

Since the source files are provided without an `.xcodeproj` file, you need to create one:

1. Open Xcode
2. **File > New > Project**
3. Select **iOS > App**
4. Configure:
   - Product Name: `Stride`
   - Team: (your team)
   - Organization Identifier: `com.yourname`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
   - Include Tests: (optional)
5. Save location: **Select the `stride` directory**
6. Click **Create**

## Step 2: Add Source Files

1. Delete the default `ContentView.swift` file created by Xcode
2. In Finder, drag the entire `Stride` folder into the Xcode project navigator
3. When prompted:
   - **Check**: "Copy items if needed"
   - **Select**: "Create groups"
   - **Add to targets**: Check `Stride`
4. Click **Finish**

## Step 3: Configure Info.plist

The `Info.plist` file is already included. Merge its contents into your project's Info.plist:

1. Select the project in the navigator
2. Select the **Stride** target
3. Go to the **Info** tab
4. Add custom iOS target properties:
   - `NSLocationWhenInUseUsageDescription`
   - `NSMotionUsageDescription`
   - `NSHealthShareUsageDescription`

Or replace Xcode's Info.plist with the provided one.

## Step 4: Enable Background Audio

1. Select the project in the navigator
2. Select the **Stride** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Background Modes**
6. Check: **Audio, AirPlay, and Picture in Picture**

## Step 5: Set Deployment Target

1. In **Signing & Capabilities** (or General tab)
2. Set **iOS Deployment Target** to **16.0** or higher

## Step 6: Build and Run

1. Select a target device:
   - **Simulator** (limited features): Any iPhone simulator
   - **Physical device** (recommended): Your iPhone connected via USB
2. Press **Cmd+R** or click the **Run** button
3. Grant permissions when prompted

## Troubleshooting

### "No such module" errors
- Ensure all `.swift` files are added to the target (check File Inspector)
- Clean build folder: **Product > Clean Build Folder** (Shift+Cmd+K)

### "Missing Info.plist keys" warnings
- Copy permission strings from `Stride/Info.plist` to your project's Info.plist

### Audio doesn't play
- Verify Background Modes > Audio is enabled
- Check device volume and mute switch

### Build succeeds but app crashes on launch
- Check that `StrideApp.swift` is set as the `@main` entry point
- Ensure all files are in the correct target membership

## Project Structure Overview

```
Stride/
├── Models/              (13 files total)
├── Audio/
├── Services/
├── ViewModels/
├── Views/
├── App/
└── Info.plist

Supporting Files:
├── README.md           (comprehensive documentation)
├── CLAUDE.md           (AI assistant guide)
└── SETUP.md            (this file)
```

## Next Steps

1. Read **README.md** for full feature documentation
2. Read **CLAUDE.md** for architecture details
3. Test on a physical device for full feature set
4. Customize cadence algorithm constants if needed
5. Add custom WAV sound files (optional)

## Minimum Requirements

- macOS with Xcode 15+
- iOS 16.0+ deployment target
- Apple Developer account (free tier OK for device testing)
- Physical iPhone (optional but highly recommended)
