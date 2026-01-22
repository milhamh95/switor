import SwiftUI
import AppKit

/// Settings window with tabs for General, Shortcuts, and About
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @EnvironmentObject var configManager: ConfigurationManager
    @State private var launchAtLogin = false
    @State private var showResolutionInMenuBar = true

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        var prefs = configManager.configuration.preferences
                        prefs.launchAtLogin = newValue
                        configManager.updatePreferences(prefs)

                        if newValue {
                            LoginItemManager.shared.enable()
                        } else {
                            LoginItemManager.shared.disable()
                        }
                    }

                Toggle("Show Resolution in Menu Bar", isOn: $showResolutionInMenuBar)
                    .onChange(of: showResolutionInMenuBar) { newValue in
                        var prefs = configManager.configuration.preferences
                        prefs.showResolutionInMenuBar = newValue
                        configManager.updatePreferences(prefs)
                    }
            } header: {
                Text("Appearance")
            }

            Section {
                HStack {
                    Text("Configuration file")
                    Spacer()
                    Text("~/.config/switor/config.json")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Button("Open Config Folder") {
                    let url = FileManager.default.homeDirectoryForCurrentUser
                        .appendingPathComponent(".config")
                        .appendingPathComponent("switor")
                    NSWorkspace.shared.open(url)
                }

                Button("Reset to Defaults", role: .destructive) {
                    configManager.resetToDefaults()
                    loadPreferences()
                }
            } header: {
                Text("Configuration")
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            loadPreferences()
        }
    }

    private func loadPreferences() {
        launchAtLogin = configManager.configuration.preferences.launchAtLogin
        showResolutionInMenuBar = configManager.configuration.preferences.showResolutionInMenuBar
    }
}

// MARK: - Shortcuts Settings

struct ShortcutsSettingsView: View {
    @EnvironmentObject var configManager: ConfigurationManager
    @EnvironmentObject var displayManager: DisplayManager
    @EnvironmentObject var shortcutManager: ShortcutManager

    @State private var showingAddSheet = false
    @State private var editingShortcut: ShortcutMapping?
    @State private var selectedShortcutID: UUID?

    private var selectedShortcut: ShortcutMapping? {
        configManager.configuration.shortcuts.first { $0.id == selectedShortcutID }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Shortcuts list
            List(selection: $selectedShortcutID) {
                if configManager.configuration.shortcuts.isEmpty {
                    Text("No shortcuts configured")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(configManager.configuration.shortcuts) { shortcut in
                        ShortcutRow(shortcut: shortcut)
                            .tag(shortcut.id)
                            .contextMenu {
                                Button("Edit") {
                                    editingShortcut = shortcut
                                }
                                Button("Delete", role: .destructive) {
                                    configManager.removeShortcut(shortcut)
                                }
                            }
                    }
                    .onDelete(perform: deleteShortcuts)
                }
            }

            Divider()

            // Bottom toolbar
            HStack {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }

                Button {
                    if let selected = selectedShortcut {
                        configManager.removeShortcut(selected)
                        selectedShortcutID = nil
                    }
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(selectedShortcutID == nil)

                Spacer()
            }
            .padding(8)
        }
        .sheet(isPresented: $showingAddSheet) {
            ShortcutEditorSheet(shortcut: nil)
        }
        .sheet(item: $editingShortcut) { shortcut in
            ShortcutEditorSheet(shortcut: shortcut)
        }
    }

    private func deleteShortcuts(at offsets: IndexSet) {
        for index in offsets {
            let shortcut = configManager.configuration.shortcuts[index]
            configManager.removeShortcut(shortcut)
        }
    }
}

struct ShortcutRow: View {
    let shortcut: ShortcutMapping

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(shortcut.description)
                    .font(.headline)
                Text(shortcut.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(shortcut.shortcutString)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)

                Text("\(shortcut.target.width)×\(shortcut.target.height) @ \(Int(shortcut.target.refreshRate))Hz\(shortcut.target.isHiDPI ? " (HiDPI)" : "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Shortcut Editor Sheet

struct ShortcutEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var configManager: ConfigurationManager
    @EnvironmentObject var displayManager: DisplayManager

    let shortcut: ShortcutMapping?

    @State private var description = ""
    @State private var selectedDisplayID: CGDirectDisplayID = 0
    @State private var selectedMode: DisplayMode?
    @State private var keyCode: UInt32 = 0
    @State private var modifiers = KeyModifiers()

    private var isEditing: Bool { shortcut != nil }

    private var selectedDisplay: Display? {
        displayManager.displays.first { $0.id == selectedDisplayID }
    }

    private var canSave: Bool {
        !description.isEmpty &&
        selectedDisplayID != 0 &&
        selectedMode != nil &&
        keyCode != 0 &&
        modifiers.hasModifiers
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isEditing ? "Edit Shortcut" : "Add Shortcut")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            // Form
            Form {
                Section {
                    TextField("Description", text: $description, prompt: Text("e.g., Switch to 1080p"))
                }

                Section {
                    Picker("Display", selection: $selectedDisplayID) {
                        Text("Select a display").tag(CGDirectDisplayID(0))
                        ForEach(displayManager.displays) { display in
                            Text(display.displayTitle).tag(display.id)
                        }
                    }

                    if let display = selectedDisplay {
                        Picker("Resolution", selection: $selectedMode) {
                            Text("Select a mode").tag(Optional<DisplayMode>.none)
                            ForEach(display.sortedModes) { mode in
                                Text(mode.fullDescription).tag(Optional(mode))
                            }
                        }
                    }
                }

                Section {
                    ShortcutRecorderView(keyCode: $keyCode, modifiers: $modifiers)
                } header: {
                    Text("Keyboard Shortcut")
                }
            }
            .formStyle(.grouped)

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("Save") {
                    saveShortcut()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
            .padding()
        }
        .frame(width: 400, height: 350)
        .onAppear {
            loadExisting()
        }
    }

    private func loadExisting() {
        guard let shortcut = shortcut else {
            // Set first display as default
            if let firstDisplay = displayManager.displays.first {
                selectedDisplayID = firstDisplay.id
            }
            return
        }

        description = shortcut.description
        selectedDisplayID = shortcut.displayID
        keyCode = shortcut.keyCode
        modifiers = shortcut.modifiers

        // Find matching mode
        if let display = displayManager.displays.first(where: { $0.id == shortcut.displayID }) {
            selectedMode = display.availableModes.first { mode in
                shortcut.target.matches(mode)
            }
        }
    }

    private func saveShortcut() {
        guard let display = selectedDisplay,
              let mode = selectedMode else { return }

        let mapping = ShortcutMapping(
            id: shortcut?.id ?? UUID(),
            displayID: display.id,
            displayName: display.name,
            keyCode: keyCode,
            modifiers: modifiers,
            target: TargetDisplayMode(from: mode),
            description: description
        )

        if isEditing {
            configManager.updateShortcut(mapping)
        } else {
            configManager.addShortcut(mapping)
        }
    }
}

// MARK: - About Settings

struct AboutSettingsView: View {
    private var currentYear: String {
        String(Calendar.current.component(.year, from: Date()))
    }

    var body: some View {
        VStack(spacing: 20) {
            // App icon from bundle
            if let appIcon = NSImage(named: "AppIcon") {
                Image(nsImage: appIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
            } else {
                Image(systemName: "display")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
            }

            Text("Switor")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Display Resolution Manager")
                .font(.title3)
                .foregroundColor(.secondary)

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()
                .frame(width: 200)

            VStack(spacing: 8) {
                Text("A macOS menu bar app for quickly")
                Text("changing display resolution and refresh rate.")
            }
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)

            Spacer()

            Text("© \(currentYear)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
