nonisolated struct StoreResult<Value: Sendable>: Sendable {
    let revision: Int
    let value: Value
}
