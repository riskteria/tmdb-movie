enum SearchModel {
    nonisolated struct DisplayedGenre: Hashable, Sendable {
        let genre: Genre
        let name: String

        var id: Genre.ID {
            genre.id
        }
    }

    struct DisplayedContent: Equatable {
        let sectionTitle: String
        let count: String
        let genres: [DisplayedGenre]
    }

    enum LoadGenres {
        struct Request {}

        struct Response {
            let result: Result<[Genre], any Error>
        }

        enum ViewData: Equatable {
            case content(DisplayedContent)
            case empty(message: String)
            case failure(message: String)
        }
    }
}
