nonisolated enum AccountDetailsDTO {
    typealias Parameters = SessionParametersDTO

    struct Response: Decodable, Sendable {
        let id: Int
        let username: String
        let name: String
        let avatar: Avatar
        let languageCode: String
        let countryCode: String
        let includeAdult: Bool

        private enum CodingKeys: String, CodingKey {
            case id, username, name, avatar
            case languageCode = "iso6391"
            case countryCode = "iso31661"
            case includeAdult
        }
    }

    struct Avatar: Decodable, Sendable {
        let gravatar: Gravatar
        let tmdb: TMDBAvatar
    }

    struct Gravatar: Decodable, Sendable {
        let hash: String
    }

    struct TMDBAvatar: Decodable, Sendable {
        let avatarPath: String?
    }
}
