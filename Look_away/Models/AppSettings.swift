import Foundation
import Combine

/// UserDefaults-backed app settings, observable so UI/menu state stays in sync.
final class AppSettings: ObservableObject {
    private enum Key {
        static let interval = "reminderInterval"
        static let widgetPosition = "widgetPosition"
        static let isPaused = "isPaused"
        static let launchPromptCount = "launchPromptCount"
        static let launchAtLoginEnabled = "launchAtLoginEnabled"
        static let widgetPet = "widgetPet"
        static let widgetColor = "widgetColor"
        static let soundEnabled = "soundEnabled"
    }

    private let defaults: UserDefaults

    @Published var interval: ReminderInterval {
        didSet { defaults.set(interval.rawValue, forKey: Key.interval) }
    }

    @Published var widgetPosition: WidgetPosition {
        didSet {
            if let data = try? JSONEncoder().encode(widgetPosition) {
                defaults.set(data, forKey: Key.widgetPosition)
            }
        }
    }

    @Published var isPaused: Bool {
        didSet { defaults.set(isPaused, forKey: Key.isPaused) }
    }

    @Published var launchAtLoginEnabled: Bool {
        didSet { defaults.set(launchAtLoginEnabled, forKey: Key.launchAtLoginEnabled) }
    }

    @Published var widgetPet: WidgetPet {
        didSet { defaults.set(widgetPet.rawValue, forKey: Key.widgetPet) }
    }

    @Published var widgetColor: WidgetColorOption {
        didSet { defaults.set(widgetColor.rawValue, forKey: Key.widgetColor) }
    }

    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Key.soundEnabled) }
    }

    /// Number of times we've shown (or considered showing) the launch-at-login prompt.
    var launchPromptCount: Int {
        get { defaults.integer(forKey: Key.launchPromptCount) }
        set { defaults.set(newValue, forKey: Key.launchPromptCount) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let rawInterval = defaults.object(forKey: Key.interval) as? Int,
           let stored = ReminderInterval(rawValue: rawInterval) {
            interval = stored
        } else {
            interval = .default
        }

        if let data = defaults.data(forKey: Key.widgetPosition),
           let stored = try? JSONDecoder().decode(WidgetPosition.self, from: data) {
            widgetPosition = stored
        } else {
            widgetPosition = .default
        }

        isPaused = defaults.bool(forKey: Key.isPaused)
        launchAtLoginEnabled = defaults.bool(forKey: Key.launchAtLoginEnabled)

        if let rawPet = defaults.string(forKey: Key.widgetPet),
           let stored = WidgetPet(rawValue: rawPet) {
            widgetPet = stored
        } else {
            widgetPet = .default
        }

        if let rawColor = defaults.string(forKey: Key.widgetColor),
           let stored = WidgetColorOption(rawValue: rawColor) {
            widgetColor = stored
        } else {
            widgetColor = .default
        }

        if let stored = defaults.object(forKey: Key.soundEnabled) as? Bool {
            soundEnabled = stored
        } else {
            soundEnabled = true
        }
    }
}
