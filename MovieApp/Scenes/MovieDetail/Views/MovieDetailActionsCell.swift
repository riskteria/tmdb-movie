import MovieAppDS
import UIKit

protocol MovieDetailActionsCellDelegate: AnyObject {
    func movieDetailActionsCellDidTapSave(_ cell: MovieDetailActionsCell)
    func movieDetailActionsCellDidTapShare(_ cell: MovieDetailActionsCell)
}

final class MovieDetailActionsCell: UICollectionViewCell {
    private let styleChangeDuration = 0.2
    private let savedTintAlpha = 0.18
    private lazy var saveButton = makeSaveButton()
    private(set) lazy var shareButton = makeShareButton()
    private lazy var buttonStack = makeButtonStack()

    weak var delegate: (any MovieDetailActionsCellDelegate)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(savedState: MovieDetailModel.ObserveSavedState.ViewData?, shareTitle: String, animated: Bool) {
        shareButton.configuration?.title = shareTitle
        switch savedState {
        case nil:
            saveButton.isHidden = false
            saveButton.alpha = 0
            saveButton.isEnabled = false
            saveButton.isAccessibilityElement = false
        case .hidden:
            saveButton.isHidden = true
            saveButton.isEnabled = false
        case let .visible(title, isSaved):
            saveButton.isHidden = false
            showSave(title: title, isSaved: isSaved, animated: animated)
        }
    }
}

private extension MovieDetailActionsCell {
    func showSave(title: String, isSaved: Bool, animated: Bool) {
        saveButton.isEnabled = true
        saveButton.isAccessibilityElement = true
        saveButton.accessibilityTraits = isSaved ? [.button, .selected] : .button
        guard animated, !UIAccessibility.isReduceMotionEnabled else {
            applySaveState(title: title, isSaved: isSaved)
            return
        }
        let options: UIView.AnimationOptions = .transitionCrossDissolve
        UIView.transition(with: saveButton, duration: styleChangeDuration, options: options) { [self] in
            applySaveState(title: title, isSaved: isSaved)
        }
    }

    func applySaveState(title: String, isSaved: Bool) {
        saveButton.configuration = makeSaveConfiguration(title: title, isSaved: isSaved)
        saveButton.alpha = 1
    }

    func updateAxis() {
        let isStacked = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        buttonStack.axis = isStacked ? .vertical : .horizontal
    }

    func makeSaveConfiguration(title: String, isSaved: Bool) -> UIButton.Configuration {
        var configuration = makeActionConfiguration(systemImage: isSaved ? "bookmark.fill" : "bookmark")
        configuration.title = title
        if isSaved {
            configuration.baseForegroundColor = .MVColor(.brand)
            configuration.background.backgroundColor = UIColor.MVColor(.brand).withAlphaComponent(savedTintAlpha)
        }
        return configuration
    }

    func makeActionConfiguration(systemImage: String) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.tinted()
        configuration.image = UIImage(systemName: systemImage)
        configuration.imagePadding = Spacing.xSmall
        configuration.cornerStyle = .large
        configuration.baseForegroundColor = .MVColor(.textPrimary)
        configuration.background.backgroundColor = .MVColor(.fillPrimary)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = UIFont.MVFont(.label)
            return attributes
        }
        return configuration
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
            buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        updateAxis()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (cell: MovieDetailActionsCell, _) in
            cell.updateAxis()
        }
    }

    func makeButtonStack() -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [saveButton, shareButton])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = Spacing.small
        return stack
    }

    func makeSaveButton() -> UIButton {
        let action = UIAction { [weak self] _ in
            guard let self else { return }
            delegate?.movieDetailActionsCellDidTapSave(self)
        }
        let button = UIButton(configuration: makeSaveConfiguration(title: "", isSaved: false), primaryAction: action)
        button.alpha = 0
        button.isEnabled = false
        return button
    }

    func makeShareButton() -> UIButton {
        let action = UIAction { [weak self] _ in
            guard let self else { return }
            delegate?.movieDetailActionsCellDidTapShare(self)
        }
        let configuration = makeActionConfiguration(systemImage: "square.and.arrow.up")
        return UIButton(configuration: configuration, primaryAction: action)
    }
}
