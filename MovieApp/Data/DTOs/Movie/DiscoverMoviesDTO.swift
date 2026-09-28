nonisolated enum DiscoverMoviesDTO {
    enum SortOption: String, Encodable, Sendable {
        case originalTitleAscending = "original_title.asc"
        case originalTitleDescending = "original_title.desc"
        case popularityAscending = "popularity.asc"
        case popularityDescending = "popularity.desc"
        case primaryReleaseDateAscending = "primary_release_date.asc"
        case primaryReleaseDateDescending = "primary_release_date.desc"
        case revenueAscending = "revenue.asc"
        case revenueDescending = "revenue.desc"
        case titleAscending = "title.asc"
        case titleDescending = "title.desc"
        case voteAverageAscending = "vote_average.asc"
        case voteAverageDescending = "vote_average.desc"
        case voteCountAscending = "vote_count.asc"
        case voteCountDescending = "vote_count.desc"
    }

    // `with…`, `without…` and `withReleaseType` take IDs joined with "," (AND) or "|" (OR).
    // Dates use the "yyyy-MM-dd" format.
    struct Parameters: Encodable, Sendable {
        var certification: String?
        var minimumCertification: String?
        var maximumCertification: String?
        var certificationCountry: String?
        var includeAdult = false
        var includeVideo = false
        var language: String?
        var page: Int?
        var primaryReleaseYear: Int?
        var minimumPrimaryReleaseDate: String?
        var maximumPrimaryReleaseDate: String?
        var region: String?
        var minimumReleaseDate: String?
        var maximumReleaseDate: String?
        var sortBy: SortOption?
        var minimumVoteAverage: Double?
        var maximumVoteAverage: Double?
        var minimumVoteCount: Int?
        var maximumVoteCount: Int?
        var watchRegion: String?
        var withCast: String?
        var withCompanies: String?
        var withCrew: String?
        var withGenres: String?
        var withKeywords: String?
        var withOriginCountry: String?
        var withOriginalLanguage: String?
        var withPeople: String?
        var withReleaseType: String?
        var minimumRuntime: Int?
        var maximumRuntime: Int?
        var withWatchMonetizationTypes: String?
        var withWatchProviders: String?
        var withoutCompanies: String?
        var withoutGenres: String?
        var withoutKeywords: String?
        var withoutWatchProviders: String?
        var year: Int?

        // Dotted keys are spelled out. The encoder's `.convertToSnakeCase` handles the rest.
        private enum CodingKeys: String, CodingKey {
            case certification
            case minimumCertification = "certification.gte"
            case maximumCertification = "certification.lte"
            case certificationCountry, includeAdult, includeVideo, language, page, primaryReleaseYear
            case minimumPrimaryReleaseDate = "primary_release_date.gte"
            case maximumPrimaryReleaseDate = "primary_release_date.lte"
            case region
            case minimumReleaseDate = "release_date.gte"
            case maximumReleaseDate = "release_date.lte"
            case sortBy
            case minimumVoteAverage = "vote_average.gte"
            case maximumVoteAverage = "vote_average.lte"
            case minimumVoteCount = "vote_count.gte"
            case maximumVoteCount = "vote_count.lte"
            case watchRegion, withCast, withCompanies, withCrew, withGenres, withKeywords, withOriginCountry
            case withOriginalLanguage, withPeople, withReleaseType
            case minimumRuntime = "with_runtime.gte"
            case maximumRuntime = "with_runtime.lte"
            case withWatchMonetizationTypes, withWatchProviders
            case withoutCompanies, withoutGenres, withoutKeywords, withoutWatchProviders, year
        }
    }

    typealias Response = PageDTO<MovieSummaryDTO>
}
