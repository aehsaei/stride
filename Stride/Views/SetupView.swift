import SwiftUI

struct SetupView: View {
    @StateObject private var viewModel = SetupViewModel()
    @State private var showingRunView = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    suggestedCadenceSection
                    targetSpeedSection
                    biometricsSection
                    metronomeSettingsSection
                    personalizationSection

                    // Start button
                    NavigationLink(destination: runView) {
                        Text("Start Run")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("Stride")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadBiometricsFromHealth()
            }
        }
    }

    // MARK: - Sections

    private var biometricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Biometrics")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 16) {
                // Height
                HStack {
                    Text("Height")
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 4) {
                        TextField("", value: $viewModel.heightFeet, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 35)
                            .onChange(of: viewModel.heightFeet) { _ in
                                viewModel.onHeightChanged()
                            }
                        Text("ft")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("", value: $viewModel.heightInches, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 35)
                            .onChange(of: viewModel.heightInches) { newValue in
                                // Clamp inches to 0-11
                                if newValue >= 12 {
                                    viewModel.heightFeet += newValue / 12
                                    viewModel.heightInches = newValue % 12
                                } else if newValue < 0 {
                                    viewModel.heightInches = 0
                                }
                                viewModel.onHeightChanged()
                            }
                        Text("in")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // Weight
                HStack {
                    Text("Weight")
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 4) {
                        TextField("", value: $viewModel.weightValue, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("lbs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
        }
    }

    private var targetSpeedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Target Pace")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 12) {
                HStack {
                    Text("Pace")
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Minutes input
                    TextField("", value: $viewModel.targetPaceMinutes, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 35)
                        .onChange(of: viewModel.targetPaceMinutes) { _ in
                            viewModel.onPaceChanged()
                        }

                    Text(":").font(.headline)

                    // Seconds input
                    TextField("", value: $viewModel.targetPaceSeconds, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 35)
                        .onChange(of: viewModel.targetPaceSeconds) { newValue in
                            if newValue >= 60 {
                                viewModel.targetPaceMinutes += floor(newValue / 60)
                                viewModel.targetPaceSeconds = newValue.truncatingRemainder(dividingBy: 60)
                            } else if newValue < 0 {
                                viewModel.targetPaceSeconds = 0
                            }
                            viewModel.onPaceChanged()
                        }

                    Picker("", selection: $viewModel.paceUnit) {
                        ForEach(PaceUnit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                    .onChange(of: viewModel.paceUnit) { newUnit in
                        viewModel.convertPaceUnit(to: newUnit)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
        }
    }

    private var metronomeSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metronome")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 16) {
                Picker("Cue Mode", selection: $viewModel.cueMode) {
                    ForEach(CueMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)

                Divider()

                Picker("Sound", selection: $viewModel.soundSet) {
                    ForEach(SoundSet.allCases) { sound in
                        Text(sound.rawValue).tag(sound)
                    }
                }
                .pickerStyle(.menu)

                Divider()

                Toggle("Haptic Cues", isOn: $viewModel.enableHaptics)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
        }
    }

    private var personalizationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personalization")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 12) {
                HStack {
                    Text("Cadence Offset")
                    Spacer()
                    Text("\(viewModel.personalizationDelta >= 0 ? "+" : "")\(Int(viewModel.personalizationDelta)) spm")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }

                Slider(value: $viewModel.personalizationDelta, in: -10...10, step: 1)
                    .onChange(of: viewModel.personalizationDelta) { _ in
                        viewModel.onPersonalizationChanged()
                    }

                Text("Adjust after your first run")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
        }
    }

    private var suggestedCadenceSection: some View {
        VStack(spacing: 8) {
            Text("\(Int(viewModel.suggestedCadence))")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(.accentColor)

            Text("steps per minute")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }

    private var runView: some View {
        RunView(
            viewModel: RunViewModel(
                biometric: viewModel.biometric,
                targetPaceMinutes: viewModel.targetPaceMinutes,
                targetPaceSeconds: viewModel.targetPaceSeconds,
                paceUnit: viewModel.paceUnit,
                cueMode: viewModel.cueMode,
                soundSet: viewModel.soundSet,
                enableHaptics: viewModel.enableHaptics,
                personalizationDelta: viewModel.personalizationDelta
            )
        )
    }
}

// MARK: - Preview

#Preview {
    SetupView()
}
