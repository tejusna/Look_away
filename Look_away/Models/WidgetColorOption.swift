import AppKit
import SwiftUI

/// The blob's color skin, user-selectable from the menu bar.
enum WidgetColorOption: String, CaseIterable, Codable {
    case purple, red, blue, orange, green

    var title: String { rawValue.capitalized }

    /// Gradient used to fill the blob.
    var gradientColors: [Color] {
        switch self {
        case .purple: return [.purple, .indigo]
        case .red: return [.red, .pink]
        case .blue: return [.blue, .cyan]
        case .orange: return [.orange, .yellow]
        case .green: return [.green, .mint]
        }
    }

    /// Muted flat fill for the speech bubble — softer than the blob's gradient
    /// so bright skins (red in particular) don't read as alarming next to white text.
    var bubbleColor: Color {
        switch self {
        case .purple: return Color(red: 0.40, green: 0.27, blue: 0.64)
        case .red: return Color(red: 0.72, green: 0.30, blue: 0.32)
        case .blue: return Color(red: 0.20, green: 0.45, blue: 0.70)
        case .orange: return Color(red: 0.80, green: 0.55, blue: 0.20)
        case .green: return Color(red: 0.30, green: 0.55, blue: 0.40)
        }
    }

    /// Flat swatch color shown next to the menu item.
    var swatch: NSColor {
        switch self {
        case .purple: return .systemPurple
        case .red: return .systemRed
        case .blue: return .systemBlue
        case .orange: return .systemOrange
        case .green: return .systemGreen
        }
    }

    static let `default` = WidgetColorOption.purple
}
