import Foundation

enum ScreenEdge: String, Codable {
    case left, right
}

/// Where the widget is docked: which screen edge, and how far down that edge (0 = top, 1 = bottom).
struct WidgetPosition: Codable, Equatable {
    var edge: ScreenEdge
    var fraction: CGFloat

    static let `default` = WidgetPosition(edge: .right, fraction: 0.5)
}
