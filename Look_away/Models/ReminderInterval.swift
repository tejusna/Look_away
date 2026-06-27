import Foundation

enum ReminderInterval: Int, CaseIterable, Codable {
    // TODO(testing): remove `.one` and switch default back to `.twenty` before shipping.
    case one = 1
    case twenty = 20
    case thirty = 30
    case fortyFive = 45
    case sixty = 60

    var minutes: Int { rawValue }

    var seconds: TimeInterval { TimeInterval(rawValue * 60) }

    var title: String { "\(rawValue) min" }

    static var `default`: ReminderInterval { .one }
}
