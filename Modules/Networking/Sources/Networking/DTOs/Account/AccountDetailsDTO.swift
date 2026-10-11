public nonisolated enum AccountDetailsDTO {
    public typealias Parameters = SessionParametersDTO

    public struct Response: Decodable, Sendable {
        public let id: Int
        public let username: String
        public let name: String
        public let avatar: Avatar
        public let languageCode: String
        public let countryCode: String
        public let includeAdult: Bool

        private enum CodingKeys: String, CodingKey {
            case id, username, name, avatar
            case languageCode = "iso6391"
            case countryCode = "iso31661"
            case includeAdult
        }
    }

    public struct Avatar: Decodable, Sendable {
        public let gravatar: Gravatar
        public let tmdb: TMDBAvatar
    }

    public struct Gravatar: Decodable, Sendable {
        public let hash: String
    }

    public struct TMDBAvatar: Decodable, Sendable {
        public let avatarPath: String?
    }
}
