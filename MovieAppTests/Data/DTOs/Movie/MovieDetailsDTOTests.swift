@testable import MovieApp
import Testing

struct MovieDetailsDTOTests {
    @Test
    func decodesTopLevelDetails() throws {
        // When
        let response = try TMDBJSON.decode(MovieDetailsDTO.Response.self, from: makeJSON())

        // Assert
        #expect(response.id == 693134)
        #expect(response.imdbID == "tt15239678")
        #expect(response.belongsToCollection?.name == "Dune Collection")
        #expect(response.productionCountries.first?.countryCode == "US")
        #expect(response.spokenLanguages.first?.languageCode == "en")
        #expect(response.credits == nil)
    }

    @Test
    func decodesAppendedResponses() throws {
        // Given
        let json = makeJSON(appending: """
            "credits": {
                "cast": [{
                    "id": 1190668, "credit_id": "5f0c8d9a", "name": "Timothée Chalamet",
                    "original_name": "Timothée Chalamet", "character": "Paul Atreides", "order": 0,
                    "profile_path": null, "known_for_department": "Acting", "gender": 2,
                    "popularity": 80.1, "adult": false
                }],
                "crew": []
            },
            "watch/providers": {
                "results": {
                    "US": {
                        "link": "https://www.themoviedb.org/movie/693134/watch?locale=US",
                        "flatrate": [{
                            "provider_id": 1899, "provider_name": "Max", "logo_path": "/max.jpg", "display_priority": 2
                        }]
                    }
                }
            },
            "account_states": { "favorite": true, "watchlist": false, "rated": { "value": 8.5 } }
            """)

        // When
        let response = try TMDBJSON.decode(MovieDetailsDTO.Response.self, from: json)

        // Assert
        let castMember = try #require(response.credits?.cast.first)
        #expect(castMember.creditID == "5f0c8d9a")
        #expect(castMember.character == "Paul Atreides")
        let provider = try #require(response.watchProviders?.results["US"]?.flatrate?.first)
        #expect(provider.providerID == 1899)
        let accountStates = try #require(response.accountStates)
        #expect(accountStates.isFavorite)
        #expect(!accountStates.isOnWatchlist)
        #expect(accountStates.rating == 8.5)
    }

    @Test
    func decodesUnratedAccountStatesAsNilRating() throws {
        // Given
        let json = makeJSON(appending: #""account_states": { "favorite": false, "watchlist": true, "rated": false }"#)

        // When
        let response = try TMDBJSON.decode(MovieDetailsDTO.Response.self, from: json)

        // Assert
        let accountStates = try #require(response.accountStates)
        #expect(accountStates.rating == nil)
        #expect(accountStates.isOnWatchlist)
    }
}

private extension MovieDetailsDTOTests {
    func makeJSON(appending appendedFields: String? = nil) -> String {
        let appended = appendedFields.map { ",\n\($0)" } ?? ""
        return """
            {
                "id": 693134,
                "imdb_id": "tt15239678",
                "title": "Dune: Part Two",
                "original_title": "Dune: Part Two",
                "original_language": "en",
                "overview": "Follow the mythic journey of Paul Atreides.",
                "tagline": "Long live the fighters.",
                "status": "Released",
                "release_date": "2024-02-27",
                "runtime": 167,
                "budget": 190000000,
                "revenue": 714444358,
                "homepage": "https://www.dunemovie.com",
                "poster_path": "/poster.jpg",
                "backdrop_path": "/backdrop.jpg",
                "belongs_to_collection": {
                    "id": 726871, "name": "Dune Collection", "poster_path": null, "backdrop_path": null
                },
                "genres": [{ "id": 878, "name": "Science Fiction" }],
                "origin_country": ["US"],
                "production_companies": [
                    { "id": 923, "name": "Legendary Pictures", "logo_path": "/logo.png", "origin_country": "US" }
                ],
                "production_countries": [{ "iso_3166_1": "US", "name": "United States of America" }],
                "spoken_languages": [{ "iso_639_1": "en", "name": "English", "english_name": "English" }],
                "popularity": 512.4,
                "vote_average": 8.2,
                "vote_count": 6123,
                "adult": false,
                "video": false\(appended)
            }
            """
    }
}
