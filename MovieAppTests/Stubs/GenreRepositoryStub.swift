@testable import MovieApp

actor GenreRepositoryStub {
    enum Call: Equatable, Sendable {
        case movieGenres
    }

    private let result: Result<[Genre], any Error>
    private(set) var calls: [Call] = []

    init(result: Result<[Genre], any Error> = .success([])) {
        self.result = result
    }
}

// MARK: - IGenreRepository
extension GenreRepositoryStub: IGenreRepository {
    func movieGenres() async throws -> [Genre] {
        calls.append(.movieGenres)
        return try result.get()
    }
}
