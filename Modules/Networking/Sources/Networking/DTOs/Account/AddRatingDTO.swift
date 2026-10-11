public nonisolated enum AddRatingDTO {
    public typealias Parameters = SessionParametersDTO

    // `value` ranges from 0.5 to 10 in steps of 0.5. By default TMDB also removes a rated movie from the watchlist.
    public struct Request: Encodable, Sendable {
        public let value: Double
    }

    public typealias Response = StatusDTO
}
