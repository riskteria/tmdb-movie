import MovieAppDS
import UIKit

struct MovieDetailLayout {
    nonisolated enum Section: Hashable, Sendable {
        case header
        case actions
        case rating
        case synopsis
        case cast
        case tabs
        case moreLikeThis
        case trailers
        case status
    }

    nonisolated enum Item: Hashable, Sendable {
        case header
        case actions
        case rating
        case synopsis
        case tabs
        case castMember(MovieDetailModel.DisplayedCastMember)
        case movie(MovieDetailModel.DisplayedMovie)
        case trailer(MovieDetailModel.DisplayedTrailer)
        case status(Status)
    }

    nonisolated enum Status: Hashable, Sendable {
        case loading
        case empty(message: String)
    }

    private let heroAspectRatio: CGFloat = 1.25
    private let heroMaximumHeight: CGFloat = 560
    private let castItemWidth: CGFloat = 72
    private let posterAspectRatio: CGFloat = 1.5
    private let compactColumnCount = 3
    private let regularColumnCount = 5

    func make(sectionForIndex: @escaping (Int) -> Section?) -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = Spacing.medium
        return UICollectionViewCompositionalLayout(
            sectionProvider: { [self] sectionIndex, environment in
                sectionForIndex(sectionIndex).map { section in makeSection(section, environment: environment) }
            },
            configuration: configuration
        )
    }
}

private extension MovieDetailLayout {
    func makeSection(_ section: Section, environment: any NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        switch section {
        case .header:
            makeHeroSection(environment: environment)
        case .actions, .rating:
            makeTextSection(estimatedHeight: 44, environment: environment)
        case .synopsis:
            makeTextSection(estimatedHeight: 100, environment: environment, hasHeader: true)
        case .cast:
            makeCastSection()
        case .tabs:
            makeFullWidthSection(estimatedHeight: 44, top: Spacing.xSmall)
        case .moreLikeThis:
            makeGridSection(environment: environment)
        case .trailers:
            makeListSection(estimatedHeight: 93)
        case .status:
            makeFullWidthSection(estimatedHeight: 180, top: 0)
        }
    }

    func makeHeroSection(environment: any NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let width = environment.container.effectiveContentSize.width
        return makeSingleItemSection(estimatedHeight: min(width * heroAspectRatio, heroMaximumHeight))
    }

    func makeTextSection(
        estimatedHeight: CGFloat,
        environment: any NSCollectionLayoutEnvironment,
        hasHeader: Bool = false
    ) -> NSCollectionLayoutSection {
        let section = makeSingleItemSection(estimatedHeight: estimatedHeight)
        if environment.traitCollection.horizontalSizeClass == .regular {
            section.contentInsetsReference = .readableContent
        } else {
            section.contentInsets = makeInsets(top: 0)
        }
        if hasHeader {
            section.contentInsets.top = Spacing.small
            section.boundarySupplementaryItems = [makeHeader()]
        }
        return section
    }

    func makeCastSection() -> NSCollectionLayoutSection {
        let size = NSCollectionLayoutSize(widthDimension: .absolute(castItemWidth), heightDimension: .estimated(120))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: size,
            subitems: [NSCollectionLayoutItem(layoutSize: size)]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = Spacing.small
        section.contentInsets = makeInsets(top: Spacing.small)
        section.boundarySupplementaryItems = [makeHeader()]
        return section
    }

    func makeGridSection(environment: any NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let isRegular = environment.traitCollection.horizontalSizeClass == .regular
        let columnCount = isRegular ? regularColumnCount : compactColumnCount
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1 / CGFloat(columnCount)),
                heightDimension: .fractionalHeight(1)
            )
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalWidth(posterAspectRatio / CGFloat(columnCount))
            ),
            repeatingSubitem: item,
            count: columnCount
        )
        group.interItemSpacing = .fixed(Spacing.small)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = Spacing.small
        section.contentInsets = makeInsets(top: 0)
        return section
    }

    func makeListSection(estimatedHeight: CGFloat) -> NSCollectionLayoutSection {
        let section = makeSingleItemSection(estimatedHeight: estimatedHeight)
        section.interGroupSpacing = Spacing.xSmall
        return section
    }

    func makeFullWidthSection(estimatedHeight: CGFloat, top: CGFloat) -> NSCollectionLayoutSection {
        let section = makeSingleItemSection(estimatedHeight: estimatedHeight)
        section.contentInsets = makeInsets(top: top)
        return section
    }

    func makeSingleItemSection(estimatedHeight: CGFloat) -> NSCollectionLayoutSection {
        let size = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(estimatedHeight)
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: size,
            subitems: [NSCollectionLayoutItem(layoutSize: size)]
        )
        return NSCollectionLayoutSection(group: group)
    }

    func makeInsets(top: CGFloat) -> NSDirectionalEdgeInsets {
        NSDirectionalEdgeInsets(top: top, leading: Spacing.large, bottom: 0, trailing: Spacing.large)
    }

    func makeHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(28)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }
}
