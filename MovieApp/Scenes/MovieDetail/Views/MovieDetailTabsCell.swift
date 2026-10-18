import MovieAppDS
import UIKit

protocol MovieDetailTabsCellDelegate: AnyObject {
    func movieDetailTabsCell(_ cell: MovieDetailTabsCell, didSelectTabAt index: Int)
}

final class MovieDetailTabsCell: UICollectionViewCell {
    private let underlineHeight: CGFloat = 2
    private let hairlineHeight: CGFloat = 0.5

    private lazy var tabStack = makeTabStack()
    private lazy var hairlineView = makeHairlineView()
    private lazy var underlineView = makeUnderlineView()
    private var tabButtons: [UIButton] = []
    private var underlineConstraints: [NSLayoutConstraint] = []
    private var selectedIndex: Int?

    weak var delegate: (any MovieDetailTabsCellDelegate)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(titles: [String], selectedIndex: Int) {
        if titles != tabButtons.map({ $0.configuration?.title ?? "" }) {
            makeTabButtons(titles: titles)
        }
        let isChangingTab = self.selectedIndex != nil && self.selectedIndex != selectedIndex
        self.selectedIndex = selectedIndex
        for (index, button) in tabButtons.enumerated() {
            let isSelected = index == selectedIndex
            button.accessibilityTraits = isSelected ? [.button, .selected] : .button
            button.configuration?.baseForegroundColor = .MVColor(isSelected ? .brand : .textSecondary)
        }
        moveUnderline(animated: isChangingTab && window != nil && !UIAccessibility.isReduceMotionEnabled)
    }
}

private extension MovieDetailTabsCell {
    func makeTabButtons(titles: [String]) {
        tabButtons.forEach { $0.removeFromSuperview() }
        tabButtons = titles.enumerated().map { index, title in makeTabButton(title: title, index: index) }
        tabButtons.forEach { tabStack.addArrangedSubview($0) }
        tabStack.accessibilityElements = tabButtons
    }

    func moveUnderline(animated: Bool) {
        guard let selectedIndex, tabButtons.indices.contains(selectedIndex) else { return }
        let selectedButton = tabButtons[selectedIndex]
        NSLayoutConstraint.deactivate(underlineConstraints)
        underlineConstraints = [
            underlineView.leadingAnchor.constraint(equalTo: selectedButton.leadingAnchor),
            underlineView.widthAnchor.constraint(equalTo: selectedButton.widthAnchor)
        ]
        NSLayoutConstraint.activate(underlineConstraints)
        guard animated else { return }
        UIView.animate(withDuration: 0.2) { [contentView] in
            contentView.layoutIfNeeded()
        }
    }
}

// MARK: - Layout
private extension MovieDetailTabsCell {
    func setUpLayout() {
        [tabStack, hairlineView, underlineView].forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(subview)
        }
        NSLayoutConstraint.activate([
            tabStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            tabStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tabStack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            hairlineView.topAnchor.constraint(equalTo: tabStack.bottomAnchor),
            hairlineView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hairlineView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hairlineView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            hairlineView.heightAnchor.constraint(equalToConstant: hairlineHeight),
            underlineView.bottomAnchor.constraint(equalTo: hairlineView.bottomAnchor),
            underlineView.heightAnchor.constraint(equalToConstant: underlineHeight)
        ])
    }

    func makeTabStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .bottom
        stack.spacing = Spacing.xLarge
        stack.accessibilityTraits = .tabBar
        return stack
    }

    func makeTabButton(title: String, index: Int) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.titleLineBreakMode = .byWordWrapping
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: Spacing.small,
            leading: 0,
            bottom: Spacing.small,
            trailing: 0
        )
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = UIFont.MVFont(.label)
            return attributes
        }
        let action = UIAction { [weak self] _ in
            guard let self else { return }
            delegate?.movieDetailTabsCell(self, didSelectTabAt: index)
        }
        return UIButton(configuration: configuration, primaryAction: action)
    }

    func makeHairlineView() -> UIView {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }

    func makeUnderlineView() -> UIView {
        let view = UIView()
        view.backgroundColor = .MVColor(.brand)
        view.layer.cornerRadius = underlineHeight / 2
        return view
    }
}
