public nonisolated enum MovieListDTO {
    public enum Category: String, Sendable {
        case nowPlaying = "now_playing"
        case popular
        case topRated = "top_rated"
        case upcoming
    }

    public struct Parameters: Encodable, Sendable {
        public var language: String?
        public var page: Int?
        public var region: String?

        public init(language: String? = nil, page: Int? = nil, region: String? = nil) {
            self.language = language
            self.page = page
            self.region = region
        }
    }

    public typealias Response = PageDTO<MovieSummaryDTO>
}
