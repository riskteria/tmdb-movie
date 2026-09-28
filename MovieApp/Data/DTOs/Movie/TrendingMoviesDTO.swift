nonisolated enum TrendingMoviesDTO {
    enum TimeWindow: String, Sendable {
        case day
        case week
    }

    struct Parameters: Encodable, Sendable {
        var language: String?
    }

    typealias Response = PageDTO<MovieSummaryDTO>
}
