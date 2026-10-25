import MovieAppDS
import UIKit

final class BookmarkBadgeButton: UIButton {
    private let side: CGFloat = 30
    private let minimumHitSide: CGFloat = 44
    private let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)

    private lazy var fillView = makeSymbolView(systemName: "bookmark.fill", tintColor: .MVColor(.brand))
    private lazy var edgeView = makeSymbolView(systemName: "bookmark", tintColor: .white)

    override var intrinsicContentSize: CGSize {
        CGSize(width: side, height: side)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let horizontalInset = min(0, (bounds.width - minimumHitSide) / 2)
        let verticalInset = min(0, (bounds.height - minimumHitSide) / 2)
        return bounds.insetBy(dx: horizontalInset, dy: verticalInset).contains(point)
    }

    func configure(isSaved: Bool, animated: Bool) {
        let animates = animated && !UIAccessibility.isReduceMotionEnabled
        if isSaved {
            fillView.addSymbolEffect(.appear, animated: animates)
        } else {
            fillView.addSymbolEffect(.disappear, animated: animates)
        }
        guard animates else { return }
        [fillView, edgeView].forEach { symbolView in
            symbolView.addSymbolEffect(.bounce, options: .nonRepeating)
        }
    }
}

// MARK: - Layout
private extension BookmarkBadgeButton {
    func setUpLayout() {
        backgroundColor = .MVColor(.badgeScrim)
        layer.cornerRadius = Radius.small
        layer.cornerCurve = .continuous
        isPointerInteractionEnabled = true
        isAccessibilityElement = false
        fillView.addSymbolEffect(.disappear, animated: false)
        [fillView, edgeView].forEach { symbolView in
            symbolView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(symbolView)
            NSLayoutConstraint.activate([
                symbolView.centerXAnchor.constraint(equalTo: centerXAnchor),
                symbolView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        }
    }

    func makeSymbolView(systemName: String, tintColor: UIColor) -> UIImageView {
        let imageView = UIImageView(image: UIImage(systemName: systemName, withConfiguration: symbolConfiguration))
        imageView.tintColor = tintColor
        imageView.isUserInteractionEnabled = false
        return imageView
    }
}
