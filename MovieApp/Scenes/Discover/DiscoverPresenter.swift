import Foundation

protocol IDiscoverPresenter {
    func presentGenres(response: DiscoverModel.LoadGenres.Response)
}

final class DiscoverPresenter {
    weak var viewController: (any IDiscoverViewController)?
}

// MARK: - IDiscoverPresenter
extension DiscoverPresenter: IDiscoverPresenter {
    func presentGenres(response: DiscoverModel.LoadGenres.Response) {
        switch response.result {
        case .success(let genres) where genres.isEmpty:
            viewController?.displayGenres(viewData: .empty(message: String(localized: "No genres available")))
        case .success(let genres):
            let content = DiscoverModel.DisplayedContent(
                sectionTitle: String(localized: "Browse by Genre"),
                count: genres.count.formatted(),
                genres: genres.map { DiscoverModel.DisplayedGenre(id: $0.id, name: $0.name) }
            )
            viewController?.displayGenres(viewData: .content(content))
        case .failure:
            viewController?.displayGenres(viewData: .failure(message: String(localized: "Unable to load genres")))
        }
    }
}
