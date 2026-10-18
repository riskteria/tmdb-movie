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
        let banner = response.isPersistent ? nil : makeStorageBanner()
        if response.savedMovies.isEmpty {
            viewController?.displaySavedMovies(viewData: makeEmptyViewData(capacity: response.capacity, banner: banner))
            return
        }
        let count = response.savedMovies.count
        let header = response.isPersistent
            ? String(localized: "\(count) of \(response.capacity) · the oldest is removed when full")
            : String(localized: "\(count) of \(response.capacity) · saved since the app opened")
        let movies = response.savedMovies.map { makeDisplayedMovie(from: $0.movie) }
        viewController?.displaySavedMovies(viewData: .content(header: header, banner: banner, movies: movies))
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
    func makeStorageBanner() -> SavedModel.DisplayedBanner {
        SavedModel.DisplayedBanner(
            title: String(localized: "Saved movies can't be loaded"),
            message: String(localized: "You can still save movies, but they'll be lost when you close the app.")
        )
    }

    func makeEmptyViewData(capacity: Int, banner: SavedModel.DisplayedBanner?) -> SavedModel.ObserveSavedMovies.ViewData {
        if let banner {
            return .empty(title: banner.title, message: banner.message)
        }
        return .empty(
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
