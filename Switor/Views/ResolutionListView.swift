import SwiftUI

/// List view showing all available display modes as dropdown pickers
struct ResolutionListView: View {
    let display: Display
    let onModeSelected: (DisplayMode, Display) -> Void

    @State private var selectedResolutionIndex: Int = 0
    @State private var selectedModeIndex: Int = 0
    @State private var isInitialized: Bool = false

    /// Get unique resolutions from HiDPI modes only (720p and above)
    private var uniqueResolutions: [SimpleResolution] {
        var seen: Set<String> = []
        var result: [SimpleResolution] = []

        // Only consider HiDPI modes with height >= 720
        for mode in display.availableModes where mode.isHiDPI && mode.height >= 720 {
            let key = "\(mode.width)x\(mode.height)"
            if !seen.contains(key) {
                seen.insert(key)
                result.append(SimpleResolution(width: mode.width, height: mode.height))
            }
        }

        // Sort from lowest to highest
        return result.sorted { lhs, rhs in
            if lhs.width != rhs.width {
                return lhs.width < rhs.width
            }
            return lhs.height < rhs.height
        }
    }

    /// Get HiDPI modes for the selected resolution (different refresh rates)
    private var availableModes: [DisplayMode] {
        guard selectedResolutionIndex >= 0 && selectedResolutionIndex < uniqueResolutions.count else {
            return []
        }
        let resolution = uniqueResolutions[selectedResolutionIndex]

        // Get HiDPI modes matching this resolution
        let modes = display.availableModes.filter {
            $0.width == resolution.width && $0.height == resolution.height && $0.isHiDPI
        }

        // Deduplicate by rounded refresh rate
        var seen: Set<Int> = []
        return modes
            .sorted { $0.refreshRate > $1.refreshRate }
            .filter { mode in
                let roundedRate = Int(mode.refreshRate.rounded())
                if seen.contains(roundedRate) {
                    return false
                }
                seen.insert(roundedRate)
                return true
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Resolution picker
            HStack {
                Text("Resolution")
                    .font(.body)
                    .foregroundColor(.secondary)

                Spacer()

                Picker("", selection: $selectedResolutionIndex) {
                    ForEach(Array(uniqueResolutions.enumerated()), id: \.offset) { index, res in
                        Text(res.displayString)
                            .tag(index)
                    }
                }
                .pickerStyle(.menu)
                .frame(minWidth: 140)
                .onChange(of: selectedResolutionIndex) { _ in
                    guard isInitialized else { return }
                    // Reset mode index when resolution changes
                    selectedModeIndex = 0
                    applySelectedMode()
                }
            }

            // Refresh rate + HiDPI picker
            HStack {
                Text("Refresh Rate")
                    .font(.body)
                    .foregroundColor(.secondary)

                Spacer()

                Picker("", selection: $selectedModeIndex) {
                    ForEach(Array(availableModes.enumerated()), id: \.offset) { index, mode in
                        Text(mode.refreshRateString)
                            .tag(index)
                    }
                }
                .pickerStyle(.menu)
                .frame(minWidth: 130)
                .onChange(of: selectedModeIndex) { _ in
                    guard isInitialized else { return }
                    applySelectedMode()
                }
            }
        }
        .onAppear {
            initializeSelection()
        }
        .onChange(of: display.currentMode?.id) { _ in
            initializeSelection()
        }
        .id("\(display.id)-\(display.currentMode?.id.uuidString ?? "none")")
    }

    private func initializeSelection() {
        isInitialized = false

        guard let currentMode = display.currentMode else {
            isInitialized = true
            return
        }

        let resolutions = uniqueResolutions

        // Find the index of the current resolution
        if let resIndex = resolutions.firstIndex(where: {
            $0.width == currentMode.width && $0.height == currentMode.height
        }) {
            selectedResolutionIndex = resIndex

            // Get available modes for this resolution directly (don't use computed property)
            let resolution = resolutions[resIndex]
            var seen: Set<Int> = []
            let modes = display.availableModes
                .filter { $0.width == resolution.width && $0.height == resolution.height && $0.isHiDPI }
                .sorted { $0.refreshRate > $1.refreshRate }
                .filter { mode in
                    let roundedRate = Int(mode.refreshRate.rounded())
                    if seen.contains(roundedRate) { return false }
                    seen.insert(roundedRate)
                    return true
                }

            // Find the index of the current mode (refresh rate)
            if let modeIndex = modes.firstIndex(where: { mode in
                abs(mode.refreshRate - currentMode.refreshRate) < 1.0
            }) {
                selectedModeIndex = modeIndex
            } else {
                selectedModeIndex = 0
            }
        } else {
            selectedResolutionIndex = 0
            selectedModeIndex = 0
        }

        // Mark as initialized after a brief delay to avoid triggering onChange
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isInitialized = true
        }
    }

    private func applySelectedMode() {
        guard selectedModeIndex >= 0 && selectedModeIndex < availableModes.count else { return }
        let mode = availableModes[selectedModeIndex]
        onModeSelected(mode, display)
    }
}

/// Simple resolution without HiDPI info
private struct SimpleResolution {
    let width: Int
    let height: Int

    var displayString: String {
        "\(width) × \(height)"
    }
}
