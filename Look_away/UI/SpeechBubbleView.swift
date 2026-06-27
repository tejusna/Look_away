import SwiftUI

struct SpeechBubbleView: View {
    static let messages = [
        "Look away 👀\nTime to rest your eyes.",
        "Eye break! 👀\n20 feet away, 20 seconds.",
        "Psst... 👀\nGive those eyes a rest."
    ]

    let text: String
    var onDismiss: () -> Void

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.purple)
            )
            .fixedSize()
            .onTapGesture { onDismiss() }
    }
}

#Preview {
    SpeechBubbleView(text: SpeechBubbleView.messages[0], onDismiss: {})
        .padding()
}
