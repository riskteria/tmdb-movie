import MovieAppDS
import UIKit

protocol MovieDetailSynopsisCellDelegate: AnyObject {
    func movieDetailSynopsisCellDidTapToggle(_ cell: MovieDetailSynopsisCell)
}

final class MovieDetailSynopsisCell: UICollectionViewCell {
    private let collapsedLineCount = 3

    private lazy var overviewLabel = makeOverviewLabel()
    private lazy var toggleButton = makeToggleButton()
    private var isExpanded = false

    weak var delegate: (any MovieDetailSynopsisCellDelegate)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        toggleButton.isHidden = !isTruncated(atWidth: layoutAttributes.size.width)
        return super.preferredLayoutAttributesFitting(layoutAttributes)
    }

    func configure(text: String, isExpanded: Bool, toggleTitle: String) {
        self.isExpanded = isExpanded
        overviewLabel.text = text
        overviewLabel.numberOfLines = isExpanded ? 0 : collapsedLineCount
        toggleButton.configuration?.title = toggleTitle
    }
}

private extension MovieDetailSynopsisCell {
    func isTruncated(atWidth width: CGFloat) -> Bool {
        guard let text = overviewLabel.text, let font = overviewLabel.font, width > 0 else { return false }
        let fullHeight = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).height
        return fullHeight > font.lineHeight * CGFloat(collapsedLineCount) + 1
    }
}

// MARK: - Layout
private extension MovieDetailSynopsisCell {
    func setUpLayout() {
        let stack = UIStackView(arrangedSubviews: [overviewLabel, toggleButton])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = Spacing.xxSmall
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            overviewLabel.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    func makeOverviewLabel() -> UILabel {
        let label = UILabel()
        label.font = .MVFont(.body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .MVColor(.textSecondary)
        label.numberOfLines = collapsedLineCount
        label.lineBreakMode = .byTruncatingTail
        return label
    }

    func makeToggleButton() -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .MVColor(.brand)
        configuration.contentInsets = .zero
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = UIFont.MVFont(.label)
            return attributes
        }
        let action = UIAction { [weak self] _ in
            guard let self else { return }
            delegate?.movieDetailSynopsisCellDidTapToggle(self)
        }
        return UIButton(configuration: configuration, primaryAction: action)
    }
}
