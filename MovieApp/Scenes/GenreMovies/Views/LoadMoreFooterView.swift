import MovieAppDS
import UIKit

final class LoadMoreFooterView: UICollectionReusableView {
    private var onRetry: (() -> Void)?

    private lazy var activityIndicator = UIActivityIndicatorView(style: .medium)
    private lazy var messageLabel = makeMessageLabel()
    private lazy var retryButton = makeRetryButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with footer: GenreMoviesModel.LoadMoreFooter, retryTitle: String, onRetry: @escaping () -> Void) {
        self.onRetry = onRetry
        retryButton.configuration?.title = retryTitle
        switch footer {
        case .hidden:
            activityIndicator.stopAnimating()
            messageLabel.isHidden = true
            retryButton.isHidden = true
        case .spinner:
            activityIndicator.startAnimating()
            messageLabel.isHidden = true
            retryButton.isHidden = true
        case .retry(let message):
            activityIndicator.stopAnimating()
            messageLabel.text = message
            messageLabel.isHidden = false
            retryButton.isHidden = false
        }
    }
}

// MARK: - Layout
private extension LoadMoreFooterView {
    func setUpLayout() {
        let stackView = UIStackView(arrangedSubviews: [activityIndicator, messageLabel, retryButton])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Spacing.xSmall
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.medium),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.medium)
        ])
    }

    func makeMessageLabel() -> UILabel {
        let label = UILabel()
        label.font = .MVFont(.body)
        label.textColor = .MVColor(.textSecondary)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }

    func makeRetryButton() -> UIButton {
        UIButton(
            configuration: .brandFilled(),
            primaryAction: UIAction { [weak self] _ in self?.onRetry?() }
        )
    }
}
