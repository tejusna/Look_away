import AppKit
import ServiceManagement

/// Wraps SMAppService for "launch at login", plus the first-3-sessions opt-in prompt.
final class LaunchAtLoginManager {
    private let settings: AppSettings
    private let maxPrompts = 3

    init(settings: AppSettings) {
        self.settings = settings
        settings.launchAtLoginEnabled = (SMAppService.mainApp.status == .enabled)
    }

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
            settings.launchAtLoginEnabled = enabled
        } catch {
            settings.launchAtLoginEnabled = (SMAppService.mainApp.status == .enabled)
        }
    }

    /// Shows the opt-in alert on each of the first 3 launches, unless already enabled.
    func promptIfNeeded() {
        guard !isEnabled else { return }
        guard settings.launchPromptCount < maxPrompts else { return }
        settings.launchPromptCount += 1

        let alert = NSAlert()
        alert.messageText = "Launch Look Away at login?"
        alert.informativeText = "Look Away can start automatically when you log in, so your eye-rest reminders are always running."
        alert.addButton(withTitle: "Enable")
        alert.addButton(withTitle: "Not Now")
        alert.alertStyle = .informational

        if alert.runModal() == .alertFirstButtonReturn {
            setEnabled(true)
        }
    }
}
