@testable import Networking
import Testing

struct AccountMoviesDTOTests {
    @Test
    func decodesRatedMovieWithAccountRating() throws {
        // Given
        let accountRating = #", "account_rating": { "created_at": "2024-03-01T10:00:00.000Z", "value": 9 }"#
        let json = makePageJSON(extraFields: accountRating)

        // When
        let response = try TMDBJSON.decode(AccountMoviesDTO.Response.self, from: json)

        // Assert
        let movie = try #require(response.results.first)
        #expect(movie.summary.id == 693134)
        #expect(movie.summary.genreIDs == [878, 12])
        #expect(movie.accountRating?.value == 9)
        #expect(response.totalResults == 1)
    }

    @Test
    func decodesMovieWithoutAccountRating() throws {
        // When
        let response = try TMDBJSON.decode(AccountMoviesDTO.Response.self, from: makePageJSON())

        // Assert
        let movie = try #require(response.results.first)
        #expect(movie.accountRating == nil)
    }
}

private extension AccountMoviesDTOTests {
    func makePageJSON(extraFields: String = "") -> String {
        """
        {
            "page": 1,
            "results": [{ \(TMDBJSON.movieSummaryFields)\(extraFields) }],
            "total_pages": 1,
            "total_results": 1
        }
        """
    }
}
