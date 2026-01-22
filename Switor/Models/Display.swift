import Foundation
import CoreGraphics

/// Represents a physical display connected to the Mac
struct Display: Identifiable, Hashable {
    let id: CGDirectDisplayID
    let name: String
    let isBuiltIn: Bool
    let isMain: Bool
    var currentMode: DisplayMode?
    var availableModes: [DisplayMode]

    init(
        id: CGDirectDisplayID,
        name: String,
        isBuiltIn: Bool = false,
        isMain: Bool = false,
        currentMode: DisplayMode? = nil,
        availableModes: [DisplayMode] = []
    ) {
        self.id = id
        self.name = name
        self.isBuiltIn = isBuiltIn
        self.isMain = isMain
        self.currentMode = currentMode
        self.availableModes = availableModes
    }

    /// Display name with additional info
    var displayTitle: String {
        var title = name
        if isBuiltIn {
            title += " (Built-in)"
        }
        if isMain {
            title += " ★"
        }
        return title
    }

    /// Get unique resolutions (grouped by width×height, may have multiple refresh rates)
    var uniqueResolutions: [ResolutionGroup] {
        uniqueResolutions(hiDPI: nil)
    }

    /// Get unique resolutions filtered by HiDPI status
    /// - Parameter hiDPI: nil = all, true = HiDPI only, false = non-HiDPI only
    func uniqueResolutions(hiDPI: Bool?) -> [ResolutionGroup] {
        let filteredModes: [DisplayMode]
        if let hiDPI = hiDPI {
            filteredModes = availableModes.filter { $0.isHiDPI == hiDPI }
        } else {
            filteredModes = availableModes
        }

        let grouped = Dictionary(grouping: filteredModes) { mode in
            "\(mode.width)x\(mode.height)"
        }

        return grouped.values.compactMap { modes -> ResolutionGroup? in
            guard let first = modes.first else { return nil }

            // Deduplicate refresh rates that round to the same integer
            var seenRates: Set<Int> = []
            let uniqueModes = modes
                .sorted { $0.refreshRate > $1.refreshRate }
                .filter { mode in
                    let roundedRate = Int(mode.refreshRate.rounded())
                    if seenRates.contains(roundedRate) {
                        return false
                    }
                    seenRates.insert(roundedRate)
                    return true
                }

            return ResolutionGroup(
                width: first.width,
                height: first.height,
                isHiDPI: first.isHiDPI,
                refreshRates: uniqueModes
            )
        }
        .sorted { lhs, rhs in
            // Sort from lowest to highest resolution
            if lhs.width != rhs.width {
                return lhs.width < rhs.width
            }
            return lhs.height < rhs.height
        }
    }

    /// Check if display has HiDPI modes available
    var hasHiDPIModes: Bool {
        availableModes.contains { $0.isHiDPI }
    }

    /// Check if display has non-HiDPI modes available
    var hasNonHiDPIModes: Bool {
        availableModes.contains { !$0.isHiDPI }
    }

    /// Get modes sorted by resolution (largest first)
    var sortedModes: [DisplayMode] {
        availableModes.sorted { lhs, rhs in
            if lhs.width != rhs.width {
                return lhs.width > rhs.width
            }
            if lhs.height != rhs.height {
                return lhs.height > rhs.height
            }
            if lhs.refreshRate != rhs.refreshRate {
                return lhs.refreshRate > rhs.refreshRate
            }
            return lhs.isHiDPI && !rhs.isHiDPI
        }
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Display, rhs: Display) -> Bool {
        lhs.id == rhs.id
    }
}

/// Groups modes with the same resolution but different refresh rates
struct ResolutionGroup: Identifiable {
    var id: String { "\(width)x\(height)x\(isHiDPI)" }
    let width: Int
    let height: Int
    let isHiDPI: Bool
    let refreshRates: [DisplayMode]

    var resolutionString: String {
        "\(width) × \(height)"
    }

    var hiDPILabel: String {
        isHiDPI ? " (HiDPI)" : ""
    }

    var fullLabel: String {
        "\(resolutionString)\(hiDPILabel)"
    }

    /// Highest available refresh rate
    var maxRefreshRate: Double {
        refreshRates.map(\.refreshRate).max() ?? 60.0
    }
}
