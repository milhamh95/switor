import Foundation
import ServiceManagement

/// Manages launch at login functionality using SMAppService
@MainActor
final class LoginItemManager: ObservableObject {
    static let shared = LoginItemManager()

    @Published private(set) var isEnabled: Bool = false
    @Published private(set) var lastError: LoginItemError?

    init() {
        refreshStatus()
    }

    // MARK: - Public API

    /// Enable launch at login
    func enable() {
        do {
            try SMAppService.mainApp.register()
            isEnabled = true
            lastError = nil
        } catch {
            lastError = .registrationFailed(error)
            isEnabled = false
        }
    }

    /// Disable launch at login
    func disable() {
        do {
            try SMAppService.mainApp.unregister()
            isEnabled = false
            lastError = nil
        } catch {
            lastError = .unregistrationFailed(error)
        }
    }

    /// Toggle launch at login
    func toggle() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }

    /// Refresh the current status
    func refreshStatus() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}

// MARK: - Login Item Errors

enum LoginItemError: LocalizedError {
    case registrationFailed(Error)
    case unregistrationFailed(Error)

    var errorDescription: String? {
        switch self {
        case .registrationFailed(let error):
            return "Failed to enable launch at login: \(error.localizedDescription)"
        case .unregistrationFailed(let error):
            return "Failed to disable launch at login: \(error.localizedDescription)"
        }
    }
}
