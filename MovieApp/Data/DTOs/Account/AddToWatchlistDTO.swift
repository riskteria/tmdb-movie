nonisolated enum AddToWatchlistDTO {
    typealias Parameters = SessionParametersDTO

    struct Request: Encodable, Sendable {
        let mediaType = "movie"
        let mediaID: Int
        let watchlist: Bool
    }

    typealias Response = StatusDTO
}
