import UIKit

final class HeroBannerCell: UICollectionViewCell {
    private(set) lazy var artworkView = ArtworkView()
    private lazy var scrimView = makeScrimView()
    private lazy var titleLabel = makeTitleLabel()
    private lazy var metadataLabel = makeMetadataLabel()
    private lazy var infoStack = makeInfoStack()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, metadata: String, artwork: DisplayedArtwork, imageLoader: any ImageLoading) {
        titleLabel.text = title
        metadataLabel.text = metadata
        artworkView.configure(with: artwork, imageLoader: imageLoader)
        accessibilityLabel = title
        accessibilityValue = metadata
    }
}

// MARK: - Layout
private extension HeroBannerCell {
    func setUpLayout() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        [artworkView, scrimView, infoStack].forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(subview)
        }
        NSLayoutConstraint.activate([
            artworkView.topAnchor.constraint(equalTo: contentView.topAnchor),
            artworkView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            artworkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            artworkView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            scrimView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrimView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrimView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrimView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            infoStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.large),
            infoStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.large),
            infoStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.xLarge * 2)
        ])
    }

    func makeScrimView() -> GradientView {
        let view = GradientView()
        view.isUserInteractionEnabled = false
        view.setColors(
            [
                UIColor.black.withAlphaComponent(0.38),
                .clear,
                .clear,
                UIColor.black.withAlphaComponent(0.82)
            ],
            locations: [0, 0.2, 0.48, 1]
        )
        return view
    }

    func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = Typography.display
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }

    func makeMetadataLabel() -> UILabel {
        let label = UILabel()
        label.font = Typography.footnote
        label.adjustsFontForContentSizeCategory = true
        label.textColor = UIColor.white.withAlphaComponent(0.86)
        label.numberOfLines = 2
        return label
    }

    func makeInfoStack() -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, metadataLabel])
        stackView.axis = .vertical
        stackView.spacing = Spacing.xSmall
        return stackView
    }
}
