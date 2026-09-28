nonisolated struct Page<Item: Sendable>: Sendable {
    let number: Int
    let items: [Item]
    let totalPages: Int
    let totalResults: Int

    var hasNextPage: Bool {
        number < totalPages
    }
}

nonisolated extension Page: Equatable where Item: Equatable {}
