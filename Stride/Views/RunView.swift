import SwiftUI

struct RunView: View {
    @StateObject private var viewModel: RunViewModel
    @Environment(\.dismiss) private var dismiss

    nonisolated init(viewModel: RunViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Main cadence display
                    mainCadenceDisplay

                    // Controls section
                    controlsSection
                }
                .padding()
            }
        }
        .navigationTitle("Running")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("End") {
                    viewModel.endRun()
                    dismiss()
                }
                .foregroundColor(.red)
                .fontWeight(.semibold)
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
        VStack(spacing: 24) {
            // Target cadence (large display)
            VStack(spacing: 12) {
                Text("\(Int(viewModel.targetCadence))")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundColor(.accentColor)
                    .contentTransition(.numericText())

                Text("steps per minute")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 12, y: 4)

            // Play/Pause button
            playPauseButton

            // Actual cadence comparison
            if let actualCadence = viewModel.actualCadence {
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Actual")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text("\(Int(actualCadence))")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 4) {
                        Text("Difference")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(viewModel.cadenceComparison)
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundColor(actualCadenceColor)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
            }

            // Current pace display
            VStack(spacing: 8) {
                Text("Current Pace")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Text(viewModel.displayPace)
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
        }
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
            HStack(spacing: 12) {
                Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                    .font(.title2)
                Text(viewModel.isRunning ? "Pause" : "Resume")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isRunning ? Color.orange : Color.accentColor)
            .cornerRadius(12)
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        VStack(spacing: 20) {
            // Speed controls
            speedControls

            // Settings toggles
            settingsToggles
        }
    }

    private var speedControls: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Target Pace")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Text(String(format: "%d:%02d %@",
                           Int(viewModel.targetPaceMinutes),
                           Int(viewModel.targetPaceSeconds),
                           viewModel.paceUnit.rawValue))
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
            }

            HStack(spacing: 12) {
                Button(action: viewModel.decreasePace) {
                    HStack {
                        Image(systemName: "minus")
                        Text("15s")
                    }
                    .font(.headline)
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }

                Button(action: viewModel.increasePace) {
                    HStack {
                        Image(systemName: "plus")
                        Text("15s")
                    }
                    .font(.headline)
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var settingsToggles: some View {
        VStack(spacing: 0) {
            // Cue mode
            HStack {
                Text("Cue Mode")

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
            .padding()

            Divider()
                .padding(.leading)

            // Sound set
            HStack {
                Text("Sound")

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
            .padding()

            Divider()
                .padding(.leading)

            // Haptics toggle
            HStack {
                Text("Haptic Cues")

                Spacer()

                Toggle("", isOn: $viewModel.enableHaptics)
                    .labelsHidden()
                    .onChange(of: viewModel.enableHaptics) { newValue in
                        viewModel.onHapticsChanged(newValue)
                    }
            }
            .padding()
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RunView(
            viewModel: RunViewModel(
                biometric: Biometric(heightMeters: 1.75, weightKg: 70),
                targetPaceMinutes: 10.0,
                targetPaceSeconds: 0.0,
                paceUnit: .minPerMi,
                cueMode: .everyStep,
                soundSet: .click,
                enableHaptics: false,
                personalizationDelta: 0,
                motionService: MockMotionService()
            )
        )
    }
}
