import UIKit

final class GenreCardCell: UICollectionViewCell {
    private lazy var gradientView = GradientView()
    private lazy var nameLabel = makeNameLabel()
    private lazy var chevronView = makeChevronView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(name: String, genreID: Genre.ID) {
        nameLabel.text = name
        gradientView.setColors(ArtworkPalette.genreColors(genreID: genreID), isDiagonal: true)
        accessibilityLabel = name
    }
}

// MARK: - Layout
private extension GenreCardCell {
    func setUpLayout() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        contentView.layer.cornerRadius = Radius.medium
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true
        [gradientView, nameLabel, chevronView].forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(subview)
        }
        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: contentView.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.small),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.small),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.small),
            chevronView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.small),
            chevronView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.small)
        ])
    }

    func makeNameLabel() -> UILabel {
        let label = UILabel()
        label.font = Typography.rowTitle
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }

    func makeChevronView() -> UIImageView {
        let configuration = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: configuration))
        imageView.tintColor = UIColor.white.withAlphaComponent(0.85)
        return imageView
    }
}
