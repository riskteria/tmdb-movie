enum SavedModel {
    nonisolated struct DisplayedMovie: Hashable, Sendable {
        // Handed to the Router on selection, so Movie Detail opens with the movie that was tapped.
        let movie: Movie
        let title: String
        let metadata: String
        let rating: String?
        let artwork: DisplayedArtwork

        var id: Movie.ID {
            movie.id
        }
    }

    nonisolated struct DisplayedBanner: Hashable, Sendable {
        let title: String
        let message: String
    }

    nonisolated enum Section: Hashable, Sendable {
        case banner
        case movies
    }

    nonisolated enum Item: Hashable, Sendable {
        case banner(DisplayedBanner)
        case movie(DisplayedMovie)
    }

    enum ObserveSavedMovies {
        struct Request {}

        struct Response {
            let savedMovies: [SavedMovie]
            let capacity: Int
            let isPersistent: Bool
        }

        enum ViewData: Equatable {
            case content(header: String, banner: DisplayedBanner?, movies: [DisplayedMovie])
            case empty(title: String, message: String)
        }
    }

    enum RemoveMovie {
        struct Request {
            let movie: Movie
        }

        struct Response {
            let movie: Movie
            let result: Result<Void, any Error>
        }

        enum ViewData: Equatable {
            case removed(Movie.ID)
            case failure(movieID: Movie.ID, message: String)
        }
    }
}
