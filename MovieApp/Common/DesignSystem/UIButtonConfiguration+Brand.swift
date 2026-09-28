import UIKit

extension UIButton.Configuration {
    static func brandFilled() -> UIButton.Configuration {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = .brand
        configuration.baseForegroundColor = .white
        configuration.cornerStyle = .large
        configuration.buttonSize = .large
        return configuration
    }
}
