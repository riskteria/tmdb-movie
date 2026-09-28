@testable import MovieApp
import Testing

struct ConfigurationDTOTests {
    @Test
    func decodesImageBaseURLs() throws {
        // Given
        let json = """
            {
                "images": {
                    "base_url": "http://image.tmdb.org/t/p/",
                    "secure_base_url": "https://image.tmdb.org/t/p/",
                    "backdrop_sizes": ["w300", "original"],
                    "logo_sizes": ["w45"],
                    "poster_sizes": ["w92", "w500"],
                    "profile_sizes": ["w185"],
                    "still_sizes": ["w92"]
                },
                "change_keys": ["adult"]
            }
            """

        // When
        let response = try TMDBJSON.decode(ConfigurationDTO.Response.self, from: json)

        // Assert
        #expect(response.images.secureBaseURL == "https://image.tmdb.org/t/p/")
        #expect(response.images.posterSizes == ["w92", "w500"])
    }
}
