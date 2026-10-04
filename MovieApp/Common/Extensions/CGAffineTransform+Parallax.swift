import CoreGraphics

nonisolated extension CGAffineTransform {
    static func parallax(offset: CGFloat, height: CGFloat) -> CGAffineTransform {
        let translation = CGAffineTransform(translationX: 0, y: offset / 2)
        guard offset < 0, height > 0 else { return translation }
        let scale = 1 - offset / height
        return translation.scaledBy(x: scale, y: scale)
    }
}
