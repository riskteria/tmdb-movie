@testable import MovieApp

struct GenreRepositoryStub: GenreRepository {
    let result: Result<[Genre], any Error>

    func movieGenres() async throws -> [Genre] {
        try result.get()
    }
}
