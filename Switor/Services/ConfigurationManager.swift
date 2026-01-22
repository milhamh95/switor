import Foundation
import Combine

/// Manages reading and writing the JSON configuration file
@MainActor
final class ConfigurationManager: ObservableObject {
    static let shared = ConfigurationManager()

    @Published private(set) var configuration: AppConfiguration
    @Published private(set) var lastError: ConfigurationError?

    private let configDirectoryURL: URL
    private let configFileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        // Setup paths
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        configDirectoryURL = homeDirectory
            .appendingPathComponent(".config")
            .appendingPathComponent("switor")
        configFileURL = configDirectoryURL.appendingPathComponent("config.json")

        // Setup encoder/decoder
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        decoder = JSONDecoder()

        // Load initial configuration
        configuration = AppConfiguration.default

        // Load from disk
        loadConfiguration()
    }

    // MARK: - Public API

    /// Load configuration from disk
    func loadConfiguration() {
        do {
            // Create directory if needed
            try ensureConfigDirectory()

            // Check if file exists
            guard FileManager.default.fileExists(atPath: configFileURL.path) else {
                // No config file yet, use defaults
                configuration = AppConfiguration.default
                return
            }

            // Read and decode
            let data = try Data(contentsOf: configFileURL)
            var loadedConfig = try decoder.decode(AppConfiguration.self, from: data)

            // Handle migrations if needed
            loadedConfig = migrateIfNeeded(loadedConfig)

            configuration = loadedConfig
            lastError = nil
        } catch {
            lastError = .loadFailed(error)
            configuration = AppConfiguration.default
        }
    }

    /// Save configuration to disk
    func saveConfiguration() {
        do {
            try ensureConfigDirectory()

            let data = try encoder.encode(configuration)
            try data.write(to: configFileURL, options: .atomic)

            lastError = nil
        } catch {
            lastError = .saveFailed(error)
        }
    }

    /// Update preferences and save
    func updatePreferences(_ preferences: Preferences) {
        configuration.preferences = preferences
        saveConfiguration()
    }

    /// Add a new shortcut mapping
    func addShortcut(_ shortcut: ShortcutMapping) {
        configuration.shortcuts.append(shortcut)
        saveConfiguration()
    }

    /// Update an existing shortcut
    func updateShortcut(_ shortcut: ShortcutMapping) {
        if let index = configuration.shortcuts.firstIndex(where: { $0.id == shortcut.id }) {
            configuration.shortcuts[index] = shortcut
            saveConfiguration()
        }
    }

    /// Remove a shortcut
    func removeShortcut(_ shortcut: ShortcutMapping) {
        configuration.shortcuts.removeAll { $0.id == shortcut.id }
        saveConfiguration()
    }

    /// Remove shortcut by ID
    func removeShortcut(withID id: UUID) {
        configuration.shortcuts.removeAll { $0.id == id }
        saveConfiguration()
    }

    /// Add a new preset
    func addPreset(_ preset: DisplayPreset) {
        configuration.presets.append(preset)
        saveConfiguration()
    }

    /// Update an existing preset
    func updatePreset(_ preset: DisplayPreset) {
        if let index = configuration.presets.firstIndex(where: { $0.id == preset.id }) {
            configuration.presets[index] = preset
            saveConfiguration()
        }
    }

    /// Remove a preset
    func removePreset(_ preset: DisplayPreset) {
        configuration.presets.removeAll { $0.id == preset.id }
        saveConfiguration()
    }

    /// Reset to default configuration
    func resetToDefaults() {
        configuration = AppConfiguration.default
        saveConfiguration()
    }

    // MARK: - Private Methods

    private func ensureConfigDirectory() throws {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: configDirectoryURL.path) {
            try fileManager.createDirectory(
                at: configDirectoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }

    private func migrateIfNeeded(_ config: AppConfiguration) -> AppConfiguration {
        // Version 1 is current, no migrations needed yet
        // Future migrations would go here:
        // var migratedConfig = config
        // if config.version < 2 {
        //     migratedConfig = migrateToV2(migratedConfig)
        // }
        // return migratedConfig

        return config
    }
}

// MARK: - Configuration Errors

enum ConfigurationError: LocalizedError {
    case loadFailed(Error)
    case saveFailed(Error)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .loadFailed(let error):
            return "Failed to load configuration: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save configuration: \(error.localizedDescription)"
        case .invalidData:
            return "Invalid configuration data"
        }
    }
}
