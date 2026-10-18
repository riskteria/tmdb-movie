import MovieAppDS
import UIKit

final class CastMemberCell: UICollectionViewCell {
    private let avatarSize: CGFloat = 64
    private let nameLineCount = 2

    private lazy var avatarView = ArtworkView(placeholderLayout: .centered)
    private lazy var nameLabel = makeLabel(color: .MVColor(.textPrimary))
    private lazy var characterLabel = makeLabel(color: .MVColor(.textSecondary))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with member: MovieDetailModel.DisplayedCastMember, imageLoader: any IImageLoader) {
        nameLabel.text = member.name
        characterLabel.text = member.character
        avatarView.configure(with: member.artwork, imageLoader: imageLoader)
        accessibilityLabel = member.name
        accessibilityValue = member.character
    }
}

private extension CastMemberCell {
    func updateLineLimits() {
        let isAccessibilitySize = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        nameLabel.numberOfLines = isAccessibilitySize ? 0 : nameLineCount
        characterLabel.numberOfLines = isAccessibilitySize ? 0 : 1
    }
}

// MARK: - Layout
private extension CastMemberCell {
    func setUpLayout() {
        isAccessibilityElement = true
        avatarView.layer.cornerRadius = avatarSize / 2
        let stack = UIStackView(arrangedSubviews: [avatarView, nameLabel, characterLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Spacing.xxSmall
        stack.setCustomSpacing(Spacing.xSmall, after: avatarView)
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: avatarSize),
            avatarView.heightAnchor.constraint(equalToConstant: avatarSize),
            nameLabel.widthAnchor.constraint(equalTo: stack.widthAnchor),
            characterLabel.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
        updateLineLimits()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (cell: CastMemberCell, _) in
            cell.updateLineLimits()
        }
    }

    func makeLabel(color: UIColor) -> UILabel {
        let label = UILabel()
        label.font = .MVFont(.caption)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.textAlignment = .center
        return label
    }
}
