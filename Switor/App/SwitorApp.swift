import SwiftUI
import AppKit

@main
struct SwitorApp: App {
    @StateObject private var displayManager = DisplayManager.shared
    @StateObject private var configManager = ConfigurationManager.shared
    @StateObject private var shortcutManager = ShortcutManager.shared

    var body: some Scene {
        // Menu Bar Extra
        MenuBarExtra {
            MenuBarView()
                .environmentObject(displayManager)
                .environmentObject(configManager)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)

        // Settings Window
        Window("Switor Settings", id: "settings") {
            SettingsView()
                .environmentObject(displayManager)
                .environmentObject(configManager)
                .environmentObject(shortcutManager)
        }
        .windowResizability(.contentSize)
    }

    @ViewBuilder
    private var menuBarLabel: some View {
        HStack(spacing: 4) {
            menuBarIcon
            if let mainDisplay = displayManager.displays.first(where: { $0.isMain }),
               let currentMode = mainDisplay.currentMode {
                Text(currentMode.shortDescription)
            }
        }
    }

    @ViewBuilder
    private var menuBarIcon: some View {
        if let iconURL = Bundle.main.url(forResource: "MenuBarIcon", withExtension: "png"),
           let nsImage = NSImage(contentsOf: iconURL) {
            // Mark as template so it adapts to light/dark mode
            Image(nsImage: {
                nsImage.isTemplate = true
                return nsImage
            }())
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 18)
        } else {
            Image(systemName: "display")
        }
    }
}
