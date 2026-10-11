public nonisolated enum ConfigurationDTO {
    public struct Response: Decodable, Sendable {
        public let images: Images
    }

    public struct Images: Decodable, Sendable {
        public let baseURL: String
        public let secureBaseURL: String
        public let backdropSizes: [String]
        public let logoSizes: [String]
        public let posterSizes: [String]
        public let profileSizes: [String]
        public let stillSizes: [String]

        private enum CodingKeys: String, CodingKey {
            case baseURL = "baseUrl"
            case secureBaseURL = "secureBaseUrl"
            case backdropSizes, logoSizes, posterSizes, profileSizes, stillSizes
        }
    }
}
