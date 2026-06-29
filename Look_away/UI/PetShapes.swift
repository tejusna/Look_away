import SwiftUI

/// A rounded 8-lobed flower silhouette, traced from Eye_Flower.svg.
///
/// The SVG path is authored in a 526x526 box (its two nested translate transforms,
/// dx=-1629 dy=-1225, are baked into the coordinates below). We draw it in that
/// reference box, then scale+center it to fit `rect`. SVG and SwiftUI both have y
/// growing downward, so no vertical flip is needed.
struct FlowerShape: Shape {
    private static let reference: CGFloat = 526

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 196.694, y: 102.922))
        path.addCurve(to: CGPoint(x: 263, y: 0), control1: CGPoint(x: 196.694, y: 46.118), control2: CGPoint(x: 226.405, y: 0))
        path.addCurve(to: CGPoint(x: 329.306, y: 102.922), control1: CGPoint(x: 299.595, y: 0), control2: CGPoint(x: 329.306, y: 46.118))
        path.addCurve(to: CGPoint(x: 448.969, y: 77.031), control1: CGPoint(x: 369.473, y: 62.756), control2: CGPoint(x: 423.092, y: 51.154))
        path.addCurve(to: CGPoint(x: 423.078, y: 196.694), control1: CGPoint(x: 474.846, y: 102.908), control2: CGPoint(x: 463.244, y: 156.527))
        path.addCurve(to: CGPoint(x: 526, y: 263), control1: CGPoint(x: 479.882, y: 196.694), control2: CGPoint(x: 526, y: 226.405))
        path.addCurve(to: CGPoint(x: 423.078, y: 329.306), control1: CGPoint(x: 526, y: 299.595), control2: CGPoint(x: 479.882, y: 329.306))
        path.addCurve(to: CGPoint(x: 448.969, y: 448.969), control1: CGPoint(x: 463.244, y: 369.473), control2: CGPoint(x: 474.846, y: 423.092))
        path.addCurve(to: CGPoint(x: 329.306, y: 423.078), control1: CGPoint(x: 423.092, y: 474.846), control2: CGPoint(x: 369.473, y: 463.244))
        path.addCurve(to: CGPoint(x: 263, y: 526), control1: CGPoint(x: 329.306, y: 479.882), control2: CGPoint(x: 299.595, y: 526))
        path.addCurve(to: CGPoint(x: 196.694, y: 423.078), control1: CGPoint(x: 226.405, y: 526), control2: CGPoint(x: 196.694, y: 479.882))
        path.addCurve(to: CGPoint(x: 77.031, y: 448.969), control1: CGPoint(x: 156.527, y: 463.244), control2: CGPoint(x: 102.908, y: 474.846))
        path.addCurve(to: CGPoint(x: 102.922, y: 329.306), control1: CGPoint(x: 51.154, y: 423.092), control2: CGPoint(x: 62.756, y: 369.473))
        path.addCurve(to: CGPoint(x: 0, y: 263), control1: CGPoint(x: 46.118, y: 329.306), control2: CGPoint(x: 0, y: 299.595))
        path.addCurve(to: CGPoint(x: 102.922, y: 196.694), control1: CGPoint(x: 0, y: 226.405), control2: CGPoint(x: 46.118, y: 196.694))
        path.addCurve(to: CGPoint(x: 77.031, y: 77.031), control1: CGPoint(x: 62.756, y: 156.527), control2: CGPoint(x: 51.154, y: 102.908))
        path.addCurve(to: CGPoint(x: 196.694, y: 102.922), control1: CGPoint(x: 102.908, y: 51.154), control2: CGPoint(x: 156.527, y: 62.756))
        path.closeSubpath()

        let scale = min(rect.width, rect.height) / Self.reference
        let dx = rect.minX + (rect.width - Self.reference * scale) / 2
        let dy = rect.minY + (rect.height - Self.reference * scale) / 2
        return path.applying(CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: dx, ty: dy))
    }
}

/// A cat head with two pointed ears, traced from cat.svg.
///
/// Authored in a 324x295 box (the two nested translate transforms, dx=-312
/// dy=-1548.820812, are baked into the coordinates). Scaled to fit `rect` with the
/// box's aspect ratio preserved, then centered.
struct CatShape: Shape {
    private static let refW: CGFloat = 324
    private static let refH: CGFloat = 295

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 268.297, y: 29.016))
        path.addCurve(to: CGPoint(x: 285.671, y: 25.194), control1: CGPoint(x: 272.935, y: 24.624), control2: CGPoint(x: 279.619, y: 23.154))
        path.addCurve(to: CGPoint(x: 297.186, y: 38.754), control1: CGPoint(x: 291.723, y: 27.234), control2: CGPoint(x: 296.153, y: 32.451))
        path.addCurve(to: CGPoint(x: 324, y: 213.179), control1: CGPoint(x: 306.484, y: 91.429), control2: CGPoint(x: 324, y: 193.159))
        path.addCurve(to: CGPoint(x: 324, y: 213.182), control1: CGPoint(x: 324, y: 213.180), control2: CGPoint(x: 324, y: 213.181))
        path.addCurve(to: CGPoint(x: 243.002, y: 294.179), control1: CGPoint(x: 323.999, y: 257.916), control2: CGPoint(x: 287.735, y: 294.179))
        path.addCurve(to: CGPoint(x: 81, y: 294.179), control1: CGPoint(x: 195.328, y: 294.179), control2: CGPoint(x: 128.674, y: 294.179))
        path.addCurve(to: CGPoint(x: 23.724, y: 270.455), control1: CGPoint(x: 59.517, y: 294.179), control2: CGPoint(x: 38.915, y: 285.645))
        path.addCurve(to: CGPoint(x: 0, y: 213.179), control1: CGPoint(x: 8.534, y: 255.264), control2: CGPoint(x: 0, y: 234.662))
        path.addCurve(to: CGPoint(x: 32.972, y: 30.311), control1: CGPoint(x: 0, y: 189.653), control2: CGPoint(x: 21.783, y: 83.361))
        path.addCurve(to: CGPoint(x: 44.64, y: 17.226), control1: CGPoint(x: 34.187, y: 24.149), control2: CGPoint(x: 38.657, y: 19.136))
        path.addCurve(to: CGPoint(x: 61.732, y: 21.129), control1: CGPoint(x: 50.623, y: 15.316), control2: CGPoint(x: 57.171, y: 16.811))
        path.addCurve(to: CGPoint(x: 97.265, y: 54.748), control1: CGPoint(x: 74.123, y: 32.837), control2: CGPoint(x: 88.706, y: 46.644))
        path.addCurve(to: CGPoint(x: 113.654, y: 58.541), control1: CGPoint(x: 101.638, y: 58.887), control2: CGPoint(x: 107.908, y: 60.338))
        path.addCurve(to: CGPoint(x: 162, y: 51.179), control1: CGPoint(x: 128.922, y: 53.753), control2: CGPoint(x: 145.163, y: 51.179))
        path.addCurve(to: CGPoint(x: 219.873, y: 61.839), control1: CGPoint(x: 182.386, y: 51.179), control2: CGPoint(x: 201.897, y: 54.953))
        path.addCurve(to: CGPoint(x: 237.24, y: 58.396), control1: CGPoint(x: 225.842, y: 64.131), control2: CGPoint(x: 232.597, y: 62.792))
        path.addCurve(to: CGPoint(x: 268.297, y: 29.016), control1: CGPoint(x: 245.042, y: 51.033), control2: CGPoint(x: 257.364, y: 39.367))
        path.closeSubpath()

        let scale = min(rect.width / Self.refW, rect.height / Self.refH)
        let dx = rect.minX + (rect.width - Self.refW * scale) / 2
        let dy = rect.minY + (rect.height - Self.refH * scale) / 2
        return path.applying(CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: dx, ty: dy))
    }
}
