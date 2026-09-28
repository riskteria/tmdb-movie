nonisolated enum MovieGenresDTO {
    struct Parameters: Encodable, Sendable {
        var language: String?
    }

    struct Response: Decodable, Sendable {
        let genres: [GenreDTO]
    }
}
