import Foundation

protocol ISavedPresenter {
    func presentSavedMovies(response: SavedModel.ObserveSavedMovies.Response)
    func presentRemoveMovie(response: SavedModel.RemoveMovie.Response)
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
        switch response.state {
        case .signedOut:
            viewController?.displaySavedMovies(viewData: makeSignedOutViewData())
        case .signedIn(let savedMovies) where savedMovies.isEmpty:
            viewController?.displaySavedMovies(viewData: makeEmptyViewData(capacity: response.capacity))
        case .signedIn(let savedMovies):
            let count = savedMovies.count
            let header = String(localized: "\(count) of \(response.capacity) · the oldest is removed when full")
            let movies = savedMovies.map { makeDisplayedMovie(from: $0.movie) }
            viewController?.displaySavedMovies(viewData: .content(header: header, movies: movies))
        }
    }

    func presentRemoveMovie(response: SavedModel.RemoveMovie.Response) {
        let movie = response.movie
        switch response.result {
        case .success:
            viewController?.displayRemoveMovie(viewData: .removed(movie.id))
        case .failure:
            let message = String(localized: "Couldn't remove “\(movie.title)”")
            viewController?.displayRemoveMovie(viewData: .failure(movieID: movie.id, message: message))
        }
    }
}

private extension SavedPresenter {
    func makeSignedOutViewData() -> SavedModel.ObserveSavedMovies.ViewData {
        .signedOut(
            title: String(localized: "Sign in to see your saved movies"),
            message: String(
                localized: "Saved movies and Continue Watching are kept with your TMDB account on this device."
            )
        )
    }

    func makeEmptyViewData(capacity: Int) -> SavedModel.ObserveSavedMovies.ViewData {
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
