import UIKit

extension NSDiffableDataSourceSnapshot<MovieDetailLayout.Section, MovieDetailLayout.Item> {
    mutating func append(_ items: [MovieDetailLayout.Item], to section: MovieDetailLayout.Section) {
        appendSections([section])
        appendItems(items, toSection: section)
    }

    mutating func appendTabContent<Content: Hashable & Sendable>(
        _ content: MovieDetailModel.DisplayedTabContent<Content>,
        as section: MovieDetailLayout.Section,
        makeItem: (Content) -> MovieDetailLayout.Item
    ) {
        switch content {
        case .items(let items):
            append(items.map(makeItem), to: section)
        case .empty(let message):
            append([.status(.empty(message: message))], to: .status)
        }
    }
}
