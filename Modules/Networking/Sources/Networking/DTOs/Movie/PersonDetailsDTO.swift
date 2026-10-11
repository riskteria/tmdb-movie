public nonisolated enum PersonDetailsDTO {
    public enum AppendedResponse: String, Sendable {
        case images
        case movieCredits = "movie_credits"
    }

    public struct Parameters: Encodable, Sendable {
        public var appendToResponse: [AppendedResponse] = []
        public var language: String?

        private enum CodingKeys: String, CodingKey {
            case appendToResponse, language
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            if !appendToResponse.isEmpty {
                let value = appendToResponse.map(\.rawValue).joined(separator: ",")
                try container.encode(value, forKey: .appendToResponse)
            }
            try container.encodeIfPresent(language, forKey: .language)
        }
    }

    public struct Response: Decodable, Sendable {
        public let id: Int
        public let imdbID: String?
        public let name: String
        public let alsoKnownAs: [String]
        public let biography: String
        public let birthday: String?
        public let deathday: String?
        public let placeOfBirth: String?
        public let knownForDepartment: String
        public let gender: Int
        public let homepage: String?
        public let profilePath: String?
        public let popularity: Double
        public let adult: Bool
        public let images: Images?
        public let movieCredits: MovieCredits?

        // Raw values are keys after `.convertFromSnakeCase`, which turns `imdb_id` into `imdbId`.
        private enum CodingKeys: String, CodingKey {
            case id
            case imdbID = "imdbId"
            case name, alsoKnownAs, biography, birthday, deathday, placeOfBirth, knownForDepartment
            case gender, homepage, profilePath, popularity, adult, images, movieCredits
        }
    }
}

// MARK: - Appended Responses
nonisolated extension PersonDetailsDTO {
    public struct Images: Decodable, Sendable {
        public let profiles: [ImageDTO]
    }

    public struct MovieCredits: Decodable, Sendable {
        public let cast: [CastCredit]
        public let crew: [CrewCredit]
    }

    // Credit fields sit next to the movie fields in the same JSON object.
    public struct CastCredit: Decodable, Sendable {
        public let movie: MovieSummaryDTO
        public let creditID: String
        public let character: String
        public let order: Int

        private enum CodingKeys: String, CodingKey {
            case creditID = "creditId"
            case character, order
        }

        public init(from decoder: any Decoder) throws {
            movie = try MovieSummaryDTO(from: decoder)
            let container = try decoder.container(keyedBy: CodingKeys.self)
            creditID = try container.decode(String.self, forKey: .creditID)
            character = try container.decode(String.self, forKey: .character)
            order = try container.decode(Int.self, forKey: .order)
        }
    }

    public struct CrewCredit: Decodable, Sendable {
        public let movie: MovieSummaryDTO
        public let creditID: String
        public let department: String
        public let job: String

        private enum CodingKeys: String, CodingKey {
            case creditID = "creditId"
            case department, job
        }

        public init(from decoder: any Decoder) throws {
            movie = try MovieSummaryDTO(from: decoder)
            let container = try decoder.container(keyedBy: CodingKeys.self)
            creditID = try container.decode(String.self, forKey: .creditID)
            department = try container.decode(String.self, forKey: .department)
            job = try container.decode(String.self, forKey: .job)
        }
    }
}
