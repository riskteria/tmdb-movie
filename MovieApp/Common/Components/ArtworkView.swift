import MovieAppDS
import UIKit

// Shows a generated gradient (with an optional title) until the image loads. Loading starts on the
// first layout pass, so the request is downsampled to the view's real size.
final class ArtworkView: UIView {
    private var artwork: DisplayedArtwork?
    private var imageLoader: (any IImageLoader)?
    private var loadTask: Task<Void, Never>?

    private lazy var placeholderView = GradientView()
    private lazy var placeholderLabel = makePlaceholderLabel()
    private lazy var imageView = makeImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    isolated deinit {
        loadTask?.cancel()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        loadImageIfNeeded()
    }

    func configure(with artwork: DisplayedArtwork, imageLoader: any IImageLoader) {
        guard artwork != self.artwork else { return }
        loadTask?.cancel()
        loadTask = nil
        self.artwork = artwork
        self.imageLoader = imageLoader
        imageView.image = nil
        placeholderView.setColors(ArtworkPalette.placeholderColors(seed: artwork.placeholderSeed), isDiagonal: true)
        placeholderLabel.text = artwork.placeholderTitle?.uppercased()
        updatePlaceholderVisibility()
        setNeedsLayout()
    }
}

private extension ArtworkView {
    func loadImageIfNeeded() {
        guard loadTask == nil, let url = artwork?.url, let imageLoader, !bounds.isEmpty else { return }
        let targetSize = bounds.size
        loadTask = Task { [weak self] in
            let image = try? await imageLoader.image(for: url, targetSize: targetSize)
            guard let self, let image, !Task.isCancelled else { return }
            UIView.transition(with: imageView, duration: 0.2, options: .transitionCrossDissolve) { [imageView] in
                imageView.image = image
            }
            updatePlaceholderVisibility()
        }
    }

    func updatePlaceholderVisibility() {
        let hasImage = imageView.image != nil
        placeholderView.isHidden = hasImage
        placeholderLabel.isHidden = hasImage || placeholderLabel.text == nil
    }
}

// MARK: - Layout
private extension ArtworkView {
    func setUpLayout() {
        backgroundColor = .MVColor(.fillPrimary)
        clipsToBounds = true
        isAccessibilityElement = false
        [placeholderView, placeholderLabel, imageView].forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subview)
        }
        NSLayoutConstraint.activate([
            placeholderView.topAnchor.constraint(equalTo: topAnchor),
            placeholderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            placeholderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            placeholderView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.small),
            placeholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.small),
            placeholderLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.small)
        ])
    }

    func makePlaceholderLabel() -> UILabel {
        let label = UILabel()
        label.font = .MVFont(.artworkTitle)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .white
        label.numberOfLines = 3
        return label
    }

    func makeImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }
}
