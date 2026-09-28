import UIKit

final class GradientView: UIView {
    override static var layerClass: AnyClass {
        CAGradientLayer.self
    }

    func setColors(_ colors: [UIColor], locations: [Double]? = nil, isDiagonal: Bool = false) {
        guard let gradientLayer = layer as? CAGradientLayer else { return }
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.locations = locations?.map { NSNumber(value: $0) }
        gradientLayer.startPoint = isDiagonal ? CGPoint(x: 0, y: 0) : CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = isDiagonal ? CGPoint(x: 1, y: 1) : CGPoint(x: 0.5, y: 1)
    }
}
