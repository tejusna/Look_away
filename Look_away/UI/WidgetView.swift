import SwiftUI

/// Root content of the floating widget panel: the eye blob, plus a speech bubble
/// that appears on the side facing into the screen when a reminder/announcement is active.
struct WidgetView: View {
    let edge: ScreenEdge
    let isAnnouncing: Bool
    let message: String
    @ObservedObject var lookController: EyeLookController
    var onDismiss: () -> Void
    var onDragBegan: () -> Void = {}
    var onDragChanged: () -> Void = {}
    var onDragEnded: () -> Void = {}

    private let blobSize: CGFloat = 56
    private let dismissThreshold: CGFloat = 40

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

    private var blob: some View {
        Circle()
            .fill(
                LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .frame(width: blobSize, height: blobSize)
            .overlay(EyesView(isAlert: isAnnouncing, lookController: lookController))
            .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
            .overlay(WindowDragHandle(onBegan: onDragBegan, onChanged: onDragChanged, onEnded: onDragEnded))
    }

    private var bubble: some View {
        SpeechBubbleView(text: message, onDismiss: onDismiss)
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
    WidgetView(edge: .right, isAnnouncing: true, message: SpeechBubbleView.messages[0], lookController: EyeLookController(), onDismiss: {})
        .padding()
}
