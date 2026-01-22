import Foundation

/// Root configuration model for the app
struct AppConfiguration: Codable {
    var version: Int
    var preferences: Preferences
    var shortcuts: [ShortcutMapping]
    var presets: [DisplayPreset]

    init(
        version: Int = 1,
        preferences: Preferences = Preferences(),
        shortcuts: [ShortcutMapping] = [],
        presets: [DisplayPreset] = []
    ) {
        self.version = version
        self.preferences = preferences
        self.shortcuts = shortcuts
        self.presets = presets
    }

    /// Default configuration
    static var `default`: AppConfiguration {
        AppConfiguration()
    }
}

/// User preferences
struct Preferences: Codable {
    var launchAtLogin: Bool
    var showResolutionInMenuBar: Bool

    init(launchAtLogin: Bool = false, showResolutionInMenuBar: Bool = false) {
        self.launchAtLogin = launchAtLogin
        self.showResolutionInMenuBar = showResolutionInMenuBar
    }
}

/// Display preset for multi-display configurations
struct DisplayPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var configurations: [DisplayConfiguration]

    init(
        id: UUID = UUID(),
        name: String,
        configurations: [DisplayConfiguration] = []
    ) {
        self.id = id
        self.name = name
        self.configurations = configurations
    }
}

/// Configuration for a single display within a preset
struct DisplayConfiguration: Codable, Identifiable {
    var id: UUID { UUID() }
    var displayID: UInt32
    var width: Int
    var height: Int
    var refreshRate: Double

    init(displayID: UInt32, width: Int, height: Int, refreshRate: Double) {
        self.displayID = displayID
        self.width = width
        self.height = height
        self.refreshRate = refreshRate
    }

    var targetMode: TargetDisplayMode {
        TargetDisplayMode(width: width, height: height, refreshRate: refreshRate)
    }

    enum CodingKeys: String, CodingKey {
        case displayID, width, height, refreshRate
    }
}
