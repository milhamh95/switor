import SwiftUI
import AppKit

/// Main popup content for the menu bar extra
struct MenuBarView: View {
    @EnvironmentObject var displayManager: DisplayManager
    @EnvironmentObject var configManager: ConfigurationManager
    @Environment(\.openWindow) private var openWindow

    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Switor")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    displayManager.refreshDisplays()
                } label: {
                    HStack(spacing: 4) {
                        Text("Re-scan")
                        Image(systemName: "arrow.clockwise")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Display sections
            if displayManager.displays.isEmpty {
                Text("No displays found")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(displayManager.displays) { display in
                    DisplaySectionView(display: display, onModeSelected: handleModeChange)

                    if display.id != displayManager.displays.last?.id {
                        Divider()
                    }
                }
            }

            // Error message
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            Divider()

            // Bottom actions
            HStack {
                Button {
                    openSettingsWindow()
                } label: {
                    Text("Settings")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(width: 320)
        .onAppear {
            NSCursor.arrow.set()
        }
        .onHover { hovering in
            if hovering {
                NSCursor.arrow.set()
            }
        }
    }

    private func handleModeChange(_ mode: DisplayMode, _ display: Display) {
        let result = displayManager.setDisplayMode(mode, for: display)
        switch result {
        case .success:
            errorMessage = nil
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func openSettingsWindow() {
        // Close the menu bar popup first
        if let window = NSApp.keyWindow {
            window.close()
        }

        // Activate the app
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }

        // Open settings window
        openWindow(id: "settings")
    }
}

/// Section for a single display showing current mode and resolution options
struct DisplaySectionView: View {
    let display: Display
    let onModeSelected: (DisplayMode, Display) -> Void

    @State private var showAllModes = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Display header
            HStack {
                Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                    .foregroundColor(.secondary)
                Text(display.displayTitle)
                    .font(.headline)
                    .fontWeight(.medium)
            }

            // Current resolution
            if let currentMode = display.currentMode {
                HStack {
                    Text("Current:")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Text(currentMode.fullDescription)
                        .font(.body)
                        .fontWeight(.medium)
                }
            }

            // Resolution options
            if showAllModes {
                ResolutionListView(
                    display: display,
                    onModeSelected: onModeSelected
                )
            } else {
                ResolutionSliderView(
                    display: display,
                    onModeSelected: onModeSelected
                )
            }

            // Toggle view mode
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showAllModes.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: showAllModes ? "slider.horizontal.3" : "list.bullet")
                    Text(showAllModes ? "Show Slider" : "Show All Modes")
                }
                .font(.body)
            }
            .buttonStyle(.borderless)
            .foregroundColor(.accentColor)
        }
    }
}
