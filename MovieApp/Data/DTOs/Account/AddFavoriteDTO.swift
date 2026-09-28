nonisolated enum AddFavoriteDTO {
    typealias Parameters = SessionParametersDTO

    struct Request: Encodable, Sendable {
        let mediaType = "movie"
        let mediaID: Int
        let favorite: Bool
    }

    typealias Response = StatusDTO
}
