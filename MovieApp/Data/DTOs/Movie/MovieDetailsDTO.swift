nonisolated enum MovieDetailsDTO {
    enum AppendedResponse: String, Sendable {
        case accountStates = "account_states"
        case credits
        case images
        case recommendations
        case releaseDates = "release_dates"
        case reviews
        case videos
        case watchProviders = "watch/providers"
    }

    struct Parameters: Encodable, Sendable {
        var appendToResponse: [AppendedResponse] = []
        var language: String?
        // Without it, images are filtered by `language`. Example: "en,null".
        var includeImageLanguage: String?
        // Required when appending `.accountStates`.
        var sessionID: String?

        private enum CodingKeys: String, CodingKey {
            case appendToResponse, language, includeImageLanguage, sessionID
        }

        func encode(to encoder: any Encoder) throws {
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

    struct Response: Decodable, Sendable {
        let id: Int
        let imdbID: String?
        let title: String
        let originalTitle: String
        let originalLanguage: String
        let overview: String
        let tagline: String?
        let status: String
        let releaseDate: String?
        let runtime: Int?
        let budget: Int
        let revenue: Int
        let homepage: String?
        let posterPath: String?
        let backdropPath: String?
        let belongsToCollection: CollectionSummary?
        let genres: [GenreDTO]
        let originCountry: [String]
        let productionCompanies: [ProductionCompany]
        let productionCountries: [ProductionCountry]
        let spokenLanguages: [SpokenLanguage]
        let popularity: Double
        let voteAverage: Double
        let voteCount: Int
        let adult: Bool
        let video: Bool
        let accountStates: AccountStates?
        let credits: Credits?
        let images: Images?
        let recommendations: PageDTO<MovieSummaryDTO>?
        let releaseDates: ReleaseDates?
        let reviews: PageDTO<Review>?
        let videos: Videos?
        let watchProviders: WatchProviders?

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
    struct CollectionSummary: Decodable, Sendable {
        let id: Int
        let name: String
        let posterPath: String?
        let backdropPath: String?
    }

    struct ProductionCompany: Decodable, Sendable {
        let id: Int
        let name: String
        let logoPath: String?
        let originCountry: String
    }

    struct ProductionCountry: Decodable, Sendable {
        let countryCode: String
        let name: String

        private enum CodingKeys: String, CodingKey {
            case countryCode = "iso31661"
            case name
        }
    }

    struct SpokenLanguage: Decodable, Sendable {
        let languageCode: String
        let name: String
        let englishName: String

        private enum CodingKeys: String, CodingKey {
            case languageCode = "iso6391"
            case name, englishName
        }
    }
}

// MARK: - Appended Responses
nonisolated extension MovieDetailsDTO {
    struct AccountStates: Decodable, Sendable {
        let isFavorite: Bool
        let isOnWatchlist: Bool
        let rating: Double?

        private enum CodingKeys: String, CodingKey {
            case isFavorite = "favorite"
            case isOnWatchlist = "watchlist"
            case rated
        }

        private struct Rated: Decodable {
            let value: Double
        }

        init(from decoder: any Decoder) throws {
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

    struct Credits: Decodable, Sendable {
        let cast: [CastMember]
        let crew: [CrewMember]
    }

    struct CastMember: Decodable, Sendable {
        let id: Int
        let creditID: String
        let name: String
        let originalName: String
        let character: String
        let order: Int
        let profilePath: String?
        let knownForDepartment: String?
        let gender: Int
        let popularity: Double
        let adult: Bool

        private enum CodingKeys: String, CodingKey {
            case id
            case creditID = "creditId"
            case name, originalName, character, order, profilePath, knownForDepartment, gender, popularity, adult
        }
    }

    struct CrewMember: Decodable, Sendable {
        let id: Int
        let creditID: String
        let name: String
        let originalName: String
        let department: String
        let job: String
        let profilePath: String?
        let knownForDepartment: String?
        let gender: Int
        let popularity: Double
        let adult: Bool

        private enum CodingKeys: String, CodingKey {
            case id
            case creditID = "creditId"
            case name, originalName, department, job, profilePath, knownForDepartment, gender, popularity, adult
        }
    }

    struct Images: Decodable, Sendable {
        let backdrops: [ImageDTO]
        let logos: [ImageDTO]
        let posters: [ImageDTO]
    }

    struct ReleaseDates: Decodable, Sendable {
        let results: [CountryReleaseDates]
    }

    struct CountryReleaseDates: Decodable, Sendable {
        let countryCode: String
        let releaseDates: [ReleaseDate]

        private enum CodingKeys: String, CodingKey {
            case countryCode = "iso31661"
            case releaseDates
        }
    }

    // `type`: 1 premiere, 2 limited theatrical, 3 theatrical, 4 digital, 5 physical, 6 TV.
    struct ReleaseDate: Decodable, Sendable {
        let certification: String
        let descriptors: [String]
        let languageCode: String?
        let note: String
        let releaseDate: String
        let type: Int

        private enum CodingKeys: String, CodingKey {
            case certification, descriptors
            case languageCode = "iso6391"
            case note, releaseDate, type
        }
    }

    struct Review: Decodable, Sendable {
        let id: String
        let author: String
        let authorDetails: AuthorDetails
        let content: String
        let createdAt: String
        let updatedAt: String
        let url: String
    }

    struct AuthorDetails: Decodable, Sendable {
        let name: String
        let username: String
        let avatarPath: String?
        let rating: Double?
    }

    struct Videos: Decodable, Sendable {
        let results: [Video]
    }

    struct Video: Decodable, Sendable {
        let id: String
        let key: String
        let name: String
        let site: String
        let size: Int
        let type: String
        let isOfficial: Bool
        let publishedAt: String
        let languageCode: String
        let countryCode: String

        private enum CodingKeys: String, CodingKey {
            case id, key, name, site, size, type
            case isOfficial = "official"
            case publishedAt
            case languageCode = "iso6391"
            case countryCode = "iso31661"
        }
    }

    // Watch provider data comes from JustWatch, which must be credited wherever it is shown.
    struct WatchProviders: Decodable, Sendable {
        let results: [String: CountryWatchProviders]
    }

    struct CountryWatchProviders: Decodable, Sendable {
        let link: String
        let flatrate: [WatchProvider]?
        let rent: [WatchProvider]?
        let buy: [WatchProvider]?
        let ads: [WatchProvider]?
        let free: [WatchProvider]?
    }

    struct WatchProvider: Decodable, Sendable {
        let providerID: Int
        let providerName: String
        let logoPath: String?
        let displayPriority: Int

        private enum CodingKeys: String, CodingKey {
            case providerID = "providerId"
            case providerName, logoPath, displayPriority
        }
    }
}
