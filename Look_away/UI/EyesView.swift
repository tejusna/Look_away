import SwiftUI

/// Drives the pupils' "looking at the cursor" offset from outside SwiftUI's view tree.
/// `WidgetWindowController` owns one of these and updates `offset` on a timer (using
/// `NSEvent.mouseLocation` + the panel's known screen frame) while a reminder is showing.
final class EyeLookController: ObservableObject {
    @Published var offset: CGSize = .zero
}

/// Two expressive animated eyes — the personality of the widget.
struct EyesView: View {
    /// Reminding state makes the eyes widen, look more alert, and track the cursor.
    var isAlert: Bool
    /// Per-pet size factor for the eyes and the gap between them (1 = default).
    var scale: CGFloat = 1
    /// Draw a pair of spectacles over the eyes.
    var showSpecs: Bool = false
    @ObservedObject var lookController: EyeLookController

    @State private var isBlinking = false
    @State private var idleLookOffset: CGSize = .zero
    @State private var blinkTask: Task<Void, Never>?
    @State private var lookTask: Task<Void, Never>?

    private var pupilOffset: CGSize {
        isAlert ? lookController.offset : idleLookOffset
    }

    var body: some View {
        HStack(spacing: 8 * scale) {
            eye
            eye
        }
        .overlay(specsOverlay)
        .onAppear { startBlinkLoop(); startLookLoop() }
        .onDisappear { blinkTask?.cancel(); lookTask?.cancel() }
    }

    /// Oversized glasses. The eye-aligned baseline width spaces the lenses exactly over the
    /// two eye centers (24*scale apart); `oversize` then enlarges the whole frame, so the
    /// lenses grow and spread for a chunky, oversized look while staying centered on the eyes.
    @ViewBuilder
    private var specsOverlay: some View {
        if showSpecs {
            let oversize: CGFloat = 1.45
            let width = (24 * scale / SpecsShape.lensSpacingFraction) * oversize
            let height = width * SpecsShape.referenceSize.height / SpecsShape.referenceSize.width
            SpecsShape()
                .stroke(Color.black.opacity(0.85), style: StrokeStyle(lineWidth: 1.9 * scale, lineCap: .round, lineJoin: .round))
                .frame(width: width, height: height)
        }
    }

    private var eye: some View {
        ZStack {
            Capsule()
                .fill(Color.white)
                .frame(width: 16 * scale, height: (isBlinking ? 2 : (isAlert ? 22 : 18)) * scale)

            Circle()
                .fill(Color.black)
                .frame(width: 8 * scale, height: 8 * scale)
                .offset(pupilOffset)
                .opacity(isBlinking ? 0 : 1)
                .animation(.easeOut(duration: 0.12), value: pupilOffset)
        }
        .animation(.easeInOut(duration: 0.12), value: isBlinking)
        .animation(.easeInOut(duration: 0.3), value: isAlert)
    }

    private func startBlinkLoop() {
        blinkTask = Task {
            while !Task.isCancelled {
                let delay = Double.random(in: 2.0...5.0)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled else { return }
                isBlinking = true
                try? await Task.sleep(nanoseconds: 120_000_000)
                guard !Task.isCancelled else { return }
                isBlinking = false
            }
        }
    }

    private func startLookLoop() {
        lookTask = Task {
            while !Task.isCancelled {
                let delay = Double.random(in: 2.5...5.5)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled, !isAlert else { continue }
                let dx = CGFloat.random(in: -3...3)
                let dy = CGFloat.random(in: -2...2)
                withAnimation(.easeInOut(duration: 0.35)) {
                    idleLookOffset = CGSize(width: dx, height: dy)
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.35)) {
                    idleLookOffset = .zero
                }
            }
        }
    }
}

#Preview {
    EyesView(isAlert: false, lookController: EyeLookController())
        .padding()
        .background(Color.purple)
}
