import AppKit
import SwiftUI

private enum WidgetPhase: Equatable {
    case hidden
    case peeking
    case announcing(String)
}

/// Borderless panel that allows fully free programmatic positioning.
///
/// `NSWindow`'s default `constrainFrameRect(_:to:)` keeps a window's top edge below the
/// menu bar and otherwise on-screen. That silently clamps the panel every time we move it
/// via `setFrameOrigin` during a drag, so the widget can't be dragged up near the top of
/// the screen ("won't go up past a certain level") and lands at the wrong height on release
/// ("doesn't stick where I dropped it"). We manage on-screen clamping ourselves in
/// `visibleFrame()`, so this override opts out of AppKit's.
private final class WidgetPanel: NSPanel {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}

/// Hosts the widget in a borderless, non-activating floating NSPanel.
///
/// Idle state is fully hidden (`orderOut`, zero footprint, not just a tiny sliver).
/// It becomes visible either to "peek" (menu opened, or mid-drag) or to "announce" a
/// reminder/intro message with a speech bubble. Dragging repositions it along the
/// left or right screen edge only.
final class WidgetWindowController {
    private let panel: WidgetPanel
    private let hostingView: NSHostingView<WidgetView>
    private let settings: AppSettings
    private let eyeLook = EyeLookController()

    private let blobSize: CGFloat = 56
    // Room around the pet so its drop shadow isn't clipped at the panel edge.
    // Must match `shadowPadding` in WidgetView. Panel footprint uses `cellSize`.
    private let shadowPadding: CGFloat = 6
    private var cellSize: CGFloat { blobSize + shadowPadding * 2 }
    private let margin: CGFloat = 12
    private let bubbleExtent: CGFloat = 188
    private let announceDuration: TimeInterval = 10
    private let maxEyeOffset: CGFloat = 4

    private var phase: WidgetPhase = .hidden
    private var currentScreen: NSScreen
    private var pendingDismiss: (() -> Void)?
    private var announceTimer: Timer?
    private var retreatTimer: Timer?
    private var cursorTimer: Timer?
    private var keepOnTopTimer: Timer?

    private var dragStartMouseLocation: NSPoint?
    private var dragStartOrigin: NSPoint?

    /// Bumped on every transition so a stale slide-out's completion (e.g. an `orderOut`
    /// scheduled before a fast re-click reopened the menu) can't undo a newer transition.
    private var transitionID = 0

    init(settings: AppSettings) {
        self.settings = settings
        self.currentScreen = NSScreen.main ?? NSScreen.screens[0]

        panel = WidgetPanel(
            contentRect: NSRect(x: 0, y: 0, width: blobSize + shadowPadding * 2, height: blobSize + shadowPadding * 2),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.isMovableByWindowBackground = false
        panel.ignoresMouseEvents = false
        panel.hidesOnDeactivate = false

        hostingView = NSHostingView(rootView: WidgetView(
            edge: settings.widgetPosition.edge, isAnnouncing: false, message: "", settings: settings, lookController: eyeLook, onDismiss: {}
        ))
        panel.contentView = hostingView
        // Stays fully off-screen until something shows it; nothing to see, nothing clickable.
    }

    // MARK: - Public API

    /// Plays the one-time launch intro, then hands off to `onFinished` (typically starts the reminder timer).
    func announceIntro(intervalMinutes: Int, onFinished: @escaping () -> Void) {
        announce(message: "I'll remind you every \(intervalMinutes) min to look away 👀", onFinished: onFinished)
    }

    /// Shows a recurring reminder. `onFinished` restarts the interval timer.
    func announceReminder(message: String, onFinished: @escaping () -> Void) {
        playWhooshIfEnabled()
        announce(message: message, onFinished: onFinished)
    }

    /// Playful peek with no message, triggered by opening the menu. Draggable while visible.
    func peek() {
        retreatTimer?.invalidate()
        guard phase == .hidden else { return }
        transitionID += 1
        phase = .peeking
        rebuildContent()
        slideIn(to: visibleFrame())
        startKeepOnTop()
    }

    /// Hides the peek a short while after the menu closes, unless a drag is in progress.
    ///
    /// Only retreats if we're still just peeking by the time the timer fires: if an
    /// announce started in the meantime (e.g. "Remind Me Now" clicked while the menu's
    /// peek animation was still running), this must not cut that announcement short —
    /// otherwise the slide-in can get reversed mid-flight and the pet never fully appears.
    func scheduleRetreat(after delay: TimeInterval) {
        retreatTimer?.invalidate()
        retreatTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self, case .peeking = self.phase else { return }
            self.retreat()
        }
    }

    // MARK: - Announce flow

    private func announce(message: String, onFinished: @escaping () -> Void) {
        retreatTimer?.invalidate()
        announceTimer?.invalidate()
        transitionID += 1
        pendingDismiss = onFinished

        phase = .announcing(message)
        rebuildContent()
        slideIn(to: visibleFrame())
        startEyeTracking()
        startKeepOnTop()

        announceTimer = Timer.scheduledTimer(withTimeInterval: announceDuration, repeats: false) { [weak self] _ in
            self?.finishAnnounce()
        }
    }

    private func finishAnnounce() {
        announceTimer?.invalidate()
        announceTimer = nil
        let dismiss = pendingDismiss
        pendingDismiss = nil
        retreat {
            dismiss?()
        }
    }

    // MARK: - Visibility transitions

    private func retreat(completion: (() -> Void)? = nil) {
        guard phase != .hidden else { completion?(); return }
        transitionID += 1
        let myTransitionID = transitionID
        phase = .hidden
        stopEyeTracking()
        stopKeepOnTop()
        slideOut { [weak self] in
            // Only order out if nothing newer (e.g. a fast re-click reopening the menu) took over.
            if self?.transitionID == myTransitionID {
                self?.panel.orderOut(nil)
            }
            completion?()
        }
    }

    // MARK: - Staying on top

    /// Re-asserts front ordering on a timer while visible. Same-level windows (.floating)
    /// are ordered by whoever last called "order front" system-wide, not per-app, so another
    /// app's own floating overlay (Zoom, screen recorders, menu-bar widgets) can silently win
    /// that race well after we first appeared. Re-ordering periodically — rather than bumping
    /// our window level — wins it back without touching geometry, which broke dragging.
    private func startKeepOnTop() {
        keepOnTopTimer?.invalidate()
        keepOnTopTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.panel.orderFrontRegardless()
        }
    }

    private func stopKeepOnTop() {
        keepOnTopTimer?.invalidate()
        keepOnTopTimer = nil
    }

    // MARK: - Cursor-following eyes

    private func startEyeTracking() {
        cursorTimer?.invalidate()
        cursorTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.updateEyeLook()
        }
    }

    private func stopEyeTracking() {
        cursorTimer?.invalidate()
        cursorTimer = nil
        eyeLook.offset = .zero
    }

    private func updateEyeLook() {
        guard case .announcing = phase else { return }
        let center = blobScreenCenter()
        let cursor = NSEvent.mouseLocation
        let dx = cursor.x - center.x
        let dy = cursor.y - center.y
        let distance = max(hypot(dx, dy), 1)
        let pull = min(distance / 80, 1)
        // AppKit y grows upward; SwiftUI offset.height grows downward, so flip dy.
        eyeLook.offset = CGSize(width: dx / distance * pull * maxEyeOffset, height: -dy / distance * pull * maxEyeOffset)
    }

    private func blobScreenCenter() -> NSPoint {
        let frame = panel.frame
        switch settings.widgetPosition.edge {
        case .right:
            return NSPoint(x: frame.maxX - cellSize / 2, y: frame.midY)
        case .left:
            return NSPoint(x: frame.minX + cellSize / 2, y: frame.midY)
        }
    }

    private func playWhooshIfEnabled() {
        guard settings.soundEnabled else { return }
        let sound = NSSound(named: "Blow")
        sound?.volume = 0.4
        sound?.play()
    }

    private func slideIn(to frame: NSRect) {
        panel.alphaValue = 0
        panel.setFrame(hiddenStartFrame(for: frame), display: false)
        panel.orderFrontRegardless()
        animate(to: frame, alpha: 1, duration: 0.45)
    }

    private func slideOut(completion: @escaping () -> Void) {
        let offscreen = hiddenStartFrame(for: panel.frame)
        animate(to: offscreen, alpha: 0, duration: 0.45, completion: completion)
    }

    private func animate(to frame: NSRect, alpha: CGFloat? = nil, duration: TimeInterval = 0.32, completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(frame, display: true)
            if let alpha {
                panel.animator().alphaValue = alpha
            }
        }, completionHandler: completion)
    }

    // MARK: - Content

    private func rebuildContent() {
        let message: String
        let isAnnouncing: Bool
        if case .announcing(let text) = phase {
            message = text
            isAnnouncing = true
        } else {
            message = ""
            isAnnouncing = false
        }

        hostingView.rootView = WidgetView(
            edge: settings.widgetPosition.edge,
            isAnnouncing: isAnnouncing,
            message: message,
            settings: settings,
            lookController: eyeLook,
            onDismiss: { [weak self] in self?.handleManualDismiss() },
            onDragBegan: { [weak self] in self?.handleDragBegan() },
            onDragChanged: { [weak self] in self?.handleDragChanged() },
            onDragEnded: { [weak self] in self?.handleDragEnded() }
        )
    }

    private func handleManualDismiss() {
        switch phase {
        case .announcing:
            finishAnnounce()
        case .peeking:
            retreat()
        case .hidden:
            break
        }
    }

    // MARK: - Dragging (raw screen-space tracking; see WindowDragHandle)

    private func handleDragBegan() {
        retreatTimer?.invalidate()
        announceTimer?.invalidate()
        keepOnTopTimer?.invalidate()
        dragStartMouseLocation = NSEvent.mouseLocation
        dragStartOrigin = panel.frame.origin
    }

    private func handleDragChanged() {
        guard let startMouse = dragStartMouseLocation, let startOrigin = dragStartOrigin else { return }
        let current = NSEvent.mouseLocation
        let delta = NSPoint(x: current.x - startMouse.x, y: current.y - startMouse.y)
        panel.setFrameOrigin(NSPoint(x: startOrigin.x + delta.x, y: startOrigin.y + delta.y))
    }

    private func handleDragEnded() {
        defer {
            dragStartMouseLocation = nil
            dragStartOrigin = nil
        }

        let current = NSEvent.mouseLocation
        let moved = dragStartMouseLocation.map { hypot(current.x - $0.x, current.y - $0.y) } ?? 0

        // A near-stationary mouse-up is a click, not a drag: while announcing, that means dismiss.
        if moved < 4, case .announcing = phase {
            handleManualDismiss()
            return
        }

        let center = NSPoint(x: panel.frame.midX, y: panel.frame.midY)
        let screen = screenContaining(center) ?? currentScreen
        currentScreen = screen

        let frame = screen.frame
        let edge: ScreenEdge = (center.x < frame.midX) ? .left : .right
        let fraction = (1 - (center.y - frame.minY) / frame.height).clamped(to: 0...1)

        settings.widgetPosition = WidgetPosition(edge: edge, fraction: fraction)
        rebuildContent()
        animate(to: visibleFrame())
        startKeepOnTop()

        // Resume the 20s countdown from where dragging paused it, or schedule the peek to retreat.
        switch phase {
        case .announcing:
            announceTimer = Timer.scheduledTimer(withTimeInterval: announceDuration, repeats: false) { [weak self] _ in
                self?.finishAnnounce()
            }
        case .peeking:
            scheduleRetreat(after: 1.5)
        case .hidden:
            break
        }
    }

    private func screenContaining(_ point: NSPoint) -> NSScreen? {
        NSScreen.screens.first { $0.frame.contains(point) }
    }

    // MARK: - Geometry

    private func anchorPoint(for position: WidgetPosition, on screen: NSScreen) -> NSPoint {
        let f = screen.frame
        // fraction is top-to-bottom (0 = top of screen); AppKit y grows upward.
        let y = f.maxY - position.fraction * f.height
        switch position.edge {
        case .right:
            return NSPoint(x: f.maxX, y: y)
        case .left:
            return NSPoint(x: f.minX, y: y)
        }
    }

    private func visibleFrame() -> NSRect {
        let position = settings.widgetPosition
        let screen = currentScreen.frame
        let anchor = anchorPoint(for: position, on: currentScreen)
        let isAnnouncing: Bool
        if case .announcing = phase { isAnnouncing = true } else { isAnnouncing = false }

        let width = isAnnouncing ? cellSize + 10 + bubbleExtent : cellSize
        let size = NSSize(width: width, height: cellSize)
        var origin: NSPoint

        switch position.edge {
        case .right:
            origin = NSPoint(x: anchor.x - margin - size.width, y: anchor.y - size.height / 2)
        case .left:
            origin = NSPoint(x: anchor.x + margin, y: anchor.y - size.height / 2)
        }

        origin.y = origin.y.clamped(to: screen.minY...max(screen.minY, screen.maxY - size.height))
        return NSRect(origin: origin, size: size)
    }

    /// A frame fully past the relevant screen edge, used as the slide-in/out starting/ending point.
    private func hiddenStartFrame(for visible: NSRect) -> NSRect {
        let edge = settings.widgetPosition.edge
        var origin = visible.origin
        switch edge {
        case .right:
            origin.x = currentScreen.frame.maxX + 20
        case .left:
            origin.x = currentScreen.frame.minX - visible.width - 20
        }
        return NSRect(origin: origin, size: visible.size)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
