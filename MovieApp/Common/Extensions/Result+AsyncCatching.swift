nonisolated extension Result where Failure == any Error {
    // The async counterpart of `Result(catching:)`, so concurrent `async let` loads can each keep their outcome.
    init(catching body: () async throws -> Success) async {
        do {
            self = .success(try await body())
        } catch {
            self = .failure(error)
        }
    }
}
