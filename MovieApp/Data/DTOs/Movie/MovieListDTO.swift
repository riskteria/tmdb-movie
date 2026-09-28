nonisolated enum MovieListDTO {
    enum Category: String, Sendable {
        case nowPlaying = "now_playing"
        case popular
        case topRated = "top_rated"
        case upcoming
    }

    struct Parameters: Encodable, Sendable {
        var language: String?
        var page: Int?
        var region: String?
    }

    typealias Response = PageDTO<MovieSummaryDTO>
}
