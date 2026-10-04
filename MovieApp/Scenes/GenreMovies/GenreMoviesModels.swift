enum GenreMoviesModel {
    nonisolated struct DisplayedMovie: Hashable, Sendable {
        let movie: Movie
        let title: String
        let artwork: DisplayedArtwork
        let rating: String?

        var id: Movie.ID {
            movie.id
        }
    }

    enum LoadStatus {
        case loading
        case loaded
        case failed
    }

    enum LoadMoreFooter: Equatable {
        case hidden
        case spinner
        case retry(message: String)
    }

    enum LoadNextPage {
        struct Request {}

        struct Response {
            let movies: [Movie]
            let status: LoadStatus
        }

        enum ViewData: Equatable {
            case loading
            case content(movies: [DisplayedMovie], footer: LoadMoreFooter)
            case empty(message: String)
            case failure(message: String)
        }
    }

    enum RefreshMovies {
        struct Request {}
    }
}
