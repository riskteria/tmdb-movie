@testable import MovieApp
import Testing

struct PersonDetailsDTOTests {
    @Test
    func decodesMovieCreditsWithMovieAndCreditFields() throws {
        // Given
        let json = """
            {
                "id": 1190668,
                "imdb_id": "nm3154303",
                "name": "Timothée Chalamet",
                "also_known_as": [],
                "biography": "An American actor.",
                "birthday": "1995-12-27",
                "deathday": null,
                "place_of_birth": "New York City, New York, USA",
                "known_for_department": "Acting",
                "gender": 2,
                "homepage": null,
                "profile_path": "/profile.jpg",
                "popularity": 80.1,
                "adult": false,
                "movie_credits": {
                    "cast": [{
                        \(TMDBJSON.movieSummaryFields),
                        "credit_id": "5f0c8d9a",
                        "character": "Paul Atreides",
                        "order": 0
                    }],
                    "crew": []
                }
            }
            """

        // When
        let response = try TMDBJSON.decode(PersonDetailsDTO.Response.self, from: json)

        // Assert
        #expect(response.imdbID == "nm3154303")
        let credit = try #require(response.movieCredits?.cast.first)
        #expect(credit.movie.title == "Dune: Part Two")
        #expect(credit.creditID == "5f0c8d9a")
        #expect(credit.character == "Paul Atreides")
        #expect(response.images == nil)
    }
}
