import MovieAppDS
import UIKit

protocol ISavedViewController: AnyObject {
    func displaySavedMovies(viewData: SavedModel.ObserveSavedMovies.ViewData)
}

final class SavedViewController: UIViewController {
    private let interactor: any ISavedInteractor
    private let router: any ISavedRouter
    private let imageLoader: any IImageLoader
    private var observeTask: Task<Void, Never>?
    private var header = ""

    private lazy var collectionView = makeCollectionView()
    private lazy var dataSource = makeDataSource()

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
        observeTask = Task { [weak self] in
            guard let self else { return }
            await interactor.observeSavedMovies(request: SavedModel.ObserveSavedMovies.Request())
        }
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
            let configuration = UIContentUnavailableConfiguration.message(
                title,
                secondaryText: message,
                systemImage: "bookmark"
            )
            contentUnavailableConfiguration = configuration
        }
        dataSource.apply(snapshot)
        // The header text can change while the section stays the same.
        if let headerView = collectionView.supplementaryView(
            forElementKind: UICollectionView.elementKindSectionHeader,
            at: IndexPath(item: 0, section: 0)
        ) as? UICollectionViewListCell {
            headerView.contentConfiguration = makeHeaderConfiguration()
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
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.showsSeparators = false
        configuration.headerMode = .supplementary
        configuration.backgroundColor = .MVColor(.backgroundPrimary)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .MVColor(.backgroundPrimary)
        collectionView.delegate = self
        return collectionView
    }

    func makeHeaderConfiguration() -> UIListContentConfiguration {
        var configuration = UIListContentConfiguration.header()
        configuration.text = header
        configuration.textProperties.font = .MVFont(.footnote)
        configuration.textProperties.color = .MVColor(.textSecondary)
        configuration.directionalLayoutMargins.leading = Spacing.large
        return configuration
    }

    func makeDataSource() -> UICollectionViewDiffableDataSource<Int, SavedModel.DisplayedMovie> {
        typealias RowRegistration = UICollectionView.CellRegistration<MediaRowCell, SavedModel.DisplayedMovie>
        let rowRegistration = RowRegistration { [imageLoader] cell, _, movie in
            cell.configure(
                title: movie.title,
                metadata: movie.metadata,
                rating: movie.rating,
                artwork: movie.artwork,
                imageLoader: imageLoader
            )
        }
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] header, _, _ in
            header.contentConfiguration = self?.makeHeaderConfiguration()
        }
        let dataSource = UICollectionViewDiffableDataSource<Int, SavedModel.DisplayedMovie>(
            collectionView: collectionView
        ) { collectionView, indexPath, movie in
            collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: movie)
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        return dataSource
    }
}
