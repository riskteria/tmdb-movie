import MovieAppDS
import UIKit

final class RatingBadgeView: UIView {
    private lazy var ratingLabel = makeRatingLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(rating: String?) {
        ratingLabel.text = rating
        isHidden = rating == nil
    }
}

// MARK: - Layout
private extension RatingBadgeView {
    func setUpLayout() {
        backgroundColor = .MVColor(.badgeScrim)
        layer.cornerRadius = Radius.small
        layer.cornerCurve = .continuous
        isAccessibilityElement = false
        maximumContentSizeCategory = .accessibilityMedium
        let stackView = UIStackView(arrangedSubviews: [makeStarView(), ratingLabel])
        stackView.alignment = .center
        stackView.spacing = Spacing.xxSmall
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.xxSmall),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.xSmall),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.xSmall),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.xxSmall)
        ])
    }

    func makeRatingLabel() -> UILabel {
        let label = UILabel()
        label.font = .MVFont(.caption)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .white
        return label
    }

    func makeStarView() -> UIImageView {
        let configuration = UIImage.SymbolConfiguration(textStyle: .caption2)
        let imageView = UIImageView(image: UIImage(systemName: "star.fill", withConfiguration: configuration))
        imageView.tintColor = .MVColor(.ratingGold)
        return imageView
    }
}
