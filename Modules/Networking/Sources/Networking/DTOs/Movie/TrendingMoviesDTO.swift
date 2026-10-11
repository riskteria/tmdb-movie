public nonisolated enum TrendingMoviesDTO {
    public enum TimeWindow: String, Sendable {
        case day
        case week
    }

    public struct Parameters: Encodable, Sendable {
        public var language: String?

        public init(language: String? = nil) {
            self.language = language
        }
    }

    public typealias Response = PageDTO<MovieSummaryDTO>
}
