import SwiftUI

/// An 8-petal blob radiating from a central core, filled as one shape so overlapping
/// petals read as a single silhouette rather than punching holes in each other.
struct FlowerShape: Shape {
    private let petalCount = 8

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        // Petal tip sits at distance `petalLength` from center (the ellipse's farthest
        // point from origin), so it must stay within the rect's half-extent or it clips.
        let radius = min(rect.width, rect.height) / 2
        let petalLength = radius * 0.92
        let petalWidth = petalLength * 0.55
        let coreRadius = radius * 0.34

        var path = Path()
        for i in 0..<petalCount {
            let angle = (Double(i) / Double(petalCount)) * 2 * .pi
            let petalRect = CGRect(x: -petalWidth / 2, y: -petalLength, width: petalWidth, height: petalLength)
            let petal = Path(ellipseIn: petalRect)
                .applying(CGAffineTransform(translationX: center.x, y: center.y).rotated(by: angle))
            path.addPath(petal)
        }
        path.addPath(Path(ellipseIn: CGRect(x: center.x - coreRadius, y: center.y - coreRadius, width: coreRadius * 2, height: coreRadius * 2)))
        return path
    }
}

/// A cat peeking over an edge: rounded head with two triangular ears.
struct CatShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        var path = Path()
        let headRect = CGRect(x: 0, y: h * 0.30, width: w, height: h * 0.70)
        path.addPath(Path(roundedRect: headRect, cornerRadius: min(w, h) * 0.30))

        var leftEar = Path()
        leftEar.move(to: CGPoint(x: w * 0.08, y: h * 0.42))
        leftEar.addLine(to: CGPoint(x: w * 0.30, y: 0))
        leftEar.addLine(to: CGPoint(x: w * 0.45, y: h * 0.42))
        leftEar.closeSubpath()
        path.addPath(leftEar)

        var rightEar = Path()
        rightEar.move(to: CGPoint(x: w * 0.55, y: h * 0.42))
        rightEar.addLine(to: CGPoint(x: w * 0.72, y: 0))
        rightEar.addLine(to: CGPoint(x: w * 0.94, y: h * 0.42))
        rightEar.closeSubpath()
        path.addPath(rightEar)

        return path
    }
}
