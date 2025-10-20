import SwiftUI

struct SetupView: View {
    @StateObject private var viewModel: SetupViewModel
    @State private var showingRunView = false

    init(viewModel: SetupViewModel = SetupViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                biometricsSection
                targetSpeedSection
                metronomeSettingsSection
                personalizationSection
                suggestedCadenceSection
            }
            .navigationTitle("Stride")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: runView) {
                        Text("Start Run")
                            .fontWeight(.semibold)
                    }
                }
            }
            .task {
                await viewModel.loadBiometricsFromHealth()
            }
        }
    }

    // MARK: - Sections

    private var biometricsSection: some View {
        Section("Biometrics") {
            // Height
            HStack {
                Text("Height")
                Spacer()
                TextField("Height", value: $viewModel.heightValue, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .onChange(of: viewModel.heightValue) { _ in
                        viewModel.onHeightChanged()
                    }

                Picker("", selection: $viewModel.heightUnit) {
                    ForEach(HeightUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.heightUnit) { newUnit in
                    viewModel.convertHeightUnit(to: newUnit)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Height: \(Int(viewModel.heightValue)) \(viewModel.heightUnit.rawValue)")

            // Weight
            HStack {
                Text("Weight")
                Spacer()
                TextField("Weight", value: $viewModel.weightValue, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)

                Picker("", selection: $viewModel.weightUnit) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.weightUnit) { newUnit in
                    viewModel.convertWeightUnit(to: newUnit)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Weight: \(Int(viewModel.weightValue)) \(viewModel.weightUnit.rawValue)")
        }
    }

    private var targetSpeedSection: some View {
        Section("Target Speed") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Speed")
                    Spacer()
                    TextField("Speed", value: $viewModel.targetSpeedValue, format: .number.precision(.fractionLength(1)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        .onChange(of: viewModel.targetSpeedValue) { _ in
                            viewModel.onSpeedChanged()
                        }

                    Picker("", selection: $viewModel.speedUnit) {
                        ForEach(SpeedUnit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: viewModel.speedUnit) { newUnit in
                        viewModel.convertSpeedUnit(to: newUnit)
                    }
                }

                Slider(value: $viewModel.targetSpeedValue, in: 1.0...15.0, step: 0.5)
                    .onChange(of: viewModel.targetSpeedValue) { _ in
                        viewModel.onSpeedChanged()
                    }
                    .accessibilityLabel("Speed slider")
            }
        }
    }

    private var metronomeSettingsSection: some View {
        Section("Metronome Settings") {
            Picker("Cue Mode", selection: $viewModel.cueMode) {
                ForEach(CueMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .accessibilityLabel("Cue mode: \(viewModel.cueMode.rawValue)")

            Picker("Sound", selection: $viewModel.soundSet) {
                ForEach(SoundSet.allCases) { sound in
                    Text(sound.rawValue).tag(sound)
                }
            }
            .accessibilityLabel("Sound: \(viewModel.soundSet.rawValue)")

            Toggle("Haptic Cues", isOn: $viewModel.enableHaptics)
                .accessibilityLabel("Haptic cues: \(viewModel.enableHaptics ? "enabled" : "disabled")")
        }
    }

    private var personalizationSection: some View {
        Section("Personalization") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Cadence Offset")
                    Spacer()
                    Text("\(viewModel.personalizationDelta >= 0 ? "+" : "")\(Int(viewModel.personalizationDelta)) spm")
                        .foregroundColor(.secondary)
                }

                Slider(value: $viewModel.personalizationDelta, in: -10...10, step: 1)
                    .onChange(of: viewModel.personalizationDelta) { _ in
                        viewModel.onPersonalizationChanged()
                    }
                    .accessibilityLabel("Personalization offset: \(Int(viewModel.personalizationDelta)) steps per minute")
            }

            Text("Adjust after your first run to match your preferred cadence")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var suggestedCadenceSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suggested Cadence")
                        .font(.headline)
                    Text("Based on your biometrics and target speed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(Int(viewModel.suggestedCadence))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.accentColor)
                + Text(" spm")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Suggested cadence: \(Int(viewModel.suggestedCadence)) steps per minute")
        }
    }

    private var runView: some View {
        RunView(
            viewModel: RunViewModel(
                biometric: viewModel.biometric,
                targetSpeedValue: viewModel.targetSpeedValue,
                speedUnit: viewModel.speedUnit,
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
    SetupView(viewModel: SetupViewModel(healthService: MockHealthService()))
}
