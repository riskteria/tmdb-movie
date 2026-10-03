import Foundation

protocol ISearchPresenter {
    func presentGenres(response: SearchModel.LoadGenres.Response)
}

final class SearchPresenter {
    weak var viewController: (any ISearchViewController)?
}

// MARK: - ISearchPresenter
extension SearchPresenter: ISearchPresenter {
    func presentGenres(response: SearchModel.LoadGenres.Response) {
        switch response.result {
        case .success(let genres) where genres.isEmpty:
            viewController?.displayGenres(viewData: .empty(message: String(localized: "No genres available")))
        case .success(let genres):
            let content = SearchModel.DisplayedContent(
                sectionTitle: String(localized: "Browse by Genre"),
                count: genres.count.formatted(),
                genres: genres.map { SearchModel.DisplayedGenre(id: $0.id, name: $0.name) }
            )
            viewController?.displayGenres(viewData: .content(content))
        case .failure:
            viewController?.displayGenres(viewData: .failure(message: String(localized: "Unable to load genres")))
        }
    }
}
