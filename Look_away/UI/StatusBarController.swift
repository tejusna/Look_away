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
    private var soundEnabledItem: NSMenuItem!
    private var petItems: [WidgetPet: NSMenuItem] = [:]
    private var colorItems: [WidgetColorOption: NSMenuItem] = [:]

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

        let petMenu = NSMenu()
        for pet in WidgetPet.allCases {
            let item = NSMenuItem(title: pet.title, action: #selector(selectPet(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = pet
            item.state = (pet == settings.widgetPet) ? .on : .off
            petItems[pet] = item
            petMenu.addItem(item)
        }
        let petParent = NSMenuItem(title: "Pets", action: nil, keyEquivalent: "")
        petParent.submenu = petMenu
        menu.addItem(petParent)

        let colorMenu = NSMenu()
        for color in WidgetColorOption.allCases {
            let item = NSMenuItem(title: color.title, action: #selector(selectColor(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = color
            item.image = swatchImage(for: color.swatch)
            item.state = (color == settings.widgetColor) ? .on : .off
            colorItems[color] = item
            colorMenu.addItem(item)
        }
        let colorParent = NSMenuItem(title: "Color", action: nil, keyEquivalent: "")
        colorParent.submenu = colorMenu
        menu.addItem(colorParent)

        soundEnabledItem = NSMenuItem(title: "Reminder Sound", action: #selector(toggleSound), keyEquivalent: "")
        soundEnabledItem.target = self
        soundEnabledItem.state = settings.soundEnabled ? .on : .off
        menu.addItem(soundEnabledItem)

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

        settings.$soundEnabled
            .sink { [weak self] enabled in self?.soundEnabledItem?.state = enabled ? .on : .off }
            .store(in: &cancellables)

        settings.$widgetPet
            .sink { [weak self] pet in
                guard let self else { return }
                for (candidate, item) in self.petItems {
                    item.state = (candidate == pet) ? .on : .off
                }
            }
            .store(in: &cancellables)

        settings.$widgetColor
            .sink { [weak self] color in
                guard let self else { return }
                for (candidate, item) in self.colorItems {
                    item.state = (candidate == color) ? .on : .off
                }
            }
            .store(in: &cancellables)
    }

    private func swatchImage(for color: NSColor) -> NSImage {
        let size = NSSize(width: 12, height: 12)
        let image = NSImage(size: size)
        image.lockFocus()
        color.setFill()
        NSBezierPath(ovalIn: NSRect(origin: .zero, size: size)).fill()
        image.unlockFocus()
        image.isTemplate = false
        return image
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

    @objc private func toggleSound() {
        settings.soundEnabled.toggle()
    }

    @objc private func selectPet(_ sender: NSMenuItem) {
        guard let pet = sender.representedObject as? WidgetPet else { return }
        settings.widgetPet = pet
    }

    @objc private func selectColor(_ sender: NSMenuItem) {
        guard let color = sender.representedObject as? WidgetColorOption else { return }
        settings.widgetColor = color
    }
}
