import UIKit

protocol MovieDetailFactory {
    func makeMovieDetail(movie: Movie) -> UIViewController
}

final class MovieDetailFlow {
    enum Transition {
        case push
        case zoom
    }

    private weak var navigationController: UINavigationController?
    private let dependencies: any MovieDetailFactory

    init(navigationController: UINavigationController, dependencies: any MovieDetailFactory) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func showDetail(for movie: Movie, transition: Transition) {
        let detail = dependencies.makeMovieDetail(movie: movie)
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
