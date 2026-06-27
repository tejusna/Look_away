import AppKit
import Combine

final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let settings: AppSettings
    private let reminderManager: ReminderManager
    private let launchAtLogin: LaunchAtLoginManager
    private let widgetWindowController: WidgetWindowController
    private var cancellables: Set<AnyCancellable> = []

    private var pauseResumeItem: NSMenuItem!
    private var intervalItems: [Int: NSMenuItem] = [:]
    private var launchAtLoginItem: NSMenuItem!

    init(settings: AppSettings, reminderManager: ReminderManager, launchAtLogin: LaunchAtLoginManager, widgetWindowController: WidgetWindowController) {
        self.settings = settings
        self.reminderManager = reminderManager
        self.launchAtLogin = launchAtLogin
        self.widgetWindowController = widgetWindowController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Look Away")
        }

        let menu = buildMenu()
        menu.delegate = self
        statusItem.menu = menu
        observeSettings()
    }

    func menuWillOpen(_ menu: NSMenu) {
        widgetWindowController.peek()
    }

    func menuDidClose(_ menu: NSMenu) {
        widgetWindowController.scheduleRetreat(after: 4.0)
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        pauseResumeItem = NSMenuItem(title: settings.isPaused ? "Resume" : "Pause", action: #selector(togglePause), keyEquivalent: "")
        pauseResumeItem.target = self
        menu.addItem(pauseResumeItem)

        let remindNow = NSMenuItem(title: "Remind Me Now", action: #selector(remindNow), keyEquivalent: "")
        remindNow.target = self
        menu.addItem(remindNow)

        menu.addItem(.separator())

        let intervalMenu = NSMenu()
        for interval in ReminderInterval.allCases {
            let item = NSMenuItem(title: interval.title, action: #selector(selectInterval(_:)), keyEquivalent: "")
            item.target = self
            item.tag = interval.rawValue
            item.state = (interval == settings.interval) ? .on : .off
            intervalItems[interval.rawValue] = item
            intervalMenu.addItem(item)
        }
        let intervalParent = NSMenuItem(title: "Reminder Interval", action: nil, keyEquivalent: "")
        intervalParent.submenu = intervalMenu
        menu.addItem(intervalParent)

        launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.target = self
        launchAtLoginItem.state = settings.launchAtLoginEnabled ? .on : .off
        menu.addItem(launchAtLoginItem)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Look Away", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        return menu
    }

    private func observeSettings() {
        settings.$isPaused
            .sink { [weak self] paused in self?.pauseResumeItem?.title = paused ? "Resume" : "Pause" }
            .store(in: &cancellables)

        settings.$interval
            .sink { [weak self] interval in
                guard let self else { return }
                for (rawValue, item) in self.intervalItems {
                    item.state = (rawValue == interval.rawValue) ? .on : .off
                }
            }
            .store(in: &cancellables)

        settings.$launchAtLoginEnabled
            .sink { [weak self] enabled in self?.launchAtLoginItem?.state = enabled ? .on : .off }
            .store(in: &cancellables)
    }

    @objc private func togglePause() {
        if settings.isPaused {
            reminderManager.resume()
        } else {
            reminderManager.pause()
        }
    }

    @objc private func remindNow() {
        reminderManager.remindNow()
    }

    @objc private func selectInterval(_ sender: NSMenuItem) {
        guard let interval = ReminderInterval(rawValue: sender.tag) else { return }
        settings.interval = interval
    }

    @objc private func toggleLaunchAtLogin() {
        launchAtLogin.setEnabled(!settings.launchAtLoginEnabled)
    }
}
