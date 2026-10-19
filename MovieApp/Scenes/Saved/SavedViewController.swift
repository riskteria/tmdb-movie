import MovieAppDS
import UIKit

protocol ISavedViewController: AnyObject {
    func displaySavedMovies(viewData: SavedModel.ObserveSavedMovies.ViewData)
    func displayRemoveMovie(viewData: SavedModel.RemoveMovie.ViewData)
}

final class SavedViewController: UIViewController {
    typealias DataSource = UICollectionViewDiffableDataSource<Int, SavedModel.DisplayedMovie>

    private let interactor: any ISavedInteractor
    private let router: any ISavedRouter
    private let imageLoader: any IImageLoader
    private var observeTask: Task<Void, Never>?
    private var removeTasks: [Movie.ID: Task<Void, Never>] = [:]
    private var removalCompletions: [Movie.ID: (Bool) -> Void] = [:]
    private var header = ""

    private lazy var collectionView = makeCollectionView()
    private lazy var dataSource = makeDataSource()
    private lazy var toastView = StatusToastView()

    init(interactor: any ISavedInteractor, router: any ISavedRouter, imageLoader: any IImageLoader) {
        self.interactor = interactor
        self.router = router
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    isolated deinit {
        observeTask?.cancel()
        removeTasks.values.forEach { task in task.cancel() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Saved")
        setUpLayout()
        observeSavedMovies()
    }
}

private extension SavedViewController {
    func observeSavedMovies() {
        observeTask?.cancel()
        observeTask = Task { [interactor] in
            await interactor.observeSavedMovies(request: SavedModel.ObserveSavedMovies.Request())
        }
    }

    func remove(_ movie: Movie, completion: @escaping (Bool) -> Void) {
        guard removeTasks[movie.id] == nil else {
            completion(false)
            return
        }
        removalCompletions[movie.id] = completion
        removeTasks[movie.id] = Task { [weak self, interactor] in
            await interactor.removeMovie(request: SavedModel.RemoveMovie.Request(movie: movie))
            self?.completeRemoval(of: movie.id, isRemoved: false)
        }
    }

    func completeRemoval(of movieID: Movie.ID, isRemoved: Bool) {
        removeTasks[movieID] = nil
        removalCompletions.removeValue(forKey: movieID)?(isRemoved)
    }

    func makeRemoveAction(for movie: SavedModel.DisplayedMovie) -> UIContextualAction {
        let title = String(localized: "Remove")
        let action = UIContextualAction(style: .destructive, title: title) { [weak self] _, _, completion in
            self?.remove(movie.movie, completion: completion)
        }
        action.image = UIImage(systemName: "trash")
        return action
    }

    func makeAccessibilityRemoveAction(for movie: SavedModel.DisplayedMovie) -> UIAccessibilityCustomAction {
        UIAccessibilityCustomAction(name: String(localized: "Remove")) { [weak self] _ in
            self?.remove(movie.movie) { _ in }
            return true
        }
    }

    func updateHeader() {
        guard dataSource.snapshot().numberOfSections > 0 else { return }
        let headerView = collectionView.supplementaryView(
            forElementKind: UICollectionView.elementKindSectionHeader,
            at: IndexPath(item: 0, section: 0)
        ) as? UICollectionViewListCell
        headerView?.contentConfiguration = makeHeaderConfiguration()
    }
}

// MARK: - ISavedViewController
extension SavedViewController: ISavedViewController {
    func displaySavedMovies(viewData: SavedModel.ObserveSavedMovies.ViewData) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, SavedModel.DisplayedMovie>()
        switch viewData {
        case let .content(header, movies):
            self.header = header
            contentUnavailableConfiguration = nil
            snapshot.appendSections([0])
            snapshot.appendItems(movies)
        case let .empty(title, message):
            contentUnavailableConfiguration = UIContentUnavailableConfiguration.message(
                title,
                secondaryText: message,
                systemImage: "bookmark"
            )
        case let .signedOut(title, message):
            contentUnavailableConfiguration = UIContentUnavailableConfiguration.message(
                title,
                secondaryText: message,
                systemImage: "person.crop.circle"
            )
            Array(removalCompletions.keys).forEach { movieID in completeRemoval(of: movieID, isRemoved: false) }
        }
        dataSource.apply(snapshot, animatingDifferences: !UIAccessibility.isReduceMotionEnabled)
        updateHeader()
    }

    func displayRemoveMovie(viewData: SavedModel.RemoveMovie.ViewData) {
        switch viewData {
        case .removed(let movieID):
            completeRemoval(of: movieID, isRemoved: true)
        case let .failure(movieID, message):
            completeRemoval(of: movieID, isRemoved: false)
            toastView.show(message: message, in: view)
        }
    }
}

// MARK: - UICollectionViewDelegate
extension SavedViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let movie = dataSource.itemIdentifier(for: indexPath)?.movie else { return }
        router.routeToMovieDetail(movie: movie)
    }
}

// MARK: - Layout
private extension SavedViewController {
    func setUpLayout() {
        view.backgroundColor = .MVColor(.backgroundPrimary)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func makeCollectionView() -> UICollectionView {
        let layout = UICollectionViewCompositionalLayout.list(using: makeListConfiguration())
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .MVColor(.backgroundPrimary)
        collectionView.delegate = self
        return collectionView
    }

    func makeListConfiguration() -> UICollectionLayoutListConfiguration {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.showsSeparators = false
        configuration.backgroundColor = .MVColor(.backgroundPrimary)
        configuration.headerMode = .supplementary
        configuration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            guard let self, let movie = dataSource.itemIdentifier(for: indexPath) else { return nil }
            return UISwipeActionsConfiguration(actions: [makeRemoveAction(for: movie)])
        }
        return configuration
    }

    func makeHeaderConfiguration() -> UIListContentConfiguration {
        var configuration = UIListContentConfiguration.header()
        configuration.text = header
        configuration.textProperties.font = .MVFont(.footnote)
        configuration.textProperties.color = .MVColor(.textSecondary)
        configuration.directionalLayoutMargins.leading = Spacing.large
        return configuration
    }

    func makeDataSource() -> DataSource {
        typealias RowRegistration = UICollectionView.CellRegistration<MediaRowCell, SavedModel.DisplayedMovie>
        let rowRegistration = RowRegistration { [weak self, imageLoader] cell, _, movie in
            cell.configure(
                title: movie.title,
                metadata: movie.metadata,
                rating: movie.rating,
                artwork: movie.artwork,
                imageLoader: imageLoader
            )
            cell.accessibilityCustomActions = self.map { viewController in
                [viewController.makeAccessibilityRemoveAction(for: movie)]
            }
        }
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] header, _, _ in
            header.contentConfiguration = self?.makeHeaderConfiguration()
        }
        let dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, movie in
            collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: movie)
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        return dataSource
    }
}
