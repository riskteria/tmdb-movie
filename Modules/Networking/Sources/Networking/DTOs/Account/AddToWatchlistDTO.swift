public nonisolated enum AddToWatchlistDTO {
    public typealias Parameters = SessionParametersDTO

    public struct Request: Encodable, Sendable {
        public let mediaType = "movie"
        public let mediaID: Int
        public let watchlist: Bool
    }

    public typealias Response = StatusDTO
}
