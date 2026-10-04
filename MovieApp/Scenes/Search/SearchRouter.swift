protocol ISearchRouter {
    func routeToGenreMovies(genre: Genre)
}

final class SearchRouter {
    private let onSelectGenre: (Genre) -> Void

    init(onSelectGenre: @escaping (Genre) -> Void) {
        self.onSelectGenre = onSelectGenre
    }
}

// MARK: - ISearchRouter
extension SearchRouter: ISearchRouter {
    func routeToGenreMovies(genre: Genre) {
        onSelectGenre(genre)
    }
}
