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

    enum ObserveSavedMovies {
        struct Request {}

        struct Response {
            let savedMovies: [SavedMovie]
            let capacity: Int
        }

        enum ViewData: Equatable {
            case content(header: String, movies: [DisplayedMovie])
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
