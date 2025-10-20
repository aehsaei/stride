import SwiftUI

struct RunView: View {
    @StateObject private var viewModel: RunViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: RunViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main cadence display
            mainCadenceDisplay
                .frame(maxHeight: .infinity)

            Divider()

            // Controls section
            controlsSection
                .padding()
                .background(Color(uiColor: .systemGroupedBackground))
        }
        .navigationTitle("Running")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("End Run") {
                    viewModel.endRun()
                    dismiss()
                }
                .foregroundColor(.red)
                .accessibilityLabel("End run and return to setup")
            }
        }
        .onAppear {
            MetronomeEngine.configureAudioSession()
            viewModel.startRun()
        }
        .onDisappear {
            if viewModel.isRunning {
                viewModel.endRun()
            }
        }
    }

    // MARK: - Main Display

    private var mainCadenceDisplay: some View {
        VStack(spacing: 20) {
            Spacer()

            // Target cadence (large display)
            VStack(spacing: 8) {
                Text("TARGET CADENCE")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(viewModel.targetCadence))")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.accentColor)
                        .contentTransition(.numericText())

                    Text("spm")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Target cadence: \(Int(viewModel.targetCadence)) steps per minute")
            }

            // Actual cadence comparison
            if let actualCadence = viewModel.actualCadence {
                VStack(spacing: 4) {
                    Text("ACTUAL CADENCE")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Text("\(Int(actualCadence)) spm")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))

                        Text(viewModel.cadenceComparison)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(actualCadenceColor)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Actual cadence: \(Int(actualCadence)) steps per minute, \(viewModel.cadenceComparison)")
            }

            Spacer()

            // Current pace display
            VStack(spacing: 4) {
                Text("CURRENT PACE")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(viewModel.displayPace)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(.bottom, 20)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Current pace: \(viewModel.displayPace) per \(viewModel.speedUnit == .mph ? "mile" : "kilometer")")

            // Play/Pause button
            playPauseButton
                .padding(.bottom, 30)
        }
        .padding()
    }

    private var actualCadenceColor: Color {
        guard let actual = viewModel.actualCadence else { return .secondary }
        let delta = abs(actual - viewModel.targetCadence)

        if delta <= 5 {
            return .green
        } else if delta <= 10 {
            return .orange
        } else {
            return .red
        }
    }

    private var playPauseButton: some View {
        Button(action: {
            if viewModel.isRunning {
                viewModel.pauseRun()
            } else {
                viewModel.resumeRun()
            }
        }) {
            Image(systemName: viewModel.isRunning ? "pause.circle.fill" : "play.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
        }
        .accessibilityLabel(viewModel.isRunning ? "Pause metronome" : "Resume metronome")
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        VStack(spacing: 16) {
            // Pace source toggle
            paceSourceToggle

            Divider()

            // Speed controls (only for manual mode)
            if viewModel.paceSource == .manual {
                speedControls
                Divider()
            }

            // Settings toggles
            settingsToggles
        }
    }

    private var paceSourceToggle: some View {
        HStack {
            Label("Follow GPS Pace", systemImage: "location.fill")
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            Toggle("", isOn: Binding(
                get: { viewModel.paceSource == .gps },
                set: { _ in viewModel.togglePaceSource() }
            ))
            .labelsHidden()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Follow GPS pace: \(viewModel.paceSource == .gps ? "on" : "off")")
    }

    private var speedControls: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Target Speed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text(String(format: "%.1f %@", viewModel.targetSpeedValue, viewModel.speedUnit.rawValue))
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            HStack(spacing: 16) {
                Button(action: viewModel.decreaseSpeed) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)
                }
                .accessibilityLabel("Decrease speed")

                Slider(value: $viewModel.targetSpeedValue, in: 1.0...15.0, step: 0.5)
                    .onChange(of: viewModel.targetSpeedValue) { _ in
                        viewModel.onSpeedChanged()
                    }
                    .accessibilityLabel("Speed slider")

                Button(action: viewModel.increaseSpeed) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)
                }
                .accessibilityLabel("Increase speed")
            }
        }
    }

    private var settingsToggles: some View {
        VStack(spacing: 12) {
            // Cue mode
            HStack {
                Text("Cue Mode")
                    .font(.subheadline)

                Spacer()

                Picker("", selection: $viewModel.cueMode) {
                    ForEach(CueMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.cueMode) { newMode in
                    viewModel.onCueModeChanged(newMode)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Cue mode: \(viewModel.cueMode.rawValue)")

            // Sound set
            HStack {
                Text("Sound")
                    .font(.subheadline)

                Spacer()

                Picker("", selection: $viewModel.soundSet) {
                    ForEach(SoundSet.allCases) { sound in
                        Text(sound.rawValue).tag(sound)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.soundSet) { newSound in
                    viewModel.onSoundSetChanged(newSound)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Sound: \(viewModel.soundSet.rawValue)")

            // Haptics toggle
            HStack {
                Text("Haptic Cues")
                    .font(.subheadline)

                Spacer()

                Toggle("", isOn: $viewModel.enableHaptics)
                    .labelsHidden()
                    .onChange(of: viewModel.enableHaptics) { newValue in
                        viewModel.onHapticsChanged(newValue)
                    }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Haptic cues: \(viewModel.enableHaptics ? "enabled" : "disabled")")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RunView(
            viewModel: RunViewModel(
                biometric: Biometric(heightMeters: 1.75, weightKg: 70),
                targetSpeedValue: 6.0,
                speedUnit: .mph,
                cueMode: .everyStep,
                soundSet: .click,
                enableHaptics: false,
                personalizationDelta: 0,
                locationService: MockLocationService(),
                motionService: MockMotionService()
            )
        )
    }
}
