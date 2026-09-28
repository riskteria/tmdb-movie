enum HomeModel {
    nonisolated enum Section: Hashable, Sendable {
        case hero
        case continueWatching
        case popular
        case topRated
        case upcoming
    }

    nonisolated struct DisplayedBanner: Hashable, Sendable {
        // Handed to the Router on selection, so Movie Detail opens with the movie that was tapped.
        let movie: Movie
        let title: String
        let metadata: String
        let artwork: DisplayedArtwork

        var id: Movie.ID {
            movie.id
        }
    }

    nonisolated struct DisplayedContinueWatching: Hashable, Sendable {
        let movie: Movie
        let title: String
        let subtitle: String
        let progress: Double
        let artwork: DisplayedArtwork

        var id: Movie.ID {
            movie.id
        }
    }

    nonisolated struct DisplayedPoster: Hashable, Sendable {
        let movie: Movie
        let title: String
        let artwork: DisplayedArtwork

        var id: Movie.ID {
            movie.id
        }
    }

    nonisolated enum Item: Hashable, Sendable {
        case hero([DisplayedBanner])
        case continueWatching(DisplayedContinueWatching)
        // The section is part of the identity because one movie can appear in two rows.
        case poster(DisplayedPoster, section: Section)
    }

    struct DisplayedSection: Equatable {
        let section: Section
        let title: String?
        let items: [Item]
    }

    enum LoadHome {
        struct Request {}

        struct Response {
            let trending: Result<[Movie], any Error>
            let continueWatching: Result<[ContinueWatchingItem], any Error>
            let popular: Result<Page<Movie>, any Error>
            let topRated: Result<Page<Movie>, any Error>
            let upcoming: Result<Page<Movie>, any Error>
            let genres: Result<[Genre], any Error>
        }

        enum ViewData: Equatable {
            case content([DisplayedSection])
            case empty(message: String)
            case failure(message: String)
        }
    }
}
