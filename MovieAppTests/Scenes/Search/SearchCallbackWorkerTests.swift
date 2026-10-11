@testable import MovieApp
import Testing

struct SearchCallbackWorkerTests {
    @Test
    func fetchGenresDeliversMovieGenres() async throws {
        // Given
        let genres = [Genre.scienceFiction, Genre.drama]
        let sut: any ISearchCallbackWorker = SearchCallbackWorker(
            genreRepository: CallbackGenreRepositoryStub(result: .success(genres))
        )

        // When
        let result = await fetchGenres(from: sut)

        // Assert
        #expect(try result.get() == genres)
    }

    @Test
    func fetchGenresDeliversRepositoryError() async {
        // Given
        let sut: any ISearchCallbackWorker = SearchCallbackWorker(
            genreRepository: CallbackGenreRepositoryStub(result: .failure(StubError.failed))
        )

        // When
        let result = await fetchGenres(from: sut)

        // Assert
        #expect(throws: StubError.failed) {
            try result.get()
        }
    }

    private func fetchGenres(from worker: any ISearchCallbackWorker) async -> Result<[Genre], any Error> {
        await withCheckedContinuation { continuation in
            worker.fetchGenres { result in
                continuation.resume(returning: result)
            }
        }
    }
}
