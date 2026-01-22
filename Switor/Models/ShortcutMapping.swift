import Foundation
import Carbon.HIToolbox
import AppKit

/// Represents a keyboard shortcut mapping to a display mode
struct ShortcutMapping: Identifiable, Codable, Hashable {
    let id: UUID
    var displayID: UInt32
    var displayName: String
    var keyCode: UInt32
    var modifiers: KeyModifiers
    var target: TargetDisplayMode
    var description: String

    init(
        id: UUID = UUID(),
        displayID: UInt32,
        displayName: String,
        keyCode: UInt32,
        modifiers: KeyModifiers,
        target: TargetDisplayMode,
        description: String
    ) {
        self.id = id
        self.displayID = displayID
        self.displayName = displayName
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.target = target
        self.description = description
    }

    /// Human-readable shortcut string (e.g., "⌘⌥R")
    var shortcutString: String {
        var parts: [String] = []

        if modifiers.control {
            parts.append("⌃")
        }
        if modifiers.option {
            parts.append("⌥")
        }
        if modifiers.shift {
            parts.append("⇧")
        }
        if modifiers.command {
            parts.append("⌘")
        }

        if let keyName = KeyCodeMap.keyName(for: keyCode) {
            parts.append(keyName)
        }

        return parts.joined()
    }
}

/// Modifier keys for a shortcut
struct KeyModifiers: Codable, Hashable {
    var command: Bool
    var option: Bool
    var control: Bool
    var shift: Bool

    init(command: Bool = false, option: Bool = false, control: Bool = false, shift: Bool = false) {
        self.command = command
        self.option = option
        self.control = control
        self.shift = shift
    }

    /// Convert to NSEvent modifier flags
    var nsEventFlags: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if command { flags.insert(.command) }
        if option { flags.insert(.option) }
        if control { flags.insert(.control) }
        if shift { flags.insert(.shift) }
        return flags
    }

    /// Create from NSEvent modifier flags
    static func from(_ flags: NSEvent.ModifierFlags) -> KeyModifiers {
        KeyModifiers(
            command: flags.contains(.command),
            option: flags.contains(.option),
            control: flags.contains(.control),
            shift: flags.contains(.shift)
        )
    }

    /// Check if any modifier is set
    var hasModifiers: Bool {
        command || option || control || shift
    }
}

/// Map key codes to human-readable names
enum KeyCodeMap {
    private static let keyNames: [UInt32: String] = [
        UInt32(kVK_ANSI_A): "A",
        UInt32(kVK_ANSI_B): "B",
        UInt32(kVK_ANSI_C): "C",
        UInt32(kVK_ANSI_D): "D",
        UInt32(kVK_ANSI_E): "E",
        UInt32(kVK_ANSI_F): "F",
        UInt32(kVK_ANSI_G): "G",
        UInt32(kVK_ANSI_H): "H",
        UInt32(kVK_ANSI_I): "I",
        UInt32(kVK_ANSI_J): "J",
        UInt32(kVK_ANSI_K): "K",
        UInt32(kVK_ANSI_L): "L",
        UInt32(kVK_ANSI_M): "M",
        UInt32(kVK_ANSI_N): "N",
        UInt32(kVK_ANSI_O): "O",
        UInt32(kVK_ANSI_P): "P",
        UInt32(kVK_ANSI_Q): "Q",
        UInt32(kVK_ANSI_R): "R",
        UInt32(kVK_ANSI_S): "S",
        UInt32(kVK_ANSI_T): "T",
        UInt32(kVK_ANSI_U): "U",
        UInt32(kVK_ANSI_V): "V",
        UInt32(kVK_ANSI_W): "W",
        UInt32(kVK_ANSI_X): "X",
        UInt32(kVK_ANSI_Y): "Y",
        UInt32(kVK_ANSI_Z): "Z",
        UInt32(kVK_ANSI_0): "0",
        UInt32(kVK_ANSI_1): "1",
        UInt32(kVK_ANSI_2): "2",
        UInt32(kVK_ANSI_3): "3",
        UInt32(kVK_ANSI_4): "4",
        UInt32(kVK_ANSI_5): "5",
        UInt32(kVK_ANSI_6): "6",
        UInt32(kVK_ANSI_7): "7",
        UInt32(kVK_ANSI_8): "8",
        UInt32(kVK_ANSI_9): "9",
        UInt32(kVK_F1): "F1",
        UInt32(kVK_F2): "F2",
        UInt32(kVK_F3): "F3",
        UInt32(kVK_F4): "F4",
        UInt32(kVK_F5): "F5",
        UInt32(kVK_F6): "F6",
        UInt32(kVK_F7): "F7",
        UInt32(kVK_F8): "F8",
        UInt32(kVK_F9): "F9",
        UInt32(kVK_F10): "F10",
        UInt32(kVK_F11): "F11",
        UInt32(kVK_F12): "F12",
        UInt32(kVK_Space): "Space",
        UInt32(kVK_Return): "Return",
        UInt32(kVK_Tab): "Tab",
        UInt32(kVK_Delete): "Delete",
        UInt32(kVK_Escape): "Esc",
        UInt32(kVK_LeftArrow): "←",
        UInt32(kVK_RightArrow): "→",
        UInt32(kVK_UpArrow): "↑",
        UInt32(kVK_DownArrow): "↓",
        // Special characters
        UInt32(kVK_ANSI_Equal): "=",
        UInt32(kVK_ANSI_Minus): "-",
        UInt32(kVK_ANSI_LeftBracket): "[",
        UInt32(kVK_ANSI_RightBracket): "]",
        UInt32(kVK_ANSI_Backslash): "\\",
        UInt32(kVK_ANSI_Semicolon): ";",
        UInt32(kVK_ANSI_Quote): "'",
        UInt32(kVK_ANSI_Comma): ",",
        UInt32(kVK_ANSI_Period): ".",
        UInt32(kVK_ANSI_Slash): "/",
        UInt32(kVK_ANSI_Grave): "`"
    ]

    static func keyName(for keyCode: UInt32) -> String? {
        keyNames[keyCode]
    }

    static func keyCode(for name: String) -> UInt32? {
        keyNames.first { $0.value == name }?.key
    }
}
