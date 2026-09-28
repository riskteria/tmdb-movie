import UIKit

extension UIContentUnavailableConfiguration {
    static func failure(
        message: String,
        retryTitle: String,
        retry: @escaping @MainActor () -> Void
    ) -> UIContentUnavailableConfiguration {
        var configuration = UIContentUnavailableConfiguration.empty()
        configuration.image = UIImage(systemName: "exclamationmark.triangle")
        configuration.text = message
        configuration.textProperties.font = Typography.sectionTitle
        configuration.button = .brandFilled()
        configuration.button.title = retryTitle
        configuration.buttonProperties.primaryAction = UIAction { _ in retry() }
        return configuration
    }

    static func message(_ text: String, secondaryText: String? = nil, systemImage: String) -> UIContentUnavailableConfiguration {
        var configuration = UIContentUnavailableConfiguration.empty()
        configuration.image = UIImage(systemName: systemImage)
        configuration.imageProperties.tintColor = .brand
        configuration.text = text
        configuration.textProperties.font = Typography.sectionTitle
        configuration.secondaryText = secondaryText
        configuration.secondaryTextProperties.font = Typography.body
        return configuration
    }
}
