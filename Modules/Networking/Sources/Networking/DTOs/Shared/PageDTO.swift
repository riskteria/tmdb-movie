public nonisolated struct PageDTO<Item: Decodable & Sendable>: Decodable, Sendable {
    public let page: Int
    public let results: [Item]
    public let totalPages: Int
    public let totalResults: Int
}
