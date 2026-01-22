import Foundation
import Combine
import HotKey
import CoreGraphics
import AppKit

/// Manages global keyboard shortcut registration and handling
@MainActor
final class ShortcutManager: ObservableObject {
    static let shared = ShortcutManager(
        displayManager: DisplayManager.shared,
        configManager: ConfigurationManager.shared
    )

    @Published private(set) var registeredShortcuts: [UUID: HotKey] = [:]
    @Published private(set) var lastTriggeredShortcut: ShortcutMapping?

    private var configCancellable: AnyCancellable?
    private let displayManager: DisplayManager
    private let configManager: ConfigurationManager

    init(displayManager: DisplayManager, configManager: ConfigurationManager) {
        self.displayManager = displayManager
        self.configManager = configManager

        setupConfigObserver()
        registerShortcuts(from: configManager.configuration.shortcuts)
    }

    // MARK: - Public API

    /// Register all shortcuts from configuration
    func registerShortcuts(from mappings: [ShortcutMapping]) {
        // Unregister existing shortcuts
        unregisterAllShortcuts()

        // Register new shortcuts
        for mapping in mappings {
            registerShortcut(mapping)
        }
    }

    /// Register a single shortcut
    func registerShortcut(_ mapping: ShortcutMapping) {
        guard let key = Key(carbonKeyCode: mapping.keyCode) else {
            return
        }

        let modifiers = convertModifiers(mapping.modifiers)
        let hotKey = HotKey(key: key, modifiers: modifiers)

        hotKey.keyDownHandler = { [weak self] in
            Task { @MainActor in
                self?.handleShortcutTriggered(mapping)
            }
        }

        registeredShortcuts[mapping.id] = hotKey
    }

    /// Unregister a single shortcut
    func unregisterShortcut(withID id: UUID) {
        registeredShortcuts.removeValue(forKey: id)
    }

    /// Unregister all shortcuts
    func unregisterAllShortcuts() {
        registeredShortcuts.removeAll()
    }

    /// Refresh shortcuts from configuration
    func refreshShortcuts() {
        registerShortcuts(from: configManager.configuration.shortcuts)
    }

    // MARK: - Private Methods

    private func setupConfigObserver() {
        configCancellable = configManager.$configuration
            .dropFirst()
            .sink { [weak self] config in
                Task { @MainActor in
                    self?.registerShortcuts(from: config.shortcuts)
                }
            }
    }

    private func handleShortcutTriggered(_ mapping: ShortcutMapping) {
        lastTriggeredShortcut = mapping

        // Find the display
        guard let display = displayManager.displays.first(where: { $0.id == mapping.displayID }) else {
            // Try to find by name if ID changed
            guard let display = displayManager.displays.first(where: { $0.name == mapping.displayName }) else {
                return
            }
            applyShortcut(mapping, to: display)
            return
        }

        applyShortcut(mapping, to: display)
    }

    private func applyShortcut(_ mapping: ShortcutMapping, to display: Display) {
        // Find matching mode
        guard let mode = displayManager.findMode(matching: mapping.target, for: display) else {
            return
        }

        // Apply the mode
        _ = displayManager.setDisplayMode(mode, for: display)
    }

    private func convertModifiers(_ modifiers: KeyModifiers) -> NSEvent.ModifierFlags {
        modifiers.nsEventFlags
    }
}

// MARK: - Key Extension for Carbon Key Codes

extension Key {
    init?(carbonKeyCode: UInt32) {
        // Map carbon key codes to HotKey's Key enum
        switch Int(carbonKeyCode) {
        case 0: self = .a
        case 1: self = .s
        case 2: self = .d
        case 3: self = .f
        case 4: self = .h
        case 5: self = .g
        case 6: self = .z
        case 7: self = .x
        case 8: self = .c
        case 9: self = .v
        case 11: self = .b
        case 12: self = .q
        case 13: self = .w
        case 14: self = .e
        case 15: self = .r
        case 16: self = .y
        case 17: self = .t
        case 18: self = .one
        case 19: self = .two
        case 20: self = .three
        case 21: self = .four
        case 22: self = .six
        case 23: self = .five
        case 25: self = .nine
        case 26: self = .seven
        case 28: self = .eight
        case 29: self = .zero
        case 31: self = .o
        case 32: self = .u
        case 34: self = .i
        case 35: self = .p
        case 37: self = .l
        case 38: self = .j
        case 40: self = .k
        case 45: self = .n
        case 46: self = .m
        case 49: self = .space
        case 36: self = .return
        case 48: self = .tab
        case 51: self = .delete
        case 53: self = .escape
        case 122: self = .f1
        case 120: self = .f2
        case 99: self = .f3
        case 118: self = .f4
        case 96: self = .f5
        case 97: self = .f6
        case 98: self = .f7
        case 100: self = .f8
        case 101: self = .f9
        case 109: self = .f10
        case 103: self = .f11
        case 111: self = .f12
        case 123: self = .leftArrow
        case 124: self = .rightArrow
        case 125: self = .downArrow
        case 126: self = .upArrow
        // Special characters
        case 24: self = .equal
        case 27: self = .minus
        case 33: self = .leftBracket
        case 30: self = .rightBracket
        case 42: self = .backslash
        case 41: self = .semicolon
        case 39: self = .quote
        case 43: self = .comma
        case 47: self = .period
        case 44: self = .slash
        case 50: self = .grave
        default: return nil
        }
    }

    var carbonKeyCode: UInt32 {
        switch self {
        case .a: return 0
        case .s: return 1
        case .d: return 2
        case .f: return 3
        case .h: return 4
        case .g: return 5
        case .z: return 6
        case .x: return 7
        case .c: return 8
        case .v: return 9
        case .b: return 11
        case .q: return 12
        case .w: return 13
        case .e: return 14
        case .r: return 15
        case .y: return 16
        case .t: return 17
        case .one: return 18
        case .two: return 19
        case .three: return 20
        case .four: return 21
        case .six: return 22
        case .five: return 23
        case .nine: return 25
        case .seven: return 26
        case .eight: return 28
        case .zero: return 29
        case .o: return 31
        case .u: return 32
        case .i: return 34
        case .p: return 35
        case .l: return 37
        case .j: return 38
        case .k: return 40
        case .n: return 45
        case .m: return 46
        case .space: return 49
        case .return: return 36
        case .tab: return 48
        case .delete: return 51
        case .escape: return 53
        case .f1: return 122
        case .f2: return 120
        case .f3: return 99
        case .f4: return 118
        case .f5: return 96
        case .f6: return 97
        case .f7: return 98
        case .f8: return 100
        case .f9: return 101
        case .f10: return 109
        case .f11: return 103
        case .f12: return 111
        case .leftArrow: return 123
        case .rightArrow: return 124
        case .downArrow: return 125
        case .upArrow: return 126
        // Special characters
        case .equal: return 24
        case .minus: return 27
        case .leftBracket: return 33
        case .rightBracket: return 30
        case .backslash: return 42
        case .semicolon: return 41
        case .quote: return 39
        case .comma: return 43
        case .period: return 47
        case .slash: return 44
        case .grave: return 50
        default: return 0
        }
    }
}
