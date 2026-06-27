import SwiftUI
import AppKit

/// Transparent overlay that reports raw, screen-space mouse drag events.
///
/// SwiftUI's `DragGesture` with `.global` coordinate space is relative to the *window*,
/// not the screen — so when the caller moves the window in response to the drag (as we
/// do here), the gesture's own reference frame shifts underneath it, producing jitter.
/// Tracking `NSEvent.mouseLocation` (true screen coordinates) instead sidesteps that.
struct WindowDragHandle: NSViewRepresentable {
    var onBegan: () -> Void
    var onChanged: () -> Void
    var onEnded: () -> Void

    func makeNSView(context: Context) -> TrackingView {
        let view = TrackingView()
        view.onBegan = onBegan
        view.onChanged = onChanged
        view.onEnded = onEnded
        return view
    }

    func updateNSView(_ nsView: TrackingView, context: Context) {
        nsView.onBegan = onBegan
        nsView.onChanged = onChanged
        nsView.onEnded = onEnded
    }

    final class TrackingView: NSView {
        var onBegan: (() -> Void)?
        var onChanged: (() -> Void)?
        var onEnded: (() -> Void)?

        override func mouseDown(with event: NSEvent) {
            onBegan?()
        }

        override func mouseDragged(with event: NSEvent) {
            onChanged?()
        }

        override func mouseUp(with event: NSEvent) {
            onEnded?()
        }
    }
}
