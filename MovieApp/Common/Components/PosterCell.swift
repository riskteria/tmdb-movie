import MovieAppDS
import UIKit

final class PosterCell: UICollectionViewCell {
    private(set) lazy var artworkView = makeArtworkView()
    private lazy var playBadge = PlayBadgeView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, artwork: DisplayedArtwork, showsPlayBadge: Bool, imageLoader: any ImageLoading) {
        artworkView.configure(with: artwork, imageLoader: imageLoader)
        playBadge.isHidden = !showsPlayBadge
        accessibilityLabel = title
    }
}

// MARK: - Layout
private extension PosterCell {
    func setUpLayout() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        [artworkView, playBadge].forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(subview)
        }
        NSLayoutConstraint.activate([
            artworkView.topAnchor.constraint(equalTo: contentView.topAnchor),
            artworkView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            artworkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            artworkView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            playBadge.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xSmall),
            playBadge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.xSmall)
        ])
    }

    func makeArtworkView() -> ArtworkView {
        let artworkView = ArtworkView()
        artworkView.layer.cornerRadius = Radius.medium
        artworkView.layer.cornerCurve = .continuous
        return artworkView
    }
}
