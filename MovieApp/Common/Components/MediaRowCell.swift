import MovieAppDS
import UIKit

// A list row: a 16:9 thumbnail, the title, and a "year • ★ rating" line.
final class MediaRowCell: UICollectionViewListCell {
    private(set) lazy var artworkView = makeArtworkView()
    private lazy var titleLabel = makeTitleLabel()
    private lazy var metadataLabel = makeMetadataLabel()
    private lazy var separatorDot = makeSeparatorDot()
    private lazy var starView = makeStarView()
    private lazy var ratingLabel = makeMetadataLabel()
    private lazy var playBadge = PlayBadgeView()

    var showsPlayBadge = false {
        didSet {
            playBadge.isHidden = !showsPlayBadge
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        title: String,
        metadata: String,
        rating: String?,
        artwork: DisplayedArtwork,
        imageLoader: any IImageLoader
    ) {
        titleLabel.text = title
        metadataLabel.text = metadata
        ratingLabel.text = rating
        [separatorDot, starView, ratingLabel].forEach { view in view.isHidden = rating == nil }
        artworkView.configure(with: artwork, imageLoader: imageLoader)
        accessibilityLabel = title
        accessibilityValue = [metadata, rating].compactMap(\.self).joined(separator: ", ")
    }
}

// MARK: - Layout
private extension MediaRowCell {
    func setUpLayout() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        let metadataStack = UIStackView(arrangedSubviews: [metadataLabel, separatorDot, starView, ratingLabel])
        metadataStack.axis = .horizontal
        metadataStack.alignment = .center
        metadataStack.spacing = 5
        let textStack = UIStackView(arrangedSubviews: [titleLabel, metadataStack])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = Spacing.xxSmall
        [artworkView, textStack, playBadge].forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(subview)
        }
        playBadge.isHidden = true
        updateTitleLineLimit()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (cell: MediaRowCell, _) in
            cell.updateTitleLineLimit()
        }
        NSLayoutConstraint.activate([
            artworkView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 9),
            artworkView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -9),
            artworkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            artworkView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.large),
            artworkView.widthAnchor.constraint(equalToConstant: 128),
            artworkView.heightAnchor.constraint(equalTo: artworkView.widthAnchor, multiplier: 9.4 / 16.0),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 9),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -9),
            textStack.leadingAnchor.constraint(equalTo: artworkView.trailingAnchor, constant: 14),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.large),
            textStack.centerYAnchor.constraint(equalTo: artworkView.centerYAnchor),
            separatorDot.widthAnchor.constraint(equalToConstant: 3),
            separatorDot.heightAnchor.constraint(equalToConstant: 3),
            playBadge.leadingAnchor.constraint(equalTo: artworkView.leadingAnchor, constant: Spacing.xSmall),
            playBadge.bottomAnchor.constraint(equalTo: artworkView.bottomAnchor, constant: -Spacing.xSmall)
        ])
    }

    func updateTitleLineLimit() {
        titleLabel.numberOfLines = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 0 : 1
    }

    func makeArtworkView() -> ArtworkView {
        let artworkView = ArtworkView()
        artworkView.layer.cornerRadius = Radius.small
        artworkView.layer.cornerCurve = .continuous
        return artworkView
    }

    func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = .MVFont(.rowTitle)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .MVColor(.textPrimary)
        return label
    }

    func makeMetadataLabel() -> UILabel {
        let label = UILabel()
        label.font = .MVFont(.caption)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .MVColor(.textSecondary)
        return label
    }

    func makeSeparatorDot() -> UIView {
        let view = UIView()
        view.backgroundColor = .MVColor(.textSecondary)
        view.layer.cornerRadius = 1.5
        return view
    }

    func makeStarView() -> UIImageView {
        let configuration = UIImage.SymbolConfiguration(textStyle: .caption2)
        let imageView = UIImageView(image: UIImage(systemName: "star.fill", withConfiguration: configuration))
        imageView.tintColor = .MVColor(.ratingGold)
        return imageView
    }
}
