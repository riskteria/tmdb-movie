public nonisolated enum DiscoverMoviesDTO {
    public enum SortOption: String, Encodable, Sendable {
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
    public struct Parameters: Encodable, Sendable {
        public var certification: String?
        public var minimumCertification: String?
        public var maximumCertification: String?
        public var certificationCountry: String?
        public var includeAdult = false
        public var includeVideo = false
        public var language: String?
        public var page: Int?
        public var primaryReleaseYear: Int?
        public var minimumPrimaryReleaseDate: String?
        public var maximumPrimaryReleaseDate: String?
        public var region: String?
        public var minimumReleaseDate: String?
        public var maximumReleaseDate: String?
        public var sortBy: SortOption?
        public var minimumVoteAverage: Double?
        public var maximumVoteAverage: Double?
        public var minimumVoteCount: Int?
        public var maximumVoteCount: Int?
        public var watchRegion: String?
        public var withCast: String?
        public var withCompanies: String?
        public var withCrew: String?
        public var withGenres: String?
        public var withKeywords: String?
        public var withOriginCountry: String?
        public var withOriginalLanguage: String?
        public var withPeople: String?
        public var withReleaseType: String?
        public var minimumRuntime: Int?
        public var maximumRuntime: Int?
        public var withWatchMonetizationTypes: String?
        public var withWatchProviders: String?
        public var withoutCompanies: String?
        public var withoutGenres: String?
        public var withoutKeywords: String?
        public var withoutWatchProviders: String?
        public var year: Int?

        public init(
            certification: String? = nil,
            minimumCertification: String? = nil,
            maximumCertification: String? = nil,
            certificationCountry: String? = nil,
            includeAdult: Bool = false,
            includeVideo: Bool = false,
            language: String? = nil,
            page: Int? = nil,
            primaryReleaseYear: Int? = nil,
            minimumPrimaryReleaseDate: String? = nil,
            maximumPrimaryReleaseDate: String? = nil,
            region: String? = nil,
            minimumReleaseDate: String? = nil,
            maximumReleaseDate: String? = nil,
            sortBy: SortOption? = nil,
            minimumVoteAverage: Double? = nil,
            maximumVoteAverage: Double? = nil,
            minimumVoteCount: Int? = nil,
            maximumVoteCount: Int? = nil,
            watchRegion: String? = nil,
            withCast: String? = nil,
            withCompanies: String? = nil,
            withCrew: String? = nil,
            withGenres: String? = nil,
            withKeywords: String? = nil,
            withOriginCountry: String? = nil,
            withOriginalLanguage: String? = nil,
            withPeople: String? = nil,
            withReleaseType: String? = nil,
            minimumRuntime: Int? = nil,
            maximumRuntime: Int? = nil,
            withWatchMonetizationTypes: String? = nil,
            withWatchProviders: String? = nil,
            withoutCompanies: String? = nil,
            withoutGenres: String? = nil,
            withoutKeywords: String? = nil,
            withoutWatchProviders: String? = nil,
            year: Int? = nil
        ) {
            self.certification = certification
            self.minimumCertification = minimumCertification
            self.maximumCertification = maximumCertification
            self.certificationCountry = certificationCountry
            self.includeAdult = includeAdult
            self.includeVideo = includeVideo
            self.language = language
            self.page = page
            self.primaryReleaseYear = primaryReleaseYear
            self.minimumPrimaryReleaseDate = minimumPrimaryReleaseDate
            self.maximumPrimaryReleaseDate = maximumPrimaryReleaseDate
            self.region = region
            self.minimumReleaseDate = minimumReleaseDate
            self.maximumReleaseDate = maximumReleaseDate
            self.sortBy = sortBy
            self.minimumVoteAverage = minimumVoteAverage
            self.maximumVoteAverage = maximumVoteAverage
            self.minimumVoteCount = minimumVoteCount
            self.maximumVoteCount = maximumVoteCount
            self.watchRegion = watchRegion
            self.withCast = withCast
            self.withCompanies = withCompanies
            self.withCrew = withCrew
            self.withGenres = withGenres
            self.withKeywords = withKeywords
            self.withOriginCountry = withOriginCountry
            self.withOriginalLanguage = withOriginalLanguage
            self.withPeople = withPeople
            self.withReleaseType = withReleaseType
            self.minimumRuntime = minimumRuntime
            self.maximumRuntime = maximumRuntime
            self.withWatchMonetizationTypes = withWatchMonetizationTypes
            self.withWatchProviders = withWatchProviders
            self.withoutCompanies = withoutCompanies
            self.withoutGenres = withoutGenres
            self.withoutKeywords = withoutKeywords
            self.withoutWatchProviders = withoutWatchProviders
            self.year = year
        }

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

    public typealias Response = PageDTO<MovieSummaryDTO>
}
