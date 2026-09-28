@testable import MovieApp
import Testing

struct AccountDetailsDTOTests {
    @Test
    func decodesAccountDetails() throws {
        // Given
        let json = """
            {
                "avatar": {
                    "gravatar": { "hash": "c9e9fc152ee756a900db85757c29815d" },
                    "tmdb": { "avatar_path": null }
                },
                "id": 548,
                "iso_639_1": "en",
                "iso_3166_1": "CA",
                "name": "Travis Bell",
                "include_adult": false,
                "username": "travisbell"
            }
            """

        // When
        let response = try TMDBJSON.decode(AccountDetailsDTO.Response.self, from: json)

        // Assert
        #expect(response.id == 548)
        #expect(response.languageCode == "en")
        #expect(response.countryCode == "CA")
        #expect(response.avatar.tmdb.avatarPath == nil)
    }
}
