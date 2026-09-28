import UIKit

// Colors generated from an ID, so artwork placeholders and genre cards need no image requests.
// The hue step matches the design sample: (id × 47) mod 360.
enum ArtworkPalette {
    static func placeholderColors(seed: Int) -> [UIColor] {
        let hue = hue(for: seed)
        return [
            UIColor(hue: hue, saturation: 0.55, brightness: 0.66, alpha: 1),
            UIColor(hue: shifted(hue, by: 0.05), saturation: 0.7, brightness: 0.16, alpha: 1)
        ]
    }

    static func genreColors(genreID: Int) -> [UIColor] {
        let hue = hue(for: genreID)
        return [
            UIColor(hue: hue, saturation: 0.77, brightness: 0.85, alpha: 1),
            UIColor(hue: shifted(hue, by: 28 / 360), saturation: 0.77, brightness: 0.42, alpha: 1)
        ]
    }

    private static func hue(for seed: Int) -> CGFloat {
        CGFloat((seed % 360 + 360) % 360 * 47 % 360) / 360
    }

    private static func shifted(_ hue: CGFloat, by amount: CGFloat) -> CGFloat {
        (hue + amount).truncatingRemainder(dividingBy: 1)
    }
}
