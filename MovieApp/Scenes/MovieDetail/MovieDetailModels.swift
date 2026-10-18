enum MovieDetailModel {
    nonisolated enum WatchAvailability: Hashable, Sendable {
        case pending
        case available(Video)
        case unavailable
    }

    nonisolated struct DisplayedDetail: Hashable, Sendable {
        let movie: Movie
        let title: String
        let metadata: String
        let overview: String
        let artwork: DisplayedArtwork
        let watch: WatchAvailability
    }

    nonisolated struct DisplayedExtras: Hashable, Sendable {
        let rating: DisplayedRating?
        let cast: [DisplayedCastMember]
        let moreLikeThis: DisplayedTabContent<DisplayedMovie>
        let trailers: DisplayedTabContent<DisplayedTrailer>
    }

    nonisolated struct DisplayedRating: Hashable, Sendable {
        let score: String
        let votes: String
        let accessibilityLabel: String
    }

    nonisolated struct DisplayedCastMember: Hashable, Sendable {
        let id: CastMember.ID
        let name: String
        let character: String
        let artwork: DisplayedArtwork
    }

    nonisolated struct DisplayedMovie: Hashable, Sendable {
        let movie: Movie
        let title: String
        let rating: String?
        let artwork: DisplayedArtwork

        var id: Movie.ID {
            movie.id
        }
    }

    nonisolated struct DisplayedTrailer: Hashable, Sendable {
        let video: Video
        let title: String
        let metadata: String
        let accessibilityValue: String
        let artwork: DisplayedArtwork
    }

    nonisolated enum DisplayedTabContent<Item: Hashable & Sendable>: Hashable, Sendable {
        case items([Item])
        case empty(message: String)
    }

    enum LoadDetails {
        struct Request {}

        struct Response {
            let movie: Movie
            // nil while the details request is still running.
            let details: Result<MovieDetails, any Error>?
        }

        enum ViewData: Equatable {
            case loading(DisplayedDetail)
            case content(DisplayedDetail, DisplayedExtras)
            case failure(message: String)
        }
    }

    enum ObserveSavedState {
        struct Request {}

        struct Response {
            let isSaved: Bool
        }

        struct ViewData: Equatable {
            let title: String
            let isSaved: Bool
        }
    }

    enum ToggleSave {
        enum Action {
            case save
            case remove
        }

        struct Request {}

        struct Response {
            let action: Action
            let movie: Movie
        }

        struct ViewData: Equatable {
            let message: String
        }
    }

    enum Watch {
        struct Request {
            let video: Video
        }

        struct Response {
            let movie: Movie
            let result: Result<Video, any Error>
        }

        enum ViewData: Equatable {
            case trailer(Video)
            case failure(message: String)
        }
    }
}
