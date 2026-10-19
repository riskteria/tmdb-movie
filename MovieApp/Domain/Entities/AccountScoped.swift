nonisolated enum AccountScoped<Value: Sendable>: Sendable {
    case signedOut
    case signedIn(Value)
}

nonisolated extension AccountScoped: Equatable where Value: Equatable {}

nonisolated extension AccountScoped: Hashable where Value: Hashable {}
