import SwiftUI

struct SpeechBubbleView: View {
    static let messages = [
        "Look away 👀\nTime to rest your eyes.",
        "Eye break! 👀\n20 feet away, 20 seconds.",
        "Psst... 👀\nGive those eyes a rest."
    ]

    let text: String
    var color: WidgetColorOption = .default
    var onDismiss: () -> Void

    /// Must stay <= the bubble width `WidgetWindowController` budgets into the panel
    /// frame (`bubbleExtent`, minus this view's own horizontal padding). Without this cap,
    /// any message lacking a manual "\n" sizes to one line via `fixedSize()` and can grow
    /// wider than the panel itself, pushing the pet outside the frame and clipping it.
    private let maxTextWidth: CGFloat = 144

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .frame(maxWidth: maxTextWidth)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.bubbleColor)
            )
            .fixedSize(horizontal: false, vertical: true)
            .onTapGesture { onDismiss() }
    }
}

#Preview {
    SpeechBubbleView(text: SpeechBubbleView.messages[0], color: .red, onDismiss: {})
        .padding()
}
