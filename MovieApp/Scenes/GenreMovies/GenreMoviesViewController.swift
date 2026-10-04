import MovieAppDS
import UIKit

protocol IGenreMoviesViewController: AnyObject {
    func displayMovies(viewData: GenreMoviesModel.LoadNextPage.ViewData)
}

final class GenreMoviesViewController: UIViewController {
    private enum Layout {
        static let nextPageThreshold = 6
    }

    private let interactor: any IGenreMoviesInteractor
    private let router: any IGenreMoviesRouter
    private let imageLoader: any ImageLoading
    private var loadTask: Task<Void, Never>?
    private var loadMoreFooter = GenreMoviesModel.LoadMoreFooter.hidden

    private lazy var collectionView = makeCollectionView()
    private lazy var dataSource = makeDataSource()

    init(
        title: String,
        interactor: any IGenreMoviesInteractor,
        router: any IGenreMoviesRouter,
        imageLoader: any ImageLoading
    ) {
        self.interactor = interactor
        self.router = router
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    isolated deinit {
        loadTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        setUpLayout()
        loadNextPage()
    }
}

private extension GenreMoviesViewController {
    func loadNextPage() {
        guard loadTask == nil else { return }
        loadTask = Task { [weak self, interactor] in
            await interactor.loadNextPage(request: GenreMoviesModel.LoadNextPage.Request())
            self?.loadTask = nil
        }
    }

    func refreshMovies() {
        if loadTask != nil {
            collectionView.refreshControl?.endRefreshing()
            return
        }
        loadTask = Task { [weak self, interactor] in
            await interactor.refreshMovies(request: GenreMoviesModel.RefreshMovies.Request())
            self?.collectionView.refreshControl?.endRefreshing()
            self?.loadTask = nil
        }
    }

    func configureLoadMoreFooter(_ footerView: LoadMoreFooterView) {
        footerView.configure(with: loadMoreFooter, retryTitle: String(localized: "Retry")) { [weak self] in
            self?.loadNextPage()
        }
    }

    func refreshVisibleLoadMoreFooter() {
        guard let footerView = collectionView.supplementaryView(
            forElementKind: UICollectionView.elementKindSectionFooter,
            at: IndexPath(item: 0, section: 0)
        ) as? LoadMoreFooterView else { return }
        configureLoadMoreFooter(footerView)
    }
}

// MARK: - IGenreMoviesViewController
extension GenreMoviesViewController: IGenreMoviesViewController {
    func displayMovies(viewData: GenreMoviesModel.LoadNextPage.ViewData) {
        switch viewData {
        case .loading:
            contentUnavailableConfiguration = UIContentUnavailableConfiguration.loading()
        case let .content(movies, footer):
            contentUnavailableConfiguration = nil
            loadMoreFooter = footer
            var snapshot = NSDiffableDataSourceSnapshot<Int, GenreMoviesModel.DisplayedMovie>()
            snapshot.appendSections([0])
            snapshot.appendItems(movies)
            dataSource.apply(snapshot)
            refreshVisibleLoadMoreFooter()
        case .empty(let message):
            contentUnavailableConfiguration = UIContentUnavailableConfiguration.message(
                message,
                systemImage: "film.stack"
            )
        case .failure(let message):
            contentUnavailableConfiguration = UIContentUnavailableConfiguration.failure(
                message: message,
                retryTitle: String(localized: "Retry")
            ) { [weak self] in
                self?.loadNextPage()
            }
        }
    }
}

// MARK: - UICollectionViewDelegate
extension GenreMoviesViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        let remainingItems = dataSource.snapshot().numberOfItems - indexPath.item
        guard loadMoreFooter == .hidden, remainingItems <= Layout.nextPageThreshold else { return }
        loadNextPage()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let movie = dataSource.itemIdentifier(for: indexPath)?.movie else { return }
        router.routeToMovieDetail(movie: movie)
    }
}

// MARK: - Layout
private extension GenreMoviesViewController {
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
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.backgroundColor = .MVColor(.backgroundPrimary)
        collectionView.delegate = self
        collectionView.refreshControl = makeRefreshControl()
        return collectionView
    }

    func makeRefreshControl() -> UIRefreshControl {
        let refreshControl = UIRefreshControl()
        refreshControl.addAction(UIAction { [weak self] _ in self?.refreshMovies() }, for: .valueChanged)
        return refreshControl
    }

    func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { _, environment in
            let columns = environment.traitCollection.horizontalSizeClass == .regular ? 4 : 2
            let posterSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1 / CGFloat(columns)),
                heightDimension: .fractionalHeight(1)
            )
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalWidth(1.5 / CGFloat(columns))
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                repeatingSubitem: NSCollectionLayoutItem(layoutSize: posterSize),
                count: columns
            )
            group.interItemSpacing = .fixed(Spacing.small)
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = Spacing.small
            section.contentInsets = NSDirectionalEdgeInsets(
                top: Spacing.small,
                leading: Spacing.large,
                bottom: Spacing.xLarge,
                trailing: Spacing.large
            )
            let footerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(64)
            )
            section.boundarySupplementaryItems = [
                NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: footerSize,
                    elementKind: UICollectionView.elementKindSectionFooter,
                    alignment: .bottom
                )
            ]
            return section
        }
    }

    func makeDataSource() -> UICollectionViewDiffableDataSource<Int, GenreMoviesModel.DisplayedMovie> {
        typealias PosterRegistration = UICollectionView.CellRegistration<PosterCell, GenreMoviesModel.DisplayedMovie>
        let posterRegistration = PosterRegistration { [imageLoader] cell, _, movie in
            cell.configure(
                title: movie.title,
                artwork: movie.artwork,
                showsPlayBadge: false,
                rating: movie.rating,
                imageLoader: imageLoader
            )
        }
        let footerRegistration = UICollectionView.SupplementaryRegistration<LoadMoreFooterView>(
            elementKind: UICollectionView.elementKindSectionFooter
        ) { [weak self] footerView, _, _ in
            self?.configureLoadMoreFooter(footerView)
        }
        let dataSource = UICollectionViewDiffableDataSource<Int, GenreMoviesModel.DisplayedMovie>(
            collectionView: collectionView
        ) { collectionView, indexPath, movie in
            collectionView.dequeueConfiguredReusableCell(using: posterRegistration, for: indexPath, item: movie)
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: footerRegistration, for: indexPath)
        }
        return dataSource
    }
}
