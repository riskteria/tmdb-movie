import MovieAppDS
import UIKit

final class MovieDetailView: UIView {
    private static let headerAspectRatio: CGFloat = 1.25
    private static let maximumHeaderHeight: CGFloat = 560

    private lazy var scrollView = makeScrollView()
    private lazy var headerView = UIView()
    private lazy var artworkView = ArtworkView()
    private lazy var scrimView = makeScrimView()
    private lazy var titleLabel = makeLabel(font: .MVFont(.display), color: .white)
    private lazy var metadataLabel = makeLabel(font: .MVFont(.footnote), color: UIColor.white.withAlphaComponent(0.86))
    private lazy var overviewLabel = makeLabel(font: .MVFont(.body), color: .MVColor(.textSecondary))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        scrollView.contentInset.bottom = safeAreaInsets.bottom
        scrollView.verticalScrollIndicatorInsets.bottom = safeAreaInsets.bottom
    }

    func configure(with detail: MovieDetailModel.DisplayedDetail, imageLoader: any ImageLoading) {
        titleLabel.text = detail.title
        metadataLabel.text = detail.metadata
        overviewLabel.text = detail.overview
        artworkView.configure(with: detail.artwork, imageLoader: imageLoader)
        headerView.accessibilityLabel = detail.title
        headerView.accessibilityValue = detail.metadata
    }
}

// MARK: - Layout
private extension MovieDetailView {
    func setUpLayout() {
        backgroundColor = .MVColor(.backgroundPrimary)
        headerView.isAccessibilityElement = true
        headerView.accessibilityTraits = .header
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        [headerView, overviewLabel].forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(subview)
        }
        let infoStack = UIStackView(arrangedSubviews: [titleLabel, metadataLabel])
        infoStack.axis = .vertical
        infoStack.spacing = Spacing.xSmall
        [artworkView, scrimView, infoStack].forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview(subview)
        }
        let contentGuide = scrollView.contentLayoutGuide
        let frameGuide = scrollView.frameLayoutGuide
        let preferredHeight = headerView.heightAnchor.constraint(
            equalTo: frameGuide.widthAnchor,
            multiplier: Self.headerAspectRatio
        )
        preferredHeight.priority = .defaultHigh
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentGuide.widthAnchor.constraint(equalTo: frameGuide.widthAnchor),
            headerView.topAnchor.constraint(equalTo: contentGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            headerView.heightAnchor.constraint(lessThanOrEqualToConstant: Self.maximumHeaderHeight),
            preferredHeight,
            artworkView.topAnchor.constraint(equalTo: headerView.topAnchor),
            artworkView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            artworkView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            artworkView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrimView.topAnchor.constraint(equalTo: headerView.topAnchor),
            scrimView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            scrimView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            scrimView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            infoStack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: Spacing.large),
            infoStack.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -Spacing.large),
            infoStack.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -Spacing.xLarge),
            overviewLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: Spacing.large),
            overviewLabel.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor, constant: Spacing.large),
            overviewLabel.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor, constant: -Spacing.large),
            overviewLabel.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor, constant: -Spacing.xLarge)
        ])
    }

    func makeScrollView() -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        // The header runs under the navigation bar; the bottom inset follows the safe area instead.
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
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
}
