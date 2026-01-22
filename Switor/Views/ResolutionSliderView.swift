import SwiftUI

/// Slider-based resolution selector for quick resolution changes
struct ResolutionSliderView: View {
    let display: Display
    let onModeSelected: (DisplayMode, Display) -> Void

    @State private var selectedIndex: Double = 0
    @State private var selectedRefreshRateIndex: Int = 0
    @State private var isHiDPI: Bool = false
    @State private var isInitialized: Bool = false

    private var uniqueResolutions: [ResolutionGroup] {
        display.uniqueResolutions(hiDPI: isHiDPI)
    }

    private var currentGroup: ResolutionGroup? {
        let index = Int(selectedIndex)
        guard index >= 0 && index < uniqueResolutions.count else { return nil }
        return uniqueResolutions[index]
    }

    private var availableRefreshRates: [DisplayMode] {
        currentGroup?.refreshRates ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // HiDPI toggle (only show if both modes available)
            if display.hasHiDPIModes && display.hasNonHiDPIModes {
                HStack {
                    Text("HiDPI (Retina)")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Spacer()

                    Toggle("", isOn: $isHiDPI)
                        .toggleStyle(.switch)
                        .controlSize(.regular)
                        .onChange(of: isHiDPI) { _ in
                            guard isInitialized else { return }
                            // Reset selection when toggling HiDPI
                            selectedIndex = 0
                            selectedRefreshRateIndex = 0
                            applySelectedMode()
                        }
                }
            }

            // Resolution slider
            if !uniqueResolutions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Resolution")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Spacer()
                        if let group = currentGroup {
                            Text(group.resolutionString)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }

                    Slider(
                        value: $selectedIndex,
                        in: 0...Double(max(0, uniqueResolutions.count - 1)),
                        step: 1
                    ) { editing in
                        if !editing && isInitialized {
                            applySelectedMode()
                        }
                    }

                    // Resolution markers
                    HStack {
                        if let first = uniqueResolutions.first {
                            Text(first.resolutionString)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if uniqueResolutions.count > 1, let last = uniqueResolutions.last {
                            Text(last.resolutionString)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Refresh rate picker (if multiple available)
                if availableRefreshRates.count > 1 {
                    HStack {
                        Text("Refresh Rate")
                            .font(.body)
                            .foregroundColor(.secondary)

                        Spacer()

                        Picker("", selection: $selectedRefreshRateIndex) {
                            ForEach(Array(availableRefreshRates.enumerated()), id: \.offset) { index, mode in
                                Text(mode.refreshRateString)
                                    .tag(index)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(minWidth: 90)
                        .onChange(of: selectedRefreshRateIndex) { _ in
                            guard isInitialized else { return }
                            applySelectedMode()
                        }
                    }
                }
            } else {
                Text("No modes available")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            initializeSelection()
        }
        .onChange(of: display.currentMode) { _ in
            initializeSelection()
        }
    }

    private func initializeSelection() {
        isInitialized = false

        guard let currentMode = display.currentMode else {
            isInitialized = true
            return
        }

        // Set HiDPI toggle based on current mode
        isHiDPI = currentMode.isHiDPI

        // Find the index of the current resolution group
        let resolutions = display.uniqueResolutions(hiDPI: isHiDPI)
        if let groupIndex = resolutions.firstIndex(where: { group in
            group.width == currentMode.width &&
            group.height == currentMode.height
        }) {
            selectedIndex = Double(groupIndex)

            // Find the index of the current refresh rate
            if let rateIndex = resolutions[groupIndex].refreshRates.firstIndex(where: { mode in
                abs(mode.refreshRate - currentMode.refreshRate) < 1.0
            }) {
                selectedRefreshRateIndex = rateIndex
            }
        }

        // Mark as initialized after a brief delay to avoid triggering onChange
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isInitialized = true
        }
    }

    private func applySelectedMode() {
        guard let group = currentGroup else { return }

        let rateIndex = min(selectedRefreshRateIndex, group.refreshRates.count - 1)
        guard rateIndex >= 0 else { return }

        let mode = group.refreshRates[rateIndex]
        onModeSelected(mode, display)
    }
}
