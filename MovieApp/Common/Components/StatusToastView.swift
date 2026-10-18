import MovieAppDS
import UIKit

final class StatusToastView: UIView {
    private let visibleDuration = Duration.seconds(3)
    private let slideDistance: CGFloat = 24
    private var dismissTask: Task<Void, Never>?

    private lazy var backgroundView = makeBackgroundView()
    private lazy var iconView = makeIconView()
    private lazy var messageLabel = makeMessageLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    isolated deinit {
        dismissTask?.cancel()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    func show(message: String, in container: UIView) {
        messageLabel.text = message
        accessibilityLabel = message
        if superview !== container {
            attach(to: container)
        }
        container.bringSubviewToFront(self)
        animate(isVisible: true)
        UIAccessibility.post(notification: .announcement, argument: message)
        dismissTask?.cancel()
        dismissTask = Task { [weak self, visibleDuration] in
            try? await Task.sleep(for: visibleDuration)
            guard !Task.isCancelled else { return }
            self?.hide()
        }
    }
}

private extension StatusToastView {
    func hide() {
        dismissTask?.cancel()
        animate(isVisible: false)
    }

    func animate(isVisible: Bool) {
        let slidesIn = !UIAccessibility.isReduceMotionEnabled
        let hiddenTransform = slidesIn ? CGAffineTransform(translationX: 0, y: slideDistance) : .identity
        if isVisible, alpha == 0 {
            transform = hiddenTransform
        }
        UIView.animate(withDuration: 0.25, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            self.alpha = isVisible ? 1 : 0
            self.transform = isVisible ? .identity : hiddenTransform
        }
    }

    func attach(to container: UIView) {
        removeFromSuperview()
        translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(self)
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: container.centerXAnchor),
            leadingAnchor.constraint(greaterThanOrEqualTo: container.layoutMarginsGuide.leadingAnchor),
            trailingAnchor.constraint(lessThanOrEqualTo: container.layoutMarginsGuide.trailingAnchor),
            bottomAnchor.constraint(equalTo: container.safeAreaLayoutGuide.bottomAnchor, constant: -Spacing.medium)
        ])
    }
}

// MARK: - Layout
private extension StatusToastView {
    func setUpLayout() {
        alpha = 0
        clipsToBounds = true
        isAccessibilityElement = true
        accessibilityTraits = .staticText
        let stack = UIStackView(arrangedSubviews: [iconView, messageLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Spacing.xSmall
        [backgroundView, stack].forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subview)
        }
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.small),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.medium),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.medium),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.small)
        ])
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    @objc func handleTap() {
        hide()
    }

    func makeBackgroundView() -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    }

    func makeIconView() -> UIImageView {
        let imageView = UIImageView(image: UIImage(systemName: "exclamationmark.circle.fill"))
        imageView.tintColor = .systemRed
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .body)
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return imageView
    }

    func makeMessageLabel() -> UILabel {
        let label = UILabel()
        label.font = .MVFont(.label)
        label.textColor = .MVColor(.textPrimary)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        return label
    }
}
