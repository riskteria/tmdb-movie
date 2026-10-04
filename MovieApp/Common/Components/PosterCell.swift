import MovieAppDS
import UIKit

final class PosterCell: UICollectionViewCell {
    private(set) lazy var artworkView = makeArtworkView()
    private lazy var playBadge = PlayBadgeView()
    private lazy var ratingBadge = RatingBadgeView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        title: String,
        artwork: DisplayedArtwork,
        showsPlayBadge: Bool,
        rating: String? = nil,
        imageLoader: any ImageLoading
    ) {
        artworkView.configure(with: artwork, imageLoader: imageLoader)
        playBadge.isHidden = !showsPlayBadge
        ratingBadge.configure(rating: rating)
        accessibilityLabel = title
        accessibilityValue = rating
    }
}

// MARK: - Layout
private extension PosterCell {
    func setUpLayout() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        [artworkView, playBadge, ratingBadge].forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(subview)
        }
        NSLayoutConstraint.activate([
            artworkView.topAnchor.constraint(equalTo: contentView.topAnchor),
            artworkView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            artworkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            artworkView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            playBadge.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xSmall),
            playBadge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.xSmall),
            ratingBadge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.xSmall),
            ratingBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xSmall)
        ])
    }

    func makeArtworkView() -> ArtworkView {
        let artworkView = ArtworkView()
        artworkView.layer.cornerRadius = Radius.medium
        artworkView.layer.cornerCurve = .continuous
        return artworkView
    }
}
