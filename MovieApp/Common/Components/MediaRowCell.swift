import UIKit

// A list row: a 16:9 thumbnail, the title, and a "year • ★ rating" line.
final class MediaRowCell: UICollectionViewListCell {
    private(set) lazy var artworkView = makeArtworkView()
    private lazy var titleLabel = makeTitleLabel()
    private lazy var metadataLabel = makeMetadataLabel()
    private lazy var separatorDot = makeSeparatorDot()
    private lazy var starView = makeStarView()
    private lazy var ratingLabel = makeMetadataLabel()

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
        imageLoader: any ImageLoading
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
        [artworkView, textStack].forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(subview)
        }
        NSLayoutConstraint.activate([
            artworkView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 9),
            artworkView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -9),
            artworkView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.large),
            artworkView.widthAnchor.constraint(equalToConstant: 128),
            artworkView.heightAnchor.constraint(equalTo: artworkView.widthAnchor, multiplier: 9.4 / 16.0),
            textStack.leadingAnchor.constraint(equalTo: artworkView.trailingAnchor, constant: 14),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.large),
            textStack.centerYAnchor.constraint(equalTo: artworkView.centerYAnchor),
            separatorDot.widthAnchor.constraint(equalToConstant: 3),
            separatorDot.heightAnchor.constraint(equalToConstant: 3)
        ])
    }

    func makeArtworkView() -> ArtworkView {
        let artworkView = ArtworkView()
        artworkView.layer.cornerRadius = Radius.small
        artworkView.layer.cornerCurve = .continuous
        return artworkView
    }

    func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = Typography.rowTitle
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .textPrimary
        return label
    }

    func makeMetadataLabel() -> UILabel {
        let label = UILabel()
        label.font = Typography.caption
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .textSecondary
        return label
    }

    func makeSeparatorDot() -> UIView {
        let view = UIView()
        view.backgroundColor = .textSecondary
        view.layer.cornerRadius = 1.5
        return view
    }

    func makeStarView() -> UIImageView {
        let configuration = UIImage.SymbolConfiguration(textStyle: .caption2)
        let imageView = UIImageView(image: UIImage(systemName: "star.fill", withConfiguration: configuration))
        imageView.tintColor = .ratingGold
        return imageView
    }
}
