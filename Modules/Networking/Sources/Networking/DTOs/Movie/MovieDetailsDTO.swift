public nonisolated enum MovieDetailsDTO {
    public enum AppendedResponse: String, Sendable {
        case accountStates = "account_states"
        case credits
        case images
        case recommendations
        case releaseDates = "release_dates"
        case reviews
        case videos
        case watchProviders = "watch/providers"
    }

    public struct Parameters: Encodable, Sendable {
        public var appendToResponse: [AppendedResponse] = []
        public var language: String?
        // Without it, images are filtered by `language`. Example: "en,null".
        public var includeImageLanguage: String?
        // Required when appending `.accountStates`.
        public var sessionID: String?

        public init(
            appendToResponse: [AppendedResponse] = [],
            language: String? = nil,
            includeImageLanguage: String? = nil,
            sessionID: String? = nil
        ) {
            self.appendToResponse = appendToResponse
            self.language = language
            self.includeImageLanguage = includeImageLanguage
            self.sessionID = sessionID
        }

        private enum CodingKeys: String, CodingKey {
            case appendToResponse, language, includeImageLanguage, sessionID
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            if !appendToResponse.isEmpty {
                let value = appendToResponse.map(\.rawValue).joined(separator: ",")
                try container.encode(value, forKey: .appendToResponse)
            }
            try container.encodeIfPresent(language, forKey: .language)
            try container.encodeIfPresent(includeImageLanguage, forKey: .includeImageLanguage)
            try container.encodeIfPresent(sessionID, forKey: .sessionID)
        }
    }

    public struct Response: Decodable, Sendable {
        public let id: Int
        public let imdbID: String?
        public let title: String
        public let originalTitle: String
        public let originalLanguage: String
        public let overview: String
        public let tagline: String?
        public let status: String
        public let releaseDate: String?
        public let runtime: Int?
        public let budget: Int
        public let revenue: Int
        public let homepage: String?
        public let posterPath: String?
        public let backdropPath: String?
        public let belongsToCollection: CollectionSummary?
        public let genres: [GenreDTO]
        public let originCountry: [String]
        public let productionCompanies: [ProductionCompany]
        public let productionCountries: [ProductionCountry]
        public let spokenLanguages: [SpokenLanguage]
        public let popularity: Double
        public let voteAverage: Double
        public let voteCount: Int
        public let adult: Bool
        public let video: Bool
        public let accountStates: AccountStates?
        public let credits: Credits?
        public let images: Images?
        public let recommendations: PageDTO<MovieSummaryDTO>?
        public let releaseDates: ReleaseDates?
        public let reviews: PageDTO<Review>?
        public let videos: Videos?
        public let watchProviders: WatchProviders?

        // Raw values are keys after `.convertFromSnakeCase`, which turns `imdb_id` into `imdbId`.
        private enum CodingKeys: String, CodingKey {
            case id
            case imdbID = "imdbId"
            case title, originalTitle, originalLanguage, overview, tagline, status, releaseDate, runtime
            case budget, revenue, homepage, posterPath, backdropPath, belongsToCollection, genres
            case originCountry, productionCompanies, productionCountries, spokenLanguages
            case popularity, voteAverage, voteCount, adult, video
            case accountStates, credits, images, recommendations, releaseDates, reviews, videos
            case watchProviders = "watch/providers"
        }
    }
}

// MARK: - Details
nonisolated extension MovieDetailsDTO {
    public struct CollectionSummary: Decodable, Sendable {
        public let id: Int
        public let name: String
        public let posterPath: String?
        public let backdropPath: String?
    }

    public struct ProductionCompany: Decodable, Sendable {
        public let id: Int
        public let name: String
        public let logoPath: String?
        public let originCountry: String
    }

    public struct ProductionCountry: Decodable, Sendable {
        public let countryCode: String
        public let name: String

        private enum CodingKeys: String, CodingKey {
            case countryCode = "iso31661"
            case name
        }
    }

    public struct SpokenLanguage: Decodable, Sendable {
        public let languageCode: String
        public let name: String
        public let englishName: String

        private enum CodingKeys: String, CodingKey {
            case languageCode = "iso6391"
            case name, englishName
        }
    }
}

// MARK: - Appended Responses
nonisolated extension MovieDetailsDTO {
    public struct AccountStates: Decodable, Sendable {
        public let isFavorite: Bool
        public let isOnWatchlist: Bool
        public let rating: Double?

        private enum CodingKeys: String, CodingKey {
            case isFavorite = "favorite"
            case isOnWatchlist = "watchlist"
            case rated
        }

        private struct Rated: Decodable {
            let value: Double
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
            isOnWatchlist = try container.decode(Bool.self, forKey: .isOnWatchlist)
            // TMDB sends `false` for an unrated movie and `{ "value": 8.5 }` for a rated one.
            if (try? container.decode(Bool.self, forKey: .rated)) == false {
                rating = nil
            } else {
                rating = try container.decode(Rated.self, forKey: .rated).value
            }
        }
    }

    public struct Credits: Decodable, Sendable {
        public let cast: [CastMember]
        public let crew: [CrewMember]
    }

    public struct CastMember: Decodable, Sendable {
        public let id: Int
        public let creditID: String
        public let name: String
        public let originalName: String
        public let character: String
        public let order: Int
        public let profilePath: String?
        public let knownForDepartment: String?
        public let gender: Int
        public let popularity: Double
        public let adult: Bool

        private enum CodingKeys: String, CodingKey {
            case id
            case creditID = "creditId"
            case name, originalName, character, order, profilePath, knownForDepartment, gender, popularity, adult
        }
    }

    public struct CrewMember: Decodable, Sendable {
        public let id: Int
        public let creditID: String
        public let name: String
        public let originalName: String
        public let department: String
        public let job: String
        public let profilePath: String?
        public let knownForDepartment: String?
        public let gender: Int
        public let popularity: Double
        public let adult: Bool

        private enum CodingKeys: String, CodingKey {
            case id
            case creditID = "creditId"
            case name, originalName, department, job, profilePath, knownForDepartment, gender, popularity, adult
        }
    }

    public struct Images: Decodable, Sendable {
        public let backdrops: [ImageDTO]
        public let logos: [ImageDTO]
        public let posters: [ImageDTO]
    }

    public struct ReleaseDates: Decodable, Sendable {
        public let results: [CountryReleaseDates]
    }

    public struct CountryReleaseDates: Decodable, Sendable {
        public let countryCode: String
        public let releaseDates: [ReleaseDate]

        private enum CodingKeys: String, CodingKey {
            case countryCode = "iso31661"
            case releaseDates
        }
    }

    // `type`: 1 premiere, 2 limited theatrical, 3 theatrical, 4 digital, 5 physical, 6 TV.
    public struct ReleaseDate: Decodable, Sendable {
        public let certification: String
        public let descriptors: [String]
        public let languageCode: String?
        public let note: String
        public let releaseDate: String
        public let type: Int

        private enum CodingKeys: String, CodingKey {
            case certification, descriptors
            case languageCode = "iso6391"
            case note, releaseDate, type
        }
    }

    public struct Review: Decodable, Sendable {
        public let id: String
        public let author: String
        public let authorDetails: AuthorDetails
        public let content: String
        public let createdAt: String
        public let updatedAt: String
        public let url: String
    }

    public struct AuthorDetails: Decodable, Sendable {
        public let name: String
        public let username: String
        public let avatarPath: String?
        public let rating: Double?
    }

    public struct Videos: Decodable, Sendable {
        public let results: [Video]
    }

    public struct Video: Decodable, Sendable {
        public let id: String
        public let key: String
        public let name: String
        public let site: String
        public let size: Int
        public let type: String
        public let isOfficial: Bool
        public let publishedAt: String
        public let languageCode: String
        public let countryCode: String

        private enum CodingKeys: String, CodingKey {
            case id, key, name, site, size, type
            case isOfficial = "official"
            case publishedAt
            case languageCode = "iso6391"
            case countryCode = "iso31661"
        }
    }

    // Watch provider data comes from JustWatch, which must be credited wherever it is shown.
    public struct WatchProviders: Decodable, Sendable {
        public let results: [String: CountryWatchProviders]
    }

    public struct CountryWatchProviders: Decodable, Sendable {
        public let link: String
        public let flatrate: [WatchProvider]?
        public let rent: [WatchProvider]?
        public let buy: [WatchProvider]?
        public let ads: [WatchProvider]?
        public let free: [WatchProvider]?
    }

    public struct WatchProvider: Decodable, Sendable {
        public let providerID: Int
        public let providerName: String
        public let logoPath: String?
        public let displayPriority: Int

        private enum CodingKeys: String, CodingKey {
            case providerID = "providerId"
            case providerName, logoPath, displayPriority
        }
    }
}
