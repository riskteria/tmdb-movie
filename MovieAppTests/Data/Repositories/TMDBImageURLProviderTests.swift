import Foundation
@testable import MovieApp
import Testing

struct TMDBImageURLProviderTests {
    private let sut = TMDBImageURLProvider()

    @Test(
        arguments: [
            (ImageSize.posterSmall, "w185"),
            (ImageSize.posterMedium, "w500"),
            (ImageSize.backdropMedium, "w780"),
            (ImageSize.backdropLarge, "w1280"),
            (ImageSize.profile, "w185")
        ]
    )
    func buildsSecureURLForSize(size: ImageSize, sizeName: String) {
        // When
        let url = sut.url(for: ImagePath(rawValue: "/poster.jpg"), size: size)

        // Assert
        #expect(url?.absoluteString == "https://image.tmdb.org/t/p/\(sizeName)/poster.jpg")
    }
}
