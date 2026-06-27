import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var settings: AppSettings!
    private var reminderManager: ReminderManager!
    private var launchAtLoginManager: LaunchAtLoginManager!
    private var statusBarController: StatusBarController!
    private var widgetWindowController: WidgetWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let settings = AppSettings()
        self.settings = settings

        let reminderManager = ReminderManager(settings: settings)
        self.reminderManager = reminderManager

        let widgetWindowController = WidgetWindowController(settings: settings)
        self.widgetWindowController = widgetWindowController

        reminderManager.onRemind = { [weak widgetWindowController, weak reminderManager] message in
            widgetWindowController?.announceReminder(message: message) {
                reminderManager?.dismiss()
            }
        }

        let launchAtLoginManager = LaunchAtLoginManager(settings: settings)
        self.launchAtLoginManager = launchAtLoginManager

        statusBarController = StatusBarController(
            settings: settings,
            reminderManager: reminderManager,
            launchAtLogin: launchAtLoginManager,
            widgetWindowController: widgetWindowController
        )

        launchAtLoginManager.promptIfNeeded()

        widgetWindowController.announceIntro(intervalMinutes: settings.interval.minutes) { [weak reminderManager] in
            reminderManager?.start()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
