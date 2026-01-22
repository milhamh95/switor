import SwiftUI
import Carbon.HIToolbox
import AppKit

/// View for recording keyboard shortcuts with manual modifier selection
/// This approach works better with hyper key setups (Karabiner, etc.)
struct ShortcutRecorderView: View {
    @Binding var keyCode: UInt32
    @Binding var modifiers: KeyModifiers

    @State private var isRecording = false
    @State private var localMonitor: Any?

    private var keyDisplayText: String {
        if isRecording {
            return "Press a key..."
        }
        if keyCode == 0 {
            return "Click to record key"
        }
        return KeyCodeMap.keyName(for: keyCode) ?? "Key \(keyCode)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Modifier checkboxes
            HStack(spacing: 16) {
                Toggle("⌃ Control", isOn: $modifiers.control)
                    .toggleStyle(.checkbox)
                Toggle("⌥ Option", isOn: $modifiers.option)
                    .toggleStyle(.checkbox)
                Toggle("⇧ Shift", isOn: $modifiers.shift)
                    .toggleStyle(.checkbox)
                Toggle("⌘ Command", isOn: $modifiers.command)
                    .toggleStyle(.checkbox)
            }
            .font(.subheadline)

            // Key recorder
            HStack {
                Text("Key:")
                    .foregroundColor(.secondary)

                HStack {
                    Text(keyDisplayText)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(isRecording ? .accentColor : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if keyCode != 0 {
                        Button {
                            keyCode = 0
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isRecording ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isRecording ? Color.accentColor : Color.clear, lineWidth: 1)
                )
                .onTapGesture {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }
            }
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        isRecording = true

        // Only capture the key, not modifiers
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            // Handle escape to cancel
            if event.keyCode == UInt16(kVK_Escape) {
                stopRecording()
                return nil
            }

            // Record any key press (ignore modifiers for the key itself)
            keyCode = UInt32(event.keyCode)
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false

        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
}
