public nonisolated enum MovieGenresDTO {
    public struct Parameters: Encodable, Sendable {
        public var language: String?

        public init(language: String? = nil) {
            self.language = language
        }
    }

    public struct Response: Decodable, Sendable {
        public let genres: [GenreDTO]
    }
}
