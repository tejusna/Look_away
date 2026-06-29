import Foundation

/// Which pet the widget takes the form of, user-selectable from the menu bar.
/// Each pet has its own personality, expressed through its reminder messages;
/// its color skin is a separate, orthogonal choice (see `WidgetColorOption`).
enum WidgetPet: String, CaseIterable, Codable {
    case bouncy, boxy, flower, cat

    var title: String { rawValue.capitalized }

    /// Personality-flavored reminder messages, shown at random when this pet announces.
    var messages: [String] {
        switch self {
        case .bouncy:
            return [
                "Boing! 👀 Time to look away!",
                "Bounce break — 20 feet, 20 seconds!",
                "Up, up, and eyes away! 👀"
            ]
        case .boxy:
            return [
                "Reminder: look away for 20 seconds.",
                "Eye break time — 20 feet away.",
                "Time's up. Rest your eyes."
            ]
        case .flower:
            return [
                "Take a breath 🌸 and look away.",
                "A little sunshine for tired eyes 👀",
                "Bloom where you blink. Look away."
            ]
        case .cat:
            return [
                "Meow. Eyes away, human. 🐾",
                "Psst — your eyes need a cat nap.",
                "Look away, or no treats. 🐾"
            ]
        }
    }

    static let `default` = WidgetPet.bouncy
}
