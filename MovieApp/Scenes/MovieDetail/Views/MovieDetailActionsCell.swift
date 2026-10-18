import MovieAppDS
import UIKit

protocol MovieDetailActionsCellDelegate: AnyObject {
    func movieDetailActionsCellDidTapShare(_ cell: MovieDetailActionsCell)
}

final class MovieDetailActionsCell: UICollectionViewCell {
    private(set) lazy var shareButton = makeShareButton()
    private lazy var buttonStack = makeButtonStack()
    private lazy var naturalWidthConstraint = buttonStack.trailingAnchor.constraint(
        lessThanOrEqualTo: contentView.trailingAnchor
    )
    private lazy var fullWidthConstraint = buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)

    weak var delegate: (any MovieDetailActionsCellDelegate)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(shareTitle: String) {
        shareButton.configuration?.title = shareTitle
    }
}

private extension MovieDetailActionsCell {
    func updateRowWidth() {
        let fillsRow = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        naturalWidthConstraint.isActive = !fillsRow
        fullWidthConstraint.isActive = fillsRow
    }
}

// MARK: - Layout
private extension MovieDetailActionsCell {
    func setUpLayout() {
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(buttonStack)
        NSLayoutConstraint.activate([
            buttonStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            buttonStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        updateRowWidth()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (cell: MovieDetailActionsCell, _) in
            cell.updateRowWidth()
        }
    }

    func makeButtonStack() -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [shareButton])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = Spacing.small
        return stack
    }

    func makeShareButton() -> UIButton {
        var configuration = UIButton.Configuration.tinted()
        configuration.image = UIImage(systemName: "square.and.arrow.up")
        configuration.imagePadding = Spacing.xSmall
        configuration.cornerStyle = .large
        configuration.baseForegroundColor = .MVColor(.textPrimary)
        configuration.background.backgroundColor = .MVColor(.fillPrimary)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = UIFont.MVFont(.label)
            return attributes
        }
        let action = UIAction { [weak self] _ in
            guard let self else { return }
            delegate?.movieDetailActionsCellDidTapShare(self)
        }
        return UIButton(configuration: configuration, primaryAction: action)
    }
}
