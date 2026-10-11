public nonisolated struct MovieSummaryDTO: Decodable, Sendable {
    public let id: Int
    public let title: String
    public let originalTitle: String
    public let originalLanguage: String
    public let overview: String
    public let posterPath: String?
    public let backdropPath: String?
    public let genreIDs: [Int]
    public let releaseDate: String?
    public let popularity: Double
    public let voteAverage: Double
    public let voteCount: Int
    public let adult: Bool
    public let video: Bool

    // Raw values are keys after `.convertFromSnakeCase`, which turns `genre_ids` into `genreIds`.
    private enum CodingKeys: String, CodingKey {
        case id, title, originalTitle, originalLanguage, overview, posterPath, backdropPath
        case genreIDs = "genreIds"
        case releaseDate, popularity, voteAverage, voteCount, adult, video
    }
}
