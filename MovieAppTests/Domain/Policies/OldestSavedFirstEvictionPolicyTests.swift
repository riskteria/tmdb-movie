import Foundation
@testable import MovieApp
import Testing

struct OldestSavedFirstEvictionPolicyTests {
    private let sut: any SavedMoviesEvictionPolicy = OldestSavedFirstEvictionPolicy()
    private let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    @Test
    func evictsNothingAtCapacity() {
        // Given
        let savedMovies = makeSavedMovies(count: SavedMovie.capacity)

        // When
        let evicted = sut.moviesToEvict(from: savedMovies, capacity: SavedMovie.capacity)

        // Assert
        #expect(evicted.isEmpty)
    }

    @Test
    func evictsOldestWhenOverCapacity() {
        // Given
        let savedMovies = makeSavedMovies(count: SavedMovie.capacity + 1)

        // When
        let evicted = sut.moviesToEvict(from: savedMovies, capacity: SavedMovie.capacity)

        // Assert
        #expect(evicted == [1])
    }

    @Test
    func evictsSeveralWhenFarOverCapacity() {
        // Given
        let savedMovies = makeSavedMovies(count: SavedMovie.capacity + 3)

        // When
        let evicted = sut.moviesToEvict(from: savedMovies, capacity: SavedMovie.capacity)

        // Assert
        #expect(evicted == [1, 2, 3])
    }

    @Test
    func breaksSavedAtTiesByMovieID() {
        // Given
        let savedMovies = [
            SavedMovie(movie: .fixture(id: 8), savedAt: referenceDate),
            SavedMovie(movie: .fixture(id: 3), savedAt: referenceDate)
        ]

        // When
        let evicted = sut.moviesToEvict(from: savedMovies, capacity: 1)

        // Assert
        #expect(evicted == [3])
    }
}

private extension OldestSavedFirstEvictionPolicyTests {
    func makeSavedMovies(count: Int) -> [SavedMovie] {
        (1...count).reversed().map { movieID in
            SavedMovie(movie: .fixture(id: movieID), savedAt: referenceDate.addingTimeInterval(Double(movieID) * 60))
        }
    }
}
