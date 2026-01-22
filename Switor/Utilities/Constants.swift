import Foundation

/// App-wide constants
enum Constants {
    /// App information
    enum App {
        static let name = "Switor"
        static let version = "1.0.0"
        static let bundleIdentifier = "com.switor.app"
    }

    /// Configuration
    enum Config {
        static let directoryName = "switor"
        static let fileName = "config.json"
        static let currentVersion = 1

        static var directoryURL: URL {
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".config")
                .appendingPathComponent(directoryName)
        }

        static var fileURL: URL {
            directoryURL.appendingPathComponent(fileName)
        }
    }

    /// UI
    enum UI {
        static let menuBarWindowWidth: CGFloat = 280
        static let settingsWindowWidth: CGFloat = 500
        static let settingsWindowHeight: CGFloat = 400
    }

    /// Common resolutions
    enum CommonResolutions {
        static let presets: [(name: String, width: Int, height: Int)] = [
            ("4K UHD", 3840, 2160),
            ("2K QHD", 2560, 1440),
            ("Full HD", 1920, 1080),
            ("HD+", 1600, 900),
            ("HD", 1280, 720),
            ("WXGA", 1366, 768)
        ]
    }

    /// Common refresh rates
    enum CommonRefreshRates {
        static let rates: [Double] = [30, 48, 50, 60, 75, 90, 120, 144, 165, 240]
    }
}
