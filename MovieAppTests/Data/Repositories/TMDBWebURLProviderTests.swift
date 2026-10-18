import Foundation
@testable import MovieApp
import Testing

struct TMDBWebURLProviderTests {
    private let sut: any WebURLProvider = TMDBWebURLProvider()

    @Test
    func movieURLPointsToTheMoviePage() {
        // When
        let url = sut.movieURL(for: 693134)

        // Assert
        #expect(url?.absoluteString == "https://www.themoviedb.org/movie/693134")
    }
}
