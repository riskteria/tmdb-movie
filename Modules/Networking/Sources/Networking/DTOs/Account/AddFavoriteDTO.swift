public nonisolated enum AddFavoriteDTO {
    public typealias Parameters = SessionParametersDTO

    public struct Request: Encodable, Sendable {
        public let mediaType = "movie"
        public let mediaID: Int
        public let favorite: Bool
    }

    public typealias Response = StatusDTO
}
