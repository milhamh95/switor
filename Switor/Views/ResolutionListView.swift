import SwiftUI

/// List view showing all available display modes as dropdown pickers
struct ResolutionListView: View {
    let display: Display
    let onModeSelected: (DisplayMode, Display) -> Void

    @State private var selectedResolutionIndex: Int = 0
    @State private var selectedRefreshRateIndex: Int = 0
    @State private var isHiDPI: Bool = false
    @State private var isInitialized: Bool = false

    private var uniqueResolutions: [ResolutionGroup] {
        display.uniqueResolutions(hiDPI: isHiDPI)
    }

    private var currentGroup: ResolutionGroup? {
        guard selectedResolutionIndex >= 0 && selectedResolutionIndex < uniqueResolutions.count else {
            return nil
        }
        return uniqueResolutions[selectedResolutionIndex]
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
                            selectedResolutionIndex = 0
                            selectedRefreshRateIndex = 0
                            applySelectedMode()
                        }
                }
            }

            // Resolution picker
            HStack {
                Text("Resolution")
                    .font(.body)
                    .foregroundColor(.secondary)

                Spacer()

                Picker("", selection: $selectedResolutionIndex) {
                    ForEach(Array(uniqueResolutions.enumerated()), id: \.offset) { index, group in
                        Text(group.resolutionString)
                            .tag(index)
                    }
                }
                .pickerStyle(.menu)
                .frame(minWidth: 140)
                .onChange(of: selectedResolutionIndex) { _ in
                    guard isInitialized else { return }
                    // Reset refresh rate index when resolution changes
                    selectedRefreshRateIndex = 0
                    applySelectedMode()
                }
            }

            // Refresh rate picker
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
            selectedResolutionIndex = groupIndex

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
