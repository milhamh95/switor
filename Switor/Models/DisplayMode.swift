import Foundation
import CoreGraphics

/// Represents a display resolution and refresh rate configuration
struct DisplayMode: Identifiable, Hashable, Codable {
    let id: UUID
    let width: Int
    let height: Int
    let refreshRate: Double
    let isHiDPI: Bool
    let ioDisplayModeID: Int32

    /// The native CGDisplayMode reference (not stored/encoded)
    var cgMode: CGDisplayMode?

    init(
        id: UUID = UUID(),
        width: Int,
        height: Int,
        refreshRate: Double,
        isHiDPI: Bool = false,
        ioDisplayModeID: Int32 = 0,
        cgMode: CGDisplayMode? = nil
    ) {
        self.id = id
        self.width = width
        self.height = height
        self.refreshRate = refreshRate
        self.isHiDPI = isHiDPI
        self.ioDisplayModeID = ioDisplayModeID
        self.cgMode = cgMode
    }

    /// Initialize from a CGDisplayMode
    init?(from cgMode: CGDisplayMode) {
        self.id = UUID()
        self.width = cgMode.width
        self.height = cgMode.height
        self.refreshRate = cgMode.refreshRate
        self.isHiDPI = cgMode.pixelWidth > cgMode.width
        self.ioDisplayModeID = cgMode.ioDisplayModeID
        self.cgMode = cgMode
    }

    /// Human-readable resolution string (e.g., "1920 × 1080")
    var resolutionString: String {
        "\(width) × \(height)"
    }

    /// Human-readable refresh rate string (e.g., "60 Hz")
    var refreshRateString: String {
        if refreshRate > 0 {
            return String(format: "%.0f Hz", refreshRate)
        }
        return "Default"
    }

    /// Full description including HiDPI status
    var fullDescription: String {
        let hiDPISuffix = isHiDPI ? " (HiDPI)" : ""
        return "\(resolutionString) @ \(refreshRateString)\(hiDPISuffix)"
    }

    /// Short description for menu bar display
    var shortDescription: String {
        "\(width)×\(height)"
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, width, height, refreshRate, isHiDPI, ioDisplayModeID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        width = try container.decode(Int.self, forKey: .width)
        height = try container.decode(Int.self, forKey: .height)
        refreshRate = try container.decode(Double.self, forKey: .refreshRate)
        isHiDPI = try container.decodeIfPresent(Bool.self, forKey: .isHiDPI) ?? false
        ioDisplayModeID = try container.decodeIfPresent(Int32.self, forKey: .ioDisplayModeID) ?? 0
        cgMode = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(refreshRate, forKey: .refreshRate)
        try container.encode(isHiDPI, forKey: .isHiDPI)
        try container.encode(ioDisplayModeID, forKey: .ioDisplayModeID)
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
        hasher.combine(refreshRate)
        hasher.combine(isHiDPI)
    }

    static func == (lhs: DisplayMode, rhs: DisplayMode) -> Bool {
        lhs.width == rhs.width &&
        lhs.height == rhs.height &&
        lhs.refreshRate == rhs.refreshRate &&
        lhs.isHiDPI == rhs.isHiDPI
    }
}

// MARK: - Simplified Target Mode for Shortcuts

/// A simplified mode specification for shortcut targets (doesn't require cgMode)
struct TargetDisplayMode: Codable, Hashable {
    let width: Int
    let height: Int
    let refreshRate: Double
    let isHiDPI: Bool

    init(width: Int, height: Int, refreshRate: Double, isHiDPI: Bool = false) {
        self.width = width
        self.height = height
        self.refreshRate = refreshRate
        self.isHiDPI = isHiDPI
    }

    init(from mode: DisplayMode) {
        self.width = mode.width
        self.height = mode.height
        self.refreshRate = mode.refreshRate
        self.isHiDPI = mode.isHiDPI
    }

    /// Check if this target matches a DisplayMode
    func matches(_ mode: DisplayMode) -> Bool {
        mode.width == width &&
        mode.height == height &&
        mode.isHiDPI == isHiDPI &&
        (refreshRate == 0 || abs(mode.refreshRate - refreshRate) < 1.0)
    }
}
