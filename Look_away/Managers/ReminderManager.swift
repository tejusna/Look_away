import Foundation
import Combine

/// Drives the idle -> reminding -> idle cycle on the configured interval, independent of UI.
/// How long the reminder stays visible / swipe-to-dismiss is owned by the widget itself.
final class ReminderManager: ObservableObject {
    /// Called when a reminder should be shown (interval elapsed, or "Remind me now").
    var onRemind: ((String) -> Void)?

    private let settings: AppSettings
    private var intervalTimer: Timer?
    private var cancellables: Set<AnyCancellable> = []

    init(settings: AppSettings) {
        self.settings = settings

        settings.$interval
            .dropFirst()
            .sink { [weak self] _ in self?.restartIntervalTimer() }
            .store(in: &cancellables)
    }

    func start() {
        if !settings.isPaused {
            restartIntervalTimer()
        }
    }

    func pause() {
        settings.isPaused = true
        intervalTimer?.invalidate()
        intervalTimer = nil
    }

    func resume() {
        settings.isPaused = false
        restartIntervalTimer()
    }

    func remindNow() {
        triggerReminder()
    }

    /// Widget finished showing a reminder (timed out or user dismissed) — restart the interval.
    func dismiss() {
        restartIntervalTimer()
    }

    private func restartIntervalTimer() {
        intervalTimer?.invalidate()
        guard !settings.isPaused else { return }
        intervalTimer = Timer.scheduledTimer(withTimeInterval: settings.interval.seconds, repeats: false) { [weak self] _ in
            self?.triggerReminder()
        }
    }

    private func triggerReminder() {
        let message = SpeechBubbleView.messages.randomElement() ?? SpeechBubbleView.messages[0]
        onRemind?(message)
    }
}
