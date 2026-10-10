import MovieAppDS
import UIKit

protocol IMovieDetailViewController: AnyObject {
    func displayDetails(viewData: MovieDetailModel.LoadDetails.ViewData)
}

final class MovieDetailViewController: UIViewController {
    private let interactor: any IMovieDetailInteractor
    private let imageLoader: any ImageLoading
    private var loadTask: Task<Void, Never>?

    private lazy var detailView = MovieDetailView()

    init(interactor: any IMovieDetailInteractor, imageLoader: any ImageLoading) {
        self.interactor = interactor
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    isolated deinit {
        loadTask?.cancel()
    }

    override func loadView() {
        view = detailView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        loadDetails()
    }
}

private extension MovieDetailViewController {
    func loadDetails() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            await interactor.loadDetails(request: MovieDetailModel.LoadDetails.Request())
        }
    }
}

// MARK: - IMovieDetailViewController
extension MovieDetailViewController: IMovieDetailViewController {
    func displayDetails(viewData: MovieDetailModel.LoadDetails.ViewData) {
        switch viewData {
        case .loading(let detail), .content(let detail):
            contentUnavailableConfiguration = nil
            detailView.configure(with: detail, imageLoader: imageLoader)
        case .failure(let message):
            var configuration = UIContentUnavailableConfiguration.failure(
                message: message,
                retryTitle: String(localized: "Retry")
            ) { [weak self] in
                self?.loadDetails()
            }
            configuration.background.backgroundColor = .MVColor(.backgroundPrimary)
            contentUnavailableConfiguration = configuration
        }
    }
}
