nonisolated enum SearchMoviesDTO {
    struct Parameters: Encodable, Sendable {
        let query: String
        var includeAdult = false
        var language: String?
        var primaryReleaseYear: Int?
        var page: Int?
        var region: String?
        var year: Int?
    }

    typealias Response = PageDTO<MovieSummaryDTO>
}
