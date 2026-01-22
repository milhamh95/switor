import SwiftUI

/// Custom progress bar style slider
struct ProgressBarSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    var onEditingChanged: (Bool) -> Void = { _ in }

    @State private var isDragging = false

    private var progress: Double {
        guard range.upperBound > range.lowerBound else { return 0 }
        return (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 12)

                // Filled portion
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor)
                    .frame(width: max(12, geometry.size.width * progress), height: 12)

                // Drag handle (subtle indicator at the end of filled portion)
                Circle()
                    .fill(Color.white)
                    .shadow(radius: 2)
                    .frame(width: 16, height: 16)
                    .offset(x: max(0, geometry.size.width * progress - 8))
            }
            .frame(height: 16)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isDragging {
                            isDragging = true
                            onEditingChanged(true)
                        }
                        let percent = gesture.location.x / geometry.size.width
                        let clampedPercent = min(max(percent, 0), 1)
                        let rawValue = range.lowerBound + clampedPercent * (range.upperBound - range.lowerBound)
                        let steppedValue = (rawValue / step).rounded() * step
                        value = min(max(steppedValue, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        isDragging = false
                        onEditingChanged(false)
                    }
            )
        }
        .frame(height: 16)
    }
}

/// Slider-based resolution selector for quick resolution changes
struct ResolutionSliderView: View {
    let display: Display
    let onModeSelected: (DisplayMode, Display) -> Void

    @State private var selectedIndex: Double = 0
    @State private var selectedRefreshRateIndex: Int = 0
    @State private var isHiDPI: Bool = false
    @State private var isInitialized: Bool = false

    private var uniqueResolutions: [ResolutionGroup] {
        // Filter to 720p and above
        display.uniqueResolutions(hiDPI: isHiDPI).filter { $0.height >= 720 }
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

                    ProgressBarSlider(
                        value: $selectedIndex,
                        range: 0...Double(max(0, uniqueResolutions.count - 1)),
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
        .onChange(of: display.currentMode?.id) { _ in
            initializeSelection()
        }
        .id("\(display.id)-\(display.currentMode?.id.uuidString ?? "none")")
    }

    private func initializeSelection() {
        isInitialized = false

        guard let currentMode = display.currentMode else {
            selectedIndex = 0
            selectedRefreshRateIndex = 0
            isInitialized = true
            return
        }

        // Set HiDPI toggle based on current mode
        isHiDPI = currentMode.isHiDPI

        // Use the same filtered resolutions as the view (720p+)
        let resolutions = display.uniqueResolutions(hiDPI: isHiDPI).filter { $0.height >= 720 }

        // Clamp selectedIndex to valid range
        let maxIndex = max(0, resolutions.count - 1)

        // Find the index of the current resolution group
        if let groupIndex = resolutions.firstIndex(where: { group in
            group.width == currentMode.width &&
            group.height == currentMode.height
        }) {
            selectedIndex = Double(groupIndex)

            // Find the index of the current refresh rate directly
            let refreshRates = resolutions[groupIndex].refreshRates
            if let rateIndex = refreshRates.firstIndex(where: { mode in
                abs(mode.refreshRate - currentMode.refreshRate) < 1.0
            }) {
                selectedRefreshRateIndex = rateIndex
            } else {
                selectedRefreshRateIndex = 0
            }
        } else {
            // Current resolution not in list (below 720p), default to highest
            selectedIndex = Double(maxIndex)
            selectedRefreshRateIndex = 0
        }

        // Ensure index is within bounds
        selectedIndex = min(selectedIndex, Double(maxIndex))

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
