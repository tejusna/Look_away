import SwiftUI

/// Root content of the floating widget panel: the eye blob, plus a speech bubble
/// that appears on the side facing into the screen when a reminder/announcement is active.
struct WidgetView: View {
    let edge: ScreenEdge
    let isAnnouncing: Bool
    let message: String
    @ObservedObject var settings: AppSettings
    @ObservedObject var lookController: EyeLookController
    var onDismiss: () -> Void
    var onDragBegan: () -> Void = {}
    var onDragChanged: () -> Void = {}
    var onDragEnded: () -> Void = {}

    private let blobSize: CGFloat = 56
    // Room around the pet so its drop shadow isn't clipped at the panel edge.
    // Must match `shadowPadding` in WidgetWindowController (panel footprint = blobSize + 2x).
    private let shadowPadding: CGFloat = 6
    private let dismissThreshold: CGFloat = 40

    private var cellSize: CGFloat { blobSize + shadowPadding * 2 }

    var body: some View {
        switch edge {
        case .left:
            HStack(spacing: 10) {
                blob
                if isAnnouncing { bubble }
            }
        case .right:
            HStack(spacing: 10) {
                if isAnnouncing { bubble }
                blob
            }
        }
    }

    @ViewBuilder
    private var blob: some View {
        switch settings.widgetPet {
        case .bouncy:
            blobContent(shape: Circle())
        case .boxy:
            blobContent(shape: RoundedRectangle(cornerRadius: 14))
        case .flower:
            blobContent(shape: FlowerShape(), eyesScale: 0.78)
        case .cat:
            blobContent(shape: CatShape(), eyesYOffset: 6)
        }
    }

    private func blobContent(shape: some Shape, eyesYOffset: CGFloat = 0, eyesScale: CGFloat = 1) -> some View {
        shape
            .fill(
                LinearGradient(colors: settings.widgetColor.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .frame(width: blobSize, height: blobSize)
            .overlay(EyesView(isAlert: isAnnouncing, scale: eyesScale, lookController: lookController).offset(y: eyesYOffset))
            .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
            // Center the shadowed pet in a larger cell so the shadow has room and isn't
            // clipped at the panel edge. Drag handle covers the whole cell.
            .frame(width: cellSize, height: cellSize)
            .overlay(WindowDragHandle(onBegan: onDragBegan, onChanged: onDragChanged, onEnded: onDragEnded))
    }

    private var bubble: some View {
        SpeechBubbleView(text: message, color: settings.widgetColor, onDismiss: onDismiss)
            .transition(.scale.combined(with: .opacity))
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onEnded { value in
                        if abs(value.translation.width) > dismissThreshold || abs(value.translation.height) > dismissThreshold {
                            onDismiss()
                        }
                    }
            )
    }
}

#Preview {
    WidgetView(edge: .right, isAnnouncing: true, message: SpeechBubbleView.messages[0], settings: AppSettings(), lookController: EyeLookController(), onDismiss: {})
        .padding()
}
