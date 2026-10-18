import MovieAppDS
import UIKit

protocol MovieDetailHeaderCellDelegate: AnyObject {
    func movieDetailHeaderCellDidTapWatch(_ cell: MovieDetailHeaderCell)
}

final class MovieDetailHeaderCell: UICollectionViewCell {
    private let heroAspectRatio: CGFloat = 1.25
    private let maximumHeroHeight: CGFloat = 560
    private let maximumWatchWidth: CGFloat = 480
    private let minimumTopClearance: CGFloat = 96

    private lazy var artworkView = ArtworkView()
    private lazy var scrimView = makeScrimView()
    private lazy var titleLabel = makeLabel(font: .MVFont(.display), color: .white)
    private lazy var metadataLabel = makeLabel(font: .MVFont(.footnote), color: UIColor.white.withAlphaComponent(0.86))
    private lazy var watchButton = makeWatchButton()

    weak var delegate: (any MovieDetailHeaderCellDelegate)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with detail: MovieDetailModel.DisplayedDetail, watchTitle: String, imageLoader: any IImageLoader) {
        watchButton.configuration?.title = watchTitle
        titleLabel.text = detail.title
        titleLabel.accessibilityLabel = detail.title
        titleLabel.accessibilityValue = detail.metadata
        metadataLabel.text = detail.metadata
        artworkView.configure(with: detail.artwork, imageLoader: imageLoader)
        updateWatchButton(for: detail.watch)
    }

    func applyParallax(offset: CGFloat) {
        let transform = CGAffineTransform.parallax(offset: offset, height: bounds.height)
        artworkView.transform = transform
        scrimView.transform = transform
        clipsToBounds = offset >= 0
        contentView.clipsToBounds = offset >= 0
    }
}

private extension MovieDetailHeaderCell {
    func updateWatchButton(for watch: MovieDetailModel.WatchAvailability) {
        switch watch {
        case .pending:
            watchButton.isHidden = false
            watchButton.alpha = 0
            watchButton.isEnabled = false
        case .available:
            watchButton.isHidden = false
            watchButton.alpha = 1
            watchButton.isEnabled = true
        case .unavailable:
            watchButton.isHidden = true
        }
        watchButton.isAccessibilityElement = watchButton.isEnabled && !watchButton.isHidden
    }
}

// MARK: - Layout
private extension MovieDetailHeaderCell {
    func setUpLayout() {
        isAccessibilityElement = false
        titleLabel.accessibilityTraits = .header
        metadataLabel.isAccessibilityElement = false
        accessibilityElements = [titleLabel, watchButton]
        let infoStack = UIStackView(arrangedSubviews: [titleLabel, metadataLabel, watchButton])
        infoStack.axis = .vertical
        infoStack.alignment = .leading
        infoStack.spacing = Spacing.xSmall
        infoStack.setCustomSpacing(Spacing.medium, after: metadataLabel)
        [artworkView, scrimView, infoStack].forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(subview)
        }
        let preferredHeight = contentView.heightAnchor.constraint(
            equalTo: contentView.widthAnchor,
            multiplier: heroAspectRatio
        )
        preferredHeight.priority = .defaultHigh
        let cappedHeight = contentView.heightAnchor.constraint(lessThanOrEqualToConstant: maximumHeroHeight)
        cappedHeight.priority = .required - 1
        let fullWidthWatch = watchButton.widthAnchor.constraint(equalTo: infoStack.widthAnchor)
        fullWidthWatch.priority = .defaultHigh
        NSLayoutConstraint.activate([
            preferredHeight,
            cappedHeight,
            artworkView.topAnchor.constraint(equalTo: contentView.topAnchor),
            artworkView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            artworkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            artworkView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            scrimView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrimView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrimView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrimView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            infoStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: minimumTopClearance),
            infoStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.large),
            infoStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.large),
            infoStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.xLarge),
            titleLabel.widthAnchor.constraint(equalTo: infoStack.widthAnchor),
            metadataLabel.widthAnchor.constraint(equalTo: infoStack.widthAnchor),
            fullWidthWatch,
            watchButton.widthAnchor.constraint(lessThanOrEqualToConstant: maximumWatchWidth)
        ])
    }

    func makeScrimView() -> GradientView {
        let view = GradientView()
        view.setColors(
            [
                UIColor.black.withAlphaComponent(0.35),
                .clear,
                .clear,
                UIColor.black.withAlphaComponent(0.88)
            ],
            locations: [0, 0.22, 0.42, 1]
        )
        return view
    }

    func makeLabel(font: UIFont, color: UIColor) -> UILabel {
        let label = UILabel()
        label.font = font
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.numberOfLines = 0
        return label
    }

    func makeWatchButton() -> UIButton {
        var configuration = UIButton.Configuration.brandFilled()
        configuration.image = UIImage(systemName: "play.fill")
        configuration.imagePadding = Spacing.xSmall
        let action = UIAction { [weak self] _ in
            guard let self else { return }
            delegate?.movieDetailHeaderCellDidTapWatch(self)
        }
        return UIButton(configuration: configuration, primaryAction: action)
    }
}
