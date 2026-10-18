import MovieAppDS
import UIKit

final class MovieDetailRatingCell: UICollectionViewCell {
    private lazy var starView = makeStarView()
    private lazy var scoreLabel = makeLabel(font: .MVFont(.rowTitle), color: .MVColor(.textPrimary))
    private lazy var votesLabel = makeLabel(font: .MVFont(.footnote), color: .MVColor(.textSecondary))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with rating: MovieDetailModel.DisplayedRating) {
        scoreLabel.text = rating.score
        votesLabel.text = rating.votes
        accessibilityLabel = rating.accessibilityLabel
    }
}

// MARK: - Layout
private extension MovieDetailRatingCell {
    func setUpLayout() {
        isAccessibilityElement = true
        let stack = UIStackView(arrangedSubviews: [starView, scoreLabel, votesLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Spacing.xSmall
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func makeStarView() -> UIImageView {
        let configuration = UIImage.SymbolConfiguration(textStyle: .subheadline)
        let imageView = UIImageView(image: UIImage(systemName: "star.fill", withConfiguration: configuration))
        imageView.tintColor = .MVColor(.ratingGold)
        imageView.adjustsImageSizeForAccessibilityContentSizeCategory = true
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        return imageView
    }

    func makeLabel(font: UIFont, color: UIColor) -> UILabel {
        let label = UILabel()
        label.font = font
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.numberOfLines = 0
        return label
    }
}
