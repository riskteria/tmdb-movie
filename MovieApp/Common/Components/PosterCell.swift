import MovieAppDS
import UIKit

protocol PosterCellDelegate: AnyObject {
    func posterCellDidTapBookmark(_ cell: PosterCell)
}

final class PosterCell: UICollectionViewCell {
    weak var delegate: (any PosterCellDelegate)?

    private(set) lazy var artworkView = makeArtworkView()
    private lazy var playBadge = PlayBadgeView()
    private lazy var ratingBadge = RatingBadgeView()
    private lazy var bookmarkButton = makeBookmarkButton()
    private var rating: String?
    private var savedValue: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hideBookmark()
    }

    func configure(
        title: String,
        artwork: DisplayedArtwork,
        showsPlayBadge: Bool,
        rating: String? = nil,
        imageLoader: any IImageLoader
    ) {
        artworkView.configure(with: artwork, imageLoader: imageLoader)
        playBadge.isHidden = !showsPlayBadge
        ratingBadge.configure(rating: rating)
        accessibilityLabel = title
        self.rating = rating
        updateAccessibilityValue()
    }

    func configureBookmark(_ bookmark: DisplayedBookmark?, animated: Bool) {
        if let bookmark {
            showBookmark(bookmark, animated: animated)
        } else {
            hideBookmark()
        }
    }
}

private extension PosterCell {
    func showBookmark(_ bookmark: DisplayedBookmark, animated: Bool) {
        bookmarkButton.isHidden = false
        bookmarkButton.configure(isSaved: bookmark.isSaved, animated: animated)
        savedValue = bookmark.savedValue
        accessibilityCustomActions = [makeBookmarkAction(named: bookmark.actionName)]
        updateAccessibilityValue()
    }

    func hideBookmark() {
        bookmarkButton.isHidden = true
        savedValue = nil
        accessibilityCustomActions = nil
        updateAccessibilityValue()
    }

    func updateAccessibilityValue() {
        let parts = [rating, savedValue].compactMap(\.self)
        accessibilityValue = parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    func reportBookmarkTap() {
        delegate?.posterCellDidTapBookmark(self)
    }

    func makeBookmarkAction(named name: String) -> UIAccessibilityCustomAction {
        UIAccessibilityCustomAction(name: name) { [weak self] _ in
            self?.reportBookmarkTap()
            return true
        }
    }
}

// MARK: - Layout
private extension PosterCell {
    func setUpLayout() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        [artworkView, playBadge, ratingBadge, bookmarkButton].forEach { subview in
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
            ratingBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xSmall),
            bookmarkButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.xSmall),
            bookmarkButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.xSmall)
        ])
    }

    func makeArtworkView() -> ArtworkView {
        let artworkView = ArtworkView()
        artworkView.layer.cornerRadius = Radius.medium
        artworkView.layer.cornerCurve = .continuous
        return artworkView
    }

    func makeBookmarkButton() -> BookmarkBadgeButton {
        let button = BookmarkBadgeButton()
        button.isHidden = true
        button.addAction(UIAction { [weak self] _ in self?.reportBookmarkTap() }, for: .primaryActionTriggered)
        return button
    }
}
