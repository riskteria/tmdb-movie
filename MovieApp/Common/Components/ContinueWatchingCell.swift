import UIKit

final class ContinueWatchingCell: UICollectionViewCell {
    private(set) lazy var artworkView = makeArtworkView()
    private lazy var playBadge = PlayBadgeView()
    private lazy var progressBar = ProgressBarView()
    private lazy var titleLabel = makeTitleLabel()
    private lazy var subtitleLabel = makeSubtitleLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        title: String,
        subtitle: String,
        progress: Double,
        artwork: DisplayedArtwork,
        imageLoader: any ImageLoading
    ) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        progressBar.progress = progress
        artworkView.configure(with: artwork, imageLoader: imageLoader)
        accessibilityLabel = title
        accessibilityValue = subtitle
    }
}

// MARK: - Layout
private extension ContinueWatchingCell {
    func setUpLayout() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        [artworkView, titleLabel, subtitleLabel].forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(subview)
        }
        [playBadge, progressBar].forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            artworkView.addSubview(subview)
        }
        NSLayoutConstraint.activate([
            artworkView.topAnchor.constraint(equalTo: contentView.topAnchor),
            artworkView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            artworkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            artworkView.heightAnchor.constraint(equalTo: artworkView.widthAnchor, multiplier: 10.0 / 16.0),
            playBadge.leadingAnchor.constraint(equalTo: artworkView.leadingAnchor, constant: Spacing.xSmall),
            playBadge.bottomAnchor.constraint(equalTo: progressBar.topAnchor, constant: -Spacing.xSmall),
            progressBar.leadingAnchor.constraint(equalTo: artworkView.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: artworkView.trailingAnchor),
            progressBar.bottomAnchor.constraint(equalTo: artworkView.bottomAnchor),
            titleLabel.topAnchor.constraint(equalTo: artworkView.bottomAnchor, constant: Spacing.xSmall),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func makeArtworkView() -> ArtworkView {
        let artworkView = ArtworkView()
        artworkView.layer.cornerRadius = Radius.medium
        artworkView.layer.cornerCurve = .continuous
        return artworkView
    }

    func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = Typography.label
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .textPrimary
        return label
    }

    func makeSubtitleLabel() -> UILabel {
        let label = UILabel()
        label.font = Typography.caption
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .textSecondary
        return label
    }
}
