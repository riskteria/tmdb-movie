enum DiscoverModel {
    nonisolated struct DisplayedGenre: Hashable, Sendable {
        let id: Genre.ID
        let name: String
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
