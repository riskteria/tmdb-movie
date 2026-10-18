import MovieAppDS
import UIKit

final class ProfileAccountCell: UICollectionViewListCell {
    private let avatarSize: CGFloat = 52

    private lazy var avatarView = ArtworkView(placeholderLayout: .centered)
    private lazy var nameLabel = makeLabel(font: .MVFont(.body), color: .MVColor(.textPrimary))
    private lazy var usernameLabel = makeLabel(font: .MVFont(.footnote), color: .MVColor(.textSecondary))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(name: String, username: String, avatar: DisplayedArtwork, imageLoader: any IImageLoader) {
        nameLabel.text = name
        usernameLabel.text = username
        avatarView.configure(with: avatar, imageLoader: imageLoader)
        accessibilityLabel = name
        accessibilityValue = username
    }
}

// MARK: - Layout
private extension ProfileAccountCell {
    func setUpLayout() {
        isAccessibilityElement = true
        avatarView.layer.cornerRadius = avatarSize / 2
        let textStack = UIStackView(arrangedSubviews: [nameLabel, usernameLabel])
        textStack.axis = .vertical
        textStack.spacing = Spacing.xxSmall
        let rowStack = UIStackView(arrangedSubviews: [avatarView, textStack])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = Spacing.medium
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rowStack)
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: avatarSize),
            avatarView.heightAnchor.constraint(equalToConstant: avatarSize),
            rowStack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            rowStack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            rowStack.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            separatorLayoutGuide.leadingAnchor.constraint(equalTo: textStack.leadingAnchor)
        ])
    }

    func makeLabel(font: UIFont, color: UIColor) -> UILabel {
        let label = UILabel()
        label.font = font
        label.textColor = color
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }
}
