import Foundation

/// The blob's outline shape, user-selectable from the menu bar.
enum WidgetShape: String, CaseIterable, Codable {
    case circle, rectangle

    var title: String { rawValue.capitalized }

    static let `default` = WidgetShape.circle
}
