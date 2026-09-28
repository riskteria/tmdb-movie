import UIKit

enum HomeLayout {
    private static let heroAspectRatio: CGFloat = 1.4
    private static let heroMaximumScreenShare: CGFloat = 0.72
    private static let posterSize = CGSize(width: 124, height: 186)
    private static let continueWatchingWidth: CGFloat = 214

    static func make(sectionForIndex: @escaping (Int) -> HomeModel.Section?) -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = Spacing.xLarge
        return UICollectionViewCompositionalLayout(
            sectionProvider: { sectionIndex, environment in
                switch sectionForIndex(sectionIndex) {
                case .hero:
                    Self.makeHeroSection(environment: environment)
                case .continueWatching:
                    Self.makeRowSection(
                        itemSize: NSCollectionLayoutSize(
                            widthDimension: .absolute(Self.continueWatchingWidth),
                            heightDimension: .estimated(190)
                        )
                    )
                case .popular, .upcoming:
                    Self.makeRowSection(
                        itemSize: NSCollectionLayoutSize(
                            widthDimension: .absolute(Self.posterSize.width),
                            heightDimension: .absolute(Self.posterSize.height)
                        )
                    )
                case .topRated:
                    Self.makeGridSection(
                        itemSize: NSCollectionLayoutSize(
                            widthDimension: .fractionalWidth(0.33),
                            heightDimension: .absolute(Self.posterSize.height),
                        )
                    )
                case nil:
                    nil
                }
            },
            configuration: configuration
        )
    }
}

private extension HomeLayout {
    static func makeHeroSection(environment: any NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let container = environment.container.effectiveContentSize
        let height = min(container.width * heroAspectRatio, container.height * heroMaximumScreenShare)
        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(height))
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
        return NSCollectionLayoutSection(group: group)
    }

    static func makeRowSection(itemSize: NSCollectionLayoutSize) -> NSCollectionLayoutSection {
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: itemSize,
            subitems: [NSCollectionLayoutItem(layoutSize: itemSize)]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
        section.interGroupSpacing = Spacing.small
        section.contentInsets = NSDirectionalEdgeInsets(
            top: Spacing.small,
            leading: Spacing.large,
            bottom: 0,
            trailing: Spacing.large
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(28)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]
        return section
    }

    static func makeGridSection(itemSize: NSCollectionLayoutSize) -> NSCollectionLayoutSection {
        let layoutSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: itemSize.heightDimension
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: Spacing.xSmall,
            bottom: 0,
            trailing: Spacing.xSmall
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: layoutSize,
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = Spacing.small
        section.contentInsets = NSDirectionalEdgeInsets(
            top: Spacing.small,
            leading: Spacing.small,
            bottom: 0,
            trailing: Spacing.small
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(28)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]
        return section
    }
}
