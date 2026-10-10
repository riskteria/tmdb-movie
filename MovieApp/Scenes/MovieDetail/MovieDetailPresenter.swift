import Foundation

protocol IMovieDetailPresenter {
    func presentDetails(response: MovieDetailModel.LoadDetails.Response)
}

final class MovieDetailPresenter {
    weak var viewController: (any IMovieDetailViewController)?
    private let imageURLProvider: any ImageURLProvider

    init(imageURLProvider: any ImageURLProvider) {
        self.imageURLProvider = imageURLProvider
    }
}

// MARK: - IMovieDetailPresenter
extension MovieDetailPresenter: IMovieDetailPresenter {
    func presentDetails(response: MovieDetailModel.LoadDetails.Response) {
        switch response.details {
        case nil:
            viewController?.displayDetails(viewData: .loading(makeDetail(from: response.movie, details: nil)))
        case .success(let details):
            viewController?.displayDetails(viewData: .content(makeDetail(from: details.movie, details: details)))
        case .failure:
            viewController?.displayDetails(viewData: .failure(message: String(localized: "Unable to load this movie")))
        }
    }
}

private extension MovieDetailPresenter {
    // "2024 • Science Fiction, Adventure • 2h 46m • PG-13". Only the year is known before details load.
    func makeDetail(from movie: Movie, details: MovieDetails?) -> MovieDetailModel.DisplayedDetail {
        let parts = [
            movie.releaseDate?.formatted(.dateTime.year()),
            details.map { $0.genres.prefix(2).map(\.name).joined(separator: ", ") },
            details?.runtime?.formatted(.units(allowed: [.hours, .minutes], width: .narrow)),
            details?.certification
        ]
        return MovieDetailModel.DisplayedDetail(
            title: movie.title,
            metadata: parts.compactMap(\.self).filter { !$0.isEmpty }.joined(separator: " • "),
            overview: movie.overview,
            artwork: DisplayedArtwork(
                path: movie.backdropPath,
                size: .backdropLarge,
                placeholderSeed: movie.id,
                placeholderTitle: nil,
                imageURLProvider: imageURLProvider
            )
        )
    }
}
