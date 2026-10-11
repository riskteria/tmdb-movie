public nonisolated enum AccountMoviesDTO {
    public enum Category: String, Sendable {
        case favorites
        case rated
        case recommendations
        case watchlist
    }

    public enum SortOption: String, Encodable, Sendable {
        case createdAtAscending = "created_at.asc"
        case createdAtDescending = "created_at.desc"
    }

    public struct Parameters: Encodable, Sendable {
        public var page: Int?
        public var language: String?
        // Ignored by `.recommendations`.
        public var sortBy: SortOption?
    }

    // Rated movies carry `account_rating` next to the movie fields in the same JSON object.
    public struct Movie: Decodable, Sendable {
        public let summary: MovieSummaryDTO
        public let accountRating: AccountRating?

        private enum CodingKeys: String, CodingKey {
            case accountRating
        }

        public init(from decoder: any Decoder) throws {
            summary = try MovieSummaryDTO(from: decoder)
            let container = try decoder.container(keyedBy: CodingKeys.self)
            accountRating = try container.decodeIfPresent(AccountRating.self, forKey: .accountRating)
        }
    }

    public struct AccountRating: Decodable, Sendable {
        public let value: Double
        public let createdAt: String
    }

    public typealias Response = PageDTO<Movie>
}
