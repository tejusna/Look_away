import SwiftUI

/// The pet's color skin, user-selectable from the Customise Pet palette. Solid colors.
enum WidgetColorOption: String, CaseIterable, Codable {
    case orange, red, blue, green, purple

    var title: String { rawValue.capitalized }

    /// Solid fill color.
    var color: Color {
        switch self {
        case .orange: return Color(hex: 0xFFA900)
        case .red: return Color(hex: 0xFF1F72)
        case .blue: return Color(hex: 0x00AAFF)
        case .green: return Color(hex: 0x00CF68)
        case .purple: return Color(hex: 0x915FF9)
        }
    }

    static let `default` = WidgetColorOption.purple
}

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
