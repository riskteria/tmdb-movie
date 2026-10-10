import Foundation

protocol ISavedPresenter {
    func presentSavedMovies(response: SavedModel.ObserveSavedMovies.Response)
}

final class SavedPresenter {
    weak var viewController: (any ISavedViewController)?
    private let imageURLProvider: any ImageURLProvider

    init(imageURLProvider: any ImageURLProvider) {
        self.imageURLProvider = imageURLProvider
    }
}

// MARK: - ISavedPresenter
extension SavedPresenter: ISavedPresenter {
    func presentSavedMovies(response: SavedModel.ObserveSavedMovies.Response) {
        if response.savedMovies.isEmpty {
            viewController?.displaySavedMovies(viewData: makeEmptyViewModel(capacity: response.capacity))
            return
        }
        let count = response.savedMovies.count
        let header = String(localized: "\(count) of \(response.capacity) · the oldest is removed when full")
        let movies = response.savedMovies.map { makeDisplayedMovie(from: $0.movie) }
        viewController?.displaySavedMovies(viewData: .content(header: header, movies: movies))
    }
}

private extension SavedPresenter {
    func makeEmptyViewModel(capacity: Int) -> SavedModel.ObserveSavedMovies.ViewData {
        .empty(
            title: String(localized: "Save movies to watch later"),
            message: String(localized: "Tap Save on any movie. Up to \(capacity) stay on this device, even offline.")
        )
    }

    func makeDisplayedMovie(from movie: Movie) -> SavedModel.DisplayedMovie {
        SavedModel.DisplayedMovie(
            movie: movie,
            title: movie.title,
            metadata: movie.releaseDate?.formatted(.dateTime.year()) ?? "-",
            rating: movie.voteAverage > 0 ? movie.voteAverage.formatted(.number.precision(.fractionLength(1))) : nil,
            artwork: DisplayedArtwork(
                path: movie.backdropPath,
                size: .backdropMedium,
                placeholderSeed: movie.id,
                placeholderTitle: nil,
                imageURLProvider: imageURLProvider
            )
        )
    }
}
