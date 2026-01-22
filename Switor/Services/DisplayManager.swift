import Foundation
import CoreGraphics
import Combine
import IOKit

/// Manages display enumeration and resolution changes using CoreGraphics
@MainActor
final class DisplayManager: ObservableObject {
    static let shared = DisplayManager()

    @Published private(set) var displays: [Display] = []
    @Published private(set) var lastError: DisplayError?

    private var displayReconfigurationCallback: DisplayReconfigurationCallback?

    init() {
        refreshDisplays()
        registerForDisplayChanges()
    }

    deinit {
        unregisterDisplayChanges()
    }

    // MARK: - Public API

    /// Refresh the list of connected displays
    func refreshDisplays() {
        displays = getOnlineDisplays()
    }

    /// Change the resolution of a display
    func setDisplayMode(_ mode: DisplayMode, for display: Display) -> Result<Void, DisplayError> {
        guard let cgMode = mode.cgMode else {
            return .failure(.invalidMode)
        }

        var config: CGDisplayConfigRef?
        let beginResult = CGBeginDisplayConfiguration(&config)

        guard beginResult == .success, let config = config else {
            return .failure(.configurationFailed(beginResult))
        }

        let configureResult = CGConfigureDisplayWithDisplayMode(config, display.id, cgMode, nil)

        guard configureResult == .success else {
            CGCancelDisplayConfiguration(config)
            return .failure(.configurationFailed(configureResult))
        }

        let completeResult = CGCompleteDisplayConfiguration(config, .permanently)

        guard completeResult == .success else {
            return .failure(.configurationFailed(completeResult))
        }

        // Refresh displays after successful change
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refreshDisplays()
        }

        return .success(())
    }

    /// Find a display mode matching the target specification
    func findMode(matching target: TargetDisplayMode, for display: Display) -> DisplayMode? {
        display.availableModes.first { target.matches($0) }
    }

    /// Get the current mode for a specific display
    func getCurrentMode(for displayID: CGDirectDisplayID) -> DisplayMode? {
        guard let cgMode = CGDisplayCopyDisplayMode(displayID) else {
            return nil
        }
        return DisplayMode(from: cgMode)
    }

    // MARK: - Private Methods

    /// Get list of online displays
    private func getOnlineDisplays() -> [Display] {
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: 16)
        var displayCount: UInt32 = 0

        let result = CGGetOnlineDisplayList(16, &displayIDs, &displayCount)

        guard result == .success else {
            lastError = .enumerationFailed(result)
            return []
        }

        return (0..<Int(displayCount)).compactMap { index in
            createDisplay(from: displayIDs[index])
        }
    }

    /// Create a Display model from a display ID
    private func createDisplay(from displayID: CGDirectDisplayID) -> Display? {
        let name = getDisplayName(for: displayID)
        let isBuiltIn = CGDisplayIsBuiltin(displayID) != 0
        let isMain = CGDisplayIsMain(displayID) != 0
        let currentMode = getCurrentMode(for: displayID)
        let availableModes = getAvailableModes(for: displayID)

        return Display(
            id: displayID,
            name: name,
            isBuiltIn: isBuiltIn,
            isMain: isMain,
            currentMode: currentMode,
            availableModes: availableModes
        )
    }

    /// Get display name from IOKit
    private func getDisplayName(for displayID: CGDirectDisplayID) -> String {
        // For built-in displays
        if CGDisplayIsBuiltin(displayID) != 0 {
            return "Built-in Display"
        }

        let cgVendor = CGDisplayVendorNumber(displayID)
        let cgProduct = CGDisplayModelNumber(displayID)

        // Try to get name from IOKit using DisplayServices
        var iterator: io_iterator_t = 0
        let matchingDict = IOServiceMatching("IODisplayConnect")

        if IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator) == KERN_SUCCESS {
            defer { IOObjectRelease(iterator) }

            var service = IOIteratorNext(iterator)
            while service != 0 {
                defer {
                    IOObjectRelease(service)
                    service = IOIteratorNext(iterator)
                }

                guard let info = IODisplayCreateInfoDictionary(service, IOOptionBits(kIODisplayOnlyPreferredName)).takeRetainedValue() as? [String: Any] else {
                    continue
                }

                if let vendorID = info[kDisplayVendorID] as? UInt32,
                   let productID = info[kDisplayProductID] as? UInt32 {

                    if vendorID == cgVendor && productID == cgProduct {
                        // Try to get the display product name
                        if let names = info[kDisplayProductName] as? [String: String],
                           let name = names.values.first, !name.isEmpty {
                            return name
                        }
                    }
                }
            }
        }

        // Fallback: Try to construct name from vendor ID
        let vendorName = getVendorName(vendorID: cgVendor)
        if let vendorName = vendorName {
            if cgProduct != 0 {
                return "\(vendorName) (\(cgProduct))"
            }
            return vendorName
        }

        // Last fallback - simple external display name
        return "External Display \(displayID)"
    }

    /// Get vendor name from vendor ID
    private func getVendorName(vendorID: UInt32) -> String? {
        // Common display vendor IDs (PNP IDs encoded as UInt32)
        // These are derived from EDID vendor codes
        let vendors: [UInt32: String] = [
            0x0610: "Apple",
            0x1E6D: "LG",
            0x10AC: "Dell",
            0x0469: "ASUS",
            0x0D0C: "Samsung",
            0x220E: "BenQ",
            0x5A63: "ViewSonic",
            0x0E11: "Compaq",
            0x1AB3: "Acer",
            0x38A3: "HP",
            0x4D10: "Philips",
            0x26CD: "Lenovo",
            0x4C2D: "Lenovo",
            0x34AC: "MSI",
            0x056D: "EIZO",
            0x3023: "Huawei",
            0x3604: "GIGABYTE",
            0x2E8C: "AOC",
        ]

        return vendors[vendorID]
    }

    /// Get all available display modes for a display
    private func getAvailableModes(for displayID: CGDirectDisplayID) -> [DisplayMode] {
        let options: [CFString: Any] = [
            kCGDisplayShowDuplicateLowResolutionModes: true
        ]

        guard let modesArray = CGDisplayCopyAllDisplayModes(displayID, options as CFDictionary) as? [CGDisplayMode] else {
            return []
        }

        return modesArray.compactMap { DisplayMode(from: $0) }
    }

    // MARK: - Display Change Notifications

    private func registerForDisplayChanges() {
        displayReconfigurationCallback = { displayID, flags, userInfo in
            guard let manager = userInfo?.assumingMemoryBound(to: DisplayManager.self).pointee else {
                return
            }

            Task { @MainActor in
                manager.refreshDisplays()
            }
        }

        var mutableSelf = self
        CGDisplayRegisterReconfigurationCallback(
            displayReconfigurationCallbackC,
            &mutableSelf
        )
    }

    nonisolated private func unregisterDisplayChanges() {
        // Note: This is safe because it only calls CoreGraphics C functions
        // which are thread-safe
        var mutableSelf = self
        CGDisplayRemoveReconfigurationCallback(
            displayReconfigurationCallbackC,
            &mutableSelf
        )
    }
}

// MARK: - C Callback

private typealias DisplayReconfigurationCallback = @convention(c) (
    CGDirectDisplayID,
    CGDisplayChangeSummaryFlags,
    UnsafeMutableRawPointer?
) -> Void

private let displayReconfigurationCallbackC: CGDisplayReconfigurationCallBack = { displayID, flags, userInfo in
    // Post notification for display changes
    DispatchQueue.main.async {
        NotificationCenter.default.post(
            name: .displayConfigurationDidChange,
            object: nil,
            userInfo: ["displayID": displayID, "flags": flags]
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let displayConfigurationDidChange = Notification.Name("displayConfigurationDidChange")
}

// MARK: - Display Errors

enum DisplayError: LocalizedError {
    case enumerationFailed(CGError)
    case configurationFailed(CGError)
    case invalidMode
    case displayNotFound

    var errorDescription: String? {
        switch self {
        case .enumerationFailed(let error):
            return "Failed to enumerate displays: \(error)"
        case .configurationFailed(let error):
            return "Failed to configure display: \(error)"
        case .invalidMode:
            return "Invalid display mode"
        case .displayNotFound:
            return "Display not found"
        }
    }
}
