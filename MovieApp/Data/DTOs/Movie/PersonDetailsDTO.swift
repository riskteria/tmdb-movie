nonisolated enum PersonDetailsDTO {
    enum AppendedResponse: String, Sendable {
        case images
        case movieCredits = "movie_credits"
    }

    struct Parameters: Encodable, Sendable {
        var appendToResponse: [AppendedResponse] = []
        var language: String?

        private enum CodingKeys: String, CodingKey {
            case appendToResponse, language
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            if !appendToResponse.isEmpty {
                let value = appendToResponse.map(\.rawValue).joined(separator: ",")
                try container.encode(value, forKey: .appendToResponse)
            }
            try container.encodeIfPresent(language, forKey: .language)
        }
    }

    struct Response: Decodable, Sendable {
        let id: Int
        let imdbID: String?
        let name: String
        let alsoKnownAs: [String]
        let biography: String
        let birthday: String?
        let deathday: String?
        let placeOfBirth: String?
        let knownForDepartment: String
        let gender: Int
        let homepage: String?
        let profilePath: String?
        let popularity: Double
        let adult: Bool
        let images: Images?
        let movieCredits: MovieCredits?

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
    struct Images: Decodable, Sendable {
        let profiles: [ImageDTO]
    }

    struct MovieCredits: Decodable, Sendable {
        let cast: [CastCredit]
        let crew: [CrewCredit]
    }

    // Credit fields sit next to the movie fields in the same JSON object.
    struct CastCredit: Decodable, Sendable {
        let movie: MovieSummaryDTO
        let creditID: String
        let character: String
        let order: Int

        private enum CodingKeys: String, CodingKey {
            case creditID = "creditId"
            case character, order
        }

        init(from decoder: any Decoder) throws {
            movie = try MovieSummaryDTO(from: decoder)
            let container = try decoder.container(keyedBy: CodingKeys.self)
            creditID = try container.decode(String.self, forKey: .creditID)
            character = try container.decode(String.self, forKey: .character)
            order = try container.decode(Int.self, forKey: .order)
        }
    }

    struct CrewCredit: Decodable, Sendable {
        let movie: MovieSummaryDTO
        let creditID: String
        let department: String
        let job: String

        private enum CodingKeys: String, CodingKey {
            case creditID = "creditId"
            case department, job
        }

        init(from decoder: any Decoder) throws {
            movie = try MovieSummaryDTO(from: decoder)
            let container = try decoder.container(keyedBy: CodingKeys.self)
            creditID = try container.decode(String.self, forKey: .creditID)
            department = try container.decode(String.self, forKey: .department)
            job = try container.decode(String.self, forKey: .job)
        }
    }
}
