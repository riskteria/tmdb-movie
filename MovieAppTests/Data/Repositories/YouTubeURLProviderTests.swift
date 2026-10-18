import Foundation
@testable import MovieApp
import Testing

struct YouTubeURLProviderTests {
    private let sut: any VideoURLProvider = YouTubeURLProvider()

    @Test
    func thumbnailURLUsesTheHighQualityDefaultImage() {
        // When
        let url = sut.thumbnailURL(for: .fixture(key: "Way9Dexny3w"))

        // Assert
        #expect(url?.absoluteString == "https://img.youtube.com/vi/Way9Dexny3w/hqdefault.jpg")
    }

    @Test
    func watchURLOpensTheVideoOnYouTube() {
        // When
        let url = sut.watchURL(for: .fixture(key: "Way9Dexny3w"))

        // Assert
        #expect(url?.absoluteString == "https://www.youtube.com/watch?v=Way9Dexny3w")
    }
}
