import UIKit

final class PlayBadgeView: UIView {
    private static let side: CGFloat = 30

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.side, height: Self.side)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Layout
private extension PlayBadgeView {
    func setUpLayout() {
        backgroundColor = .brand
        layer.cornerRadius = Radius.small
        layer.cornerCurve = .continuous
        isAccessibilityElement = false
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        let imageView = UIImageView(image: UIImage(systemName: "play.fill", withConfiguration: symbolConfiguration))
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
