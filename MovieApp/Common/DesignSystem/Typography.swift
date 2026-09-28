import UIKit

// Lexend, scaled with UIFontMetrics so every style follows Dynamic Type. Labels using these fonts
// must set `adjustsFontForContentSizeCategory = true`.
enum Typography {
    static let largeTitle = font(.bold, size: 32, relativeTo: .largeTitle)
    static let display = font(.bold, size: 30, relativeTo: .largeTitle)
    static let navigationTitle = font(.semiBold, size: 17, relativeTo: .headline)
    static let sectionTitle = font(.semiBold, size: 18, relativeTo: .title3)
    static let rowTitle = font(.semiBold, size: 15, relativeTo: .subheadline)
    static let body = font(.regular, size: 15, relativeTo: .body)
    static let label = font(.medium, size: 14, relativeTo: .callout)
    static let artworkTitle = font(.bold, size: 14, relativeTo: .callout)
    static let footnote = font(.regular, size: 13, relativeTo: .footnote)
    static let caption = font(.regular, size: 12, relativeTo: .caption1)

    private enum Weight: String {
        case regular = "Lexend-Regular"
        case medium = "Lexend-Medium"
        case semiBold = "Lexend-SemiBold"
        case bold = "Lexend-Bold"

        var systemWeight: UIFont.Weight {
            switch self {
            case .regular:
                .regular
            case .medium:
                .medium
            case .semiBold:
                .semibold
            case .bold:
                .bold
            }
        }
    }

    // Falls back to the system font if a Lexend file is missing from the bundle.
    private static func font(_ weight: Weight, size: CGFloat, relativeTo textStyle: UIFont.TextStyle) -> UIFont {
        let font = UIFont(name: weight.rawValue, size: size) ?? .systemFont(ofSize: size, weight: weight.systemWeight)
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font)
    }
}
