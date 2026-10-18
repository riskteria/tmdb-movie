import UIKit

protocol MovieDetailFactory {
    func makeMovieDetail(
        movie: Movie,
        onSelectMovie: @escaping (Movie) -> Void,
        onWatchTrailer: @escaping (Video) -> Void,
        onShare: @escaping (Movie) -> Void
    ) -> UIViewController
}

protocol TrailerFactory {
    func makeTrailer(video: Video) -> UIViewController?
}

protocol ShareFactory {
    func makeShareSheet(movie: Movie) -> UIViewController?
}

enum MovieDetailTransition {
    case push
    case zoom
}

protocol MovieDetailNavigator: AnyObject {
    func showDetail(for movie: Movie, transition: MovieDetailTransition)
}

final class MovieDetailFlow {
    typealias Dependencies = MovieDetailFactory & TrailerFactory & ShareFactory

    private weak var navigationController: UINavigationController?
    private let dependencies: any Dependencies

    init(navigationController: UINavigationController, dependencies: any Dependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }
}

// MARK: - MovieDetailNavigator
extension MovieDetailFlow: MovieDetailNavigator {
    func showDetail(for movie: Movie, transition: MovieDetailTransition) {
        let detail = dependencies.makeMovieDetail(
            movie: movie,
            onSelectMovie: { [weak self] recommendation in
                self?.showDetail(for: recommendation, transition: .push)
            },
            onWatchTrailer: { [weak self] video in
                self?.showTrailer(video)
            },
            onShare: { [weak self] sharedMovie in
                self?.showShare(for: sharedMovie)
            }
        )
        if transition == .zoom, !UIAccessibility.isReduceMotionEnabled {
            let movieID = movie.id
            detail.preferredTransition = .zoom { context -> UIView? in
                let source = context.sourceViewController as? any ZoomTransitionSourceProvider
                return source?.zoomTransitionSourceView(for: movieID)
            }
        }
        navigationController?.pushViewController(detail, animated: true)
    }
}

private extension MovieDetailFlow {
    func showTrailer(_ video: Video) {
        guard let trailer = dependencies.makeTrailer(video: video) else { return }
        trailer.modalPresentationStyle = .fullScreen
        if UIAccessibility.isReduceMotionEnabled {
            trailer.modalTransitionStyle = .crossDissolve
        }
        navigationController?.present(trailer, animated: true)
    }

    func showShare(for movie: Movie) {
        guard let navigationController, let sheet = dependencies.makeShareSheet(movie: movie) else { return }
        let source = navigationController.topViewController as? any ShareSourceProvider
        sheet.popoverPresentationController?.sourceItem = source?.shareSourceItem ?? navigationController.navigationBar
        navigationController.present(sheet, animated: true)
    }
}
