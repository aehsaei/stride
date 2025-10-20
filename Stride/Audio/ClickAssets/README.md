# Audio Assets

This directory should contain the metronome click sound files.

## Required Files

- `click.wav` - Standard metronome click sound
- `woodblock.wav` - Woodblock percussion sound
- `hihat.wav` - Hi-hat cymbal sound

## Specifications

For optimal performance, audio files should be:
- Format: WAV (uncompressed PCM)
- Sample rate: 44100 Hz
- Bit depth: 16-bit
- Channels: Mono or Stereo
- Duration: 10-50ms (short transient sounds)

## Current Implementation

The MetronomeEngine currently generates a simple click sound programmatically in the `generateClickBuffer()` method. To use custom WAV files:

1. Add your WAV files to this directory
2. Add them to the Xcode project (drag into Xcode, ensure "Copy items if needed" is checked)
3. Update `MetronomeEngine.loadSound()` to load from bundle:

```swift
private func loadSound(soundSet: SoundSet) {
    guard let url = Bundle.main.url(forResource: soundSet.fileName, withExtension: nil) else {
        print("Failed to find sound file: \(soundSet.fileName)")
        audioBuffer = generateClickBuffer()  // Fallback
        return
    }

    do {
        audioFile = try AVAudioFile(forReading: url)
        let format = audioFile!.processingFormat
        let frameCount = AVAudioFrameCount(audioFile!.length)

        audioBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
        try audioFile!.read(into: audioBuffer!)
    } catch {
        print("Failed to load audio file: \(error)")
        audioBuffer = generateClickBuffer()  // Fallback
    }
}
```

## Finding Sounds

Free metronome sounds can be found at:
- freesound.org (search "metronome", "click", "woodblock")
- zapsplat.com
- Generate your own using audio software (Audacity, GarageBand, etc.)
