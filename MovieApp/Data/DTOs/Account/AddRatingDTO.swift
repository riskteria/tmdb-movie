nonisolated enum AddRatingDTO {
    typealias Parameters = SessionParametersDTO

    // `value` ranges from 0.5 to 10 in steps of 0.5. By default TMDB also removes a rated movie from the watchlist.
    struct Request: Encodable, Sendable {
        let value: Double
    }

    typealias Response = StatusDTO
}
