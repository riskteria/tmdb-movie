enum MovieDetailModel {
    struct DisplayedDetail: Equatable {
        let title: String
        let metadata: String
        let overview: String
        let artwork: DisplayedArtwork
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
            case content(DisplayedDetail)
            case failure(message: String)
        }
    }
}
