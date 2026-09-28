nonisolated enum ConfigurationDTO {
    struct Response: Decodable, Sendable {
        let images: Images
    }

    struct Images: Decodable, Sendable {
        let baseURL: String
        let secureBaseURL: String
        let backdropSizes: [String]
        let logoSizes: [String]
        let posterSizes: [String]
        let profileSizes: [String]
        let stillSizes: [String]

        private enum CodingKeys: String, CodingKey {
            case baseURL = "baseUrl"
            case secureBaseURL = "secureBaseUrl"
            case backdropSizes, logoSizes, posterSizes, profileSizes, stillSizes
        }
    }
}
