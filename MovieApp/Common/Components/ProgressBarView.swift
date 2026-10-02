import UIKit

final class ProgressBarView: UIView {
    private static let height: CGFloat = 4

    private lazy var fillView = makeFillView()

    var progress: Double = 0 {
        didSet {
            setNeedsLayout()
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Self.height)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white.withAlphaComponent(0.3)
        addSubview(fillView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width * min(max(progress, 0), 1)
        fillView.frame = CGRect(x: 0, y: 0, width: width, height: bounds.height)
    }
}

// MARK: - Layout
private extension ProgressBarView {
    func makeFillView() -> UIView {
        let view = UIView()
        view.backgroundColor = .brand
        view.layer.cornerRadius = Self.height / 2
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        return view
    }
}
