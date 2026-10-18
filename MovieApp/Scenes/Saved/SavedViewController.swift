import MovieAppDS
import UIKit

protocol ISavedViewController: AnyObject {
    func displaySavedMovies(viewData: SavedModel.ObserveSavedMovies.ViewData)
    func displayRemoveMovie(viewData: SavedModel.RemoveMovie.ViewData)
}

final class SavedViewController: UIViewController {
    typealias Section = SavedModel.Section
    typealias Item = SavedModel.Item
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>

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
        guard let section = dataSource.index(for: .movies) else { return }
        let headerView = collectionView.supplementaryView(
            forElementKind: UICollectionView.elementKindSectionHeader,
            at: IndexPath(item: 0, section: section)
        ) as? UICollectionViewListCell
        headerView?.contentConfiguration = makeHeaderConfiguration()
    }
}

// MARK: - ISavedViewController
extension SavedViewController: ISavedViewController {
    func displaySavedMovies(viewData: SavedModel.ObserveSavedMovies.ViewData) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        switch viewData {
        case let .content(header, banner, movies):
            self.header = header
            contentUnavailableConfiguration = nil
            if let banner {
                snapshot.appendSections([.banner])
                snapshot.appendItems([.banner(banner)], toSection: .banner)
            }
            snapshot.appendSections([.movies])
            snapshot.appendItems(movies.map(Item.movie), toSection: .movies)
        case let .empty(title, message):
            contentUnavailableConfiguration = UIContentUnavailableConfiguration.message(
                title,
                secondaryText: message,
                systemImage: "bookmark"
            )
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
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard case .movie = dataSource.itemIdentifier(for: indexPath) else { return false }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard case .movie(let movie) = dataSource.itemIdentifier(for: indexPath) else { return }
        router.routeToMovieDetail(movie: movie.movie)
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
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            let section = self?.dataSource.sectionIdentifier(for: sectionIndex)
            let configuration = self?.makeListConfiguration(for: section)
                ?? UICollectionLayoutListConfiguration(appearance: .plain)
            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        }
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .MVColor(.backgroundPrimary)
        collectionView.delegate = self
        return collectionView
    }

    func makeListConfiguration(for section: Section?) -> UICollectionLayoutListConfiguration {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.showsSeparators = false
        configuration.backgroundColor = .MVColor(.backgroundPrimary)
        configuration.headerMode = section == .movies ? .supplementary : .none
        configuration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            guard let self, case .movie(let movie) = dataSource.itemIdentifier(for: indexPath) else { return nil }
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

    func makeBannerConfiguration(for banner: SavedModel.DisplayedBanner) -> UIListContentConfiguration {
        var configuration = UIListContentConfiguration.subtitleCell()
        configuration.image = UIImage(systemName: "exclamationmark.triangle.fill")
        configuration.imageProperties.tintColor = .systemOrange
        configuration.text = banner.title
        configuration.textProperties.font = .MVFont(.rowTitle)
        configuration.textProperties.color = .MVColor(.textPrimary)
        configuration.secondaryText = banner.message
        configuration.secondaryTextProperties.font = .MVFont(.footnote)
        configuration.secondaryTextProperties.color = .MVColor(.textSecondary)
        return configuration
    }

    func makeBannerBackground() -> UIBackgroundConfiguration {
        var background = UIBackgroundConfiguration.listCell()
        background.backgroundColor = .MVColor(.backgroundSecondary)
        background.cornerRadius = Radius.medium
        background.backgroundInsets = NSDirectionalEdgeInsets(
            top: Spacing.xSmall,
            leading: Spacing.large,
            bottom: Spacing.xSmall,
            trailing: Spacing.large
        )
        return background
    }

    func makeDataSource() -> DataSource {
        typealias RowRegistration = UICollectionView.CellRegistration<MediaRowCell, SavedModel.DisplayedMovie>
        typealias BannerRegistration = UICollectionView.CellRegistration<
            UICollectionViewListCell,
            SavedModel.DisplayedBanner
        >
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
        let bannerRegistration = BannerRegistration { [weak self] cell, _, banner in
            guard let self else { return }
            var configuration = makeBannerConfiguration(for: banner)
            configuration.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: Spacing.medium,
                leading: Spacing.large + Spacing.medium,
                bottom: Spacing.medium,
                trailing: Spacing.large + Spacing.medium
            )
            cell.contentConfiguration = configuration
            cell.backgroundConfiguration = makeBannerBackground()
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = "\(banner.title), \(banner.message)"
        }
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] header, _, _ in
            header.contentConfiguration = self?.makeHeaderConfiguration()
        }
        let dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .banner(let banner):
                collectionView.dequeueConfiguredReusableCell(using: bannerRegistration, for: indexPath, item: banner)
            case .movie(let movie):
                collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: movie)
            }
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        return dataSource
    }
}
