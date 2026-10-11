public nonisolated enum SearchMoviesDTO {
    public struct Parameters: Encodable, Sendable {
        public let query: String
        public var includeAdult = false
        public var language: String?
        public var primaryReleaseYear: Int?
        public var page: Int?
        public var region: String?
        public var year: Int?

        public init(
            query: String,
            includeAdult: Bool = false,
            language: String? = nil,
            primaryReleaseYear: Int? = nil,
            page: Int? = nil,
            region: String? = nil,
            year: Int? = nil
        ) {
            self.query = query
            self.includeAdult = includeAdult
            self.language = language
            self.primaryReleaseYear = primaryReleaseYear
            self.page = page
            self.region = region
            self.year = year
        }
    }

    public typealias Response = PageDTO<MovieSummaryDTO>
}
