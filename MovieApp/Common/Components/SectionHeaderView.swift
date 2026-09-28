import UIKit

final class SectionHeaderView: UICollectionReusableView {
    private lazy var titleLabel = makeTitleLabel()
    private lazy var countLabel = makeCountLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, count: String? = nil) {
        titleLabel.text = title
        countLabel.text = count
        countLabel.isHidden = count == nil
    }
}

// MARK: - Layout
private extension SectionHeaderView {
    func setUpLayout() {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, countLabel])
        stackView.axis = .horizontal
        stackView.alignment = .firstBaseline
        stackView.spacing = Spacing.xSmall
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = Typography.sectionTitle
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .textPrimary
        label.accessibilityTraits = .header
        return label
    }

    func makeCountLabel() -> UILabel {
        let label = UILabel()
        label.font = Typography.footnote
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .textSecondary
        return label
    }
}
