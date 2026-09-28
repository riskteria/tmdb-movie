nonisolated enum AccountMoviesDTO {
    enum Category: String, Sendable {
        case favorites
        case rated
        case recommendations
        case watchlist
    }

    enum SortOption: String, Encodable, Sendable {
        case createdAtAscending = "created_at.asc"
        case createdAtDescending = "created_at.desc"
    }

    struct Parameters: Encodable, Sendable {
        var page: Int?
        var language: String?
        // Ignored by `.recommendations`.
        var sortBy: SortOption?
    }

    // Rated movies carry `account_rating` next to the movie fields in the same JSON object.
    struct Movie: Decodable, Sendable {
        let summary: MovieSummaryDTO
        let accountRating: AccountRating?

        private enum CodingKeys: String, CodingKey {
            case accountRating
        }

        init(from decoder: any Decoder) throws {
            summary = try MovieSummaryDTO(from: decoder)
            let container = try decoder.container(keyedBy: CodingKeys.self)
            accountRating = try container.decodeIfPresent(AccountRating.self, forKey: .accountRating)
        }
    }

    struct AccountRating: Decodable, Sendable {
        let value: Double
        let createdAt: String
    }

    typealias Response = PageDTO<Movie>
}
