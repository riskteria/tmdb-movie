import Foundation

// What a Presenter hands a cell for one piece of artwork: the image URL, if any, plus what the
// generated placeholder needs until (or instead of) the image.
nonisolated struct DisplayedArtwork: Hashable, Sendable {
    let url: URL?
    let placeholderSeed: Int
    let placeholderTitle: String?
}

nonisolated extension DisplayedArtwork {
    init(
        path: ImagePath?,
        size: ImageSize,
        placeholderSeed: Int,
        placeholderTitle: String?,
        imageURLProvider: any ImageURLProviding
    ) {
        self.init(
            url: path.flatMap { imageURLProvider.url(for: $0, size: size) },
            placeholderSeed: placeholderSeed,
            placeholderTitle: placeholderTitle
        )
    }
}
