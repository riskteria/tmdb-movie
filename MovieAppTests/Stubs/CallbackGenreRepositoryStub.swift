@testable import MovieApp

struct CallbackGenreRepositoryStub: ICallbackGenreRepository {
    let result: Result<[Genre], any Error>

    func movieGenres(completion: @escaping @Sendable (Result<[Genre], any Error>) -> Void) {
        completion(result)
    }
}
