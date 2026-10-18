import MovieAppDS
import UIKit

final class WelcomeView: UIView {
    private let logoSize: CGFloat = 58
    private let hairlineHeight: CGFloat = 0.5

    private lazy var scrollView = UIScrollView()
    private lazy var logoView = makeLogoView()
    private lazy var headingLabel = makeLabel(
        font: .MVFont(.display),
        color: .MVColor(.textPrimary),
        alignment: .natural
    )
    private lazy var bodyLabel = makeLabel(font: .MVFont(.body), color: .MVColor(.textSecondary), alignment: .natural)
    private lazy var signInButton = UIButton(configuration: makeSignInConfiguration())
    private lazy var separatorLabel = makeLabel(font: .MVFont(.caption), color: .tertiaryLabel)
    private lazy var continueAsGuestButton = UIButton(configuration: .neutralFilled())
    private lazy var footnoteLabel = makeLabel(font: .MVFont(.caption), color: .MVColor(.textSecondary))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        with content: WelcomeModel.DisplayedContent,
        signInAction: UIAction,
        continueAsGuestAction: UIAction
    ) {
        headingLabel.text = content.heading
        bodyLabel.text = content.body
        signInButton.configuration?.title = content.signInTitle
        separatorLabel.text = content.separatorTitle
        continueAsGuestButton.configuration?.title = content.continueAsGuestTitle
        footnoteLabel.text = content.footnote
        signInButton.addAction(signInAction, for: .primaryActionTriggered)
        continueAsGuestButton.addAction(continueAsGuestAction, for: .primaryActionTriggered)
    }

    func setActionsEnabled(_ isEnabled: Bool) {
        [signInButton, continueAsGuestButton].forEach { button in button.isEnabled = isEnabled }
    }
}

// MARK: - Layout
private extension WelcomeView {
    func setUpLayout() {
        backgroundColor = .MVColor(.backgroundPrimary)
        headingLabel.accessibilityTraits = .header
        let logoContainer = makeLogoContainer()
        let headerStack = UIStackView(arrangedSubviews: [logoContainer, headingLabel, bodyLabel])
        headerStack.axis = .vertical
        headerStack.setCustomSpacing(Spacing.large, after: logoContainer)
        headerStack.setCustomSpacing(Spacing.xSmall, after: headingLabel)
        let actionsStack = UIStackView(
            arrangedSubviews: [signInButton, makeSeparatorView(), continueAsGuestButton, footnoteLabel]
        )
        actionsStack.axis = .vertical
        actionsStack.spacing = Spacing.small
        let spacer = UIView()
        spacer.setContentHuggingPriority(UILayoutPriority(1), for: .vertical)
        spacer.setContentCompressionResistancePriority(UILayoutPriority(1), for: .vertical)
        let contentStack = UIStackView(arrangedSubviews: [headerStack, spacer, actionsStack])
        contentStack.axis = .vertical
        contentStack.spacing = Spacing.xLarge
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollView.addSubview(contentStack)
        let verticalInsets = Spacing.large + Spacing.xLarge
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            contentStack.topAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.topAnchor,
                constant: Spacing.large
            ),
            contentStack.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                constant: -Spacing.xLarge
            ),
            contentStack.leadingAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.leadingAnchor,
                constant: Spacing.xLarge
            ),
            contentStack.trailingAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.trailingAnchor,
                constant: -Spacing.xLarge
            ),
            contentStack.heightAnchor.constraint(
                greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor,
                constant: -verticalInsets
            )
        ])
    }

    func makeLogoContainer() -> UIView {
        let container = UIView()
        logoView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(logoView)
        NSLayoutConstraint.activate([
            logoView.topAnchor.constraint(equalTo: container.topAnchor),
            logoView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            logoView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            logoView.widthAnchor.constraint(equalToConstant: logoSize),
            logoView.heightAnchor.constraint(equalToConstant: logoSize)
        ])
        return container
    }

    func makeLogoView() -> UIImageView {
        let imageView = UIImageView(image: .MVImage(.logo))
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = false
        return imageView
    }

    func makeSeparatorView() -> UIView {
        let leadingLine = makeHairline()
        let trailingLine = makeHairline()
        separatorLabel.setContentHuggingPriority(.required, for: .horizontal)
        let stack = UIStackView(arrangedSubviews: [leadingLine, separatorLabel, trailingLine])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Spacing.small
        stack.accessibilityElementsHidden = true
        leadingLine.widthAnchor.constraint(equalTo: trailingLine.widthAnchor).isActive = true
        return stack
    }

    func makeHairline() -> UIView {
        let line = UIView()
        line.backgroundColor = .separator
        line.heightAnchor.constraint(equalToConstant: hairlineHeight).isActive = true
        return line
    }

    func makeSignInConfiguration() -> UIButton.Configuration {
        var configuration = UIButton.Configuration.brandFilled()
        configuration.image = UIImage(systemName: "person.badge.key")
        configuration.imagePadding = Spacing.xSmall
        return configuration
    }

    func makeLabel(font: UIFont, color: UIColor, alignment: NSTextAlignment = .center) -> UILabel {
        let label = UILabel()
        label.font = font
        label.textColor = color
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = alignment
        return label
    }
}
