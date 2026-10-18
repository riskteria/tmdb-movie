@testable import MovieApp
import Testing

struct MovieDetailsTests {
    @Test
    func mainTrailerIsTheFirstOfficialTrailer() {
        // Given
        let officialTrailer = Video.fixture(key: "official-trailer")
        let details = MovieDetails.fixture(
            videos: [
                .fixture(key: "fan-trailer", isOfficial: false),
                .fixture(key: "teaser", kind: .teaser),
                officialTrailer
            ]
        )

        // Assert
        #expect(details.mainTrailer == officialTrailer)
    }

    @Test
    func mainTrailerFallsBackToTheFirstVideo() {
        // Given
        let teaser = Video.fixture(key: "teaser", kind: .teaser)
        let details = MovieDetails.fixture(videos: [teaser, .fixture(key: "fan-trailer", isOfficial: false)])

        // Assert
        #expect(details.mainTrailer == teaser)
    }

    @Test
    func mainTrailerIsNilWithoutVideos() {
        // Given
        let details = MovieDetails.fixture(videos: [])

        // Assert
        #expect(details.mainTrailer == nil)
    }
}
