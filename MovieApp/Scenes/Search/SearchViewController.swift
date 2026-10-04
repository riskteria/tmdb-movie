import MovieAppDS
import UIKit

protocol ISearchViewController: AnyObject {
    func displayGenres(viewData: SearchModel.LoadGenres.ViewData)
}

final class SearchViewController: UIViewController {
    private let interactor: any ISearchInteractor
    private let router: any ISearchRouter
    private var loadTask: Task<Void, Never>?
    private var content: SearchModel.DisplayedContent?

    private lazy var collectionView = makeCollectionView()
    private lazy var dataSource = makeDataSource()

    init(interactor: any ISearchInteractor, router: any ISearchRouter) {
        self.interactor = interactor
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    isolated deinit {
        loadTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Search")
        setUpSearch()
        setUpLayout()
        loadGenres()
    }
}

private extension SearchViewController {
    func loadGenres() {
        loadTask?.cancel()
        contentUnavailableConfiguration = UIContentUnavailableConfiguration.loading()
        loadTask = Task { [interactor] in
            await interactor.loadGenres(request: SearchModel.LoadGenres.Request())
        }
    }

    func refreshGenres() {
        loadTask?.cancel()
        loadTask = Task { [weak self, interactor] in
            await interactor.loadGenres(request: SearchModel.LoadGenres.Request())
            self?.collectionView.refreshControl?.endRefreshing()
        }
    }
}

// MARK: - ISearchViewController
extension SearchViewController: ISearchViewController {
    func displayGenres(viewData: SearchModel.LoadGenres.ViewData) {
        switch viewData {
        case .content(let content):
            self.content = content
            contentUnavailableConfiguration = nil
            var snapshot = NSDiffableDataSourceSnapshot<Int, SearchModel.DisplayedGenre>()
            snapshot.appendSections([0])
            snapshot.appendItems(content.genres)
            dataSource.apply(snapshot)
            refreshVisibleHeader()
        case .empty(let message):
            contentUnavailableConfiguration = UIContentUnavailableConfiguration.message(
                message,
                systemImage: "square.grid.2x2"
            )
        case .failure(let message):
            let retryTitle = String(localized: "Retry")
            let configuration = UIContentUnavailableConfiguration.failure(
                message: message,
                retryTitle: retryTitle
            ) { [weak self] in
                self?.loadGenres()
            }
            contentUnavailableConfiguration = configuration
        }
    }
}

// MARK: - UICollectionViewDelegate
extension SearchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let genre = dataSource.itemIdentifier(for: indexPath)?.genre else { return }
        router.routeToGenreMovies(genre: genre)
    }
}

// MARK: - Layout
private extension SearchViewController {
    func setUpSearch() {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = String(localized: "Search movies")
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.preferredSearchBarPlacement = .stacked
    }

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
        collectionView.refreshControl = makeRefreshControl()
        collectionView.delegate = self
        return collectionView
    }

    // Two columns on compact width, four on regular.
    func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { _, environment in
            let columns = environment.traitCollection.horizontalSizeClass == .regular ? 4 : 2
            let cardSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1 / CGFloat(columns)),
                heightDimension: .fractionalHeight(1)
            )
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalWidth(10 / 16 / CGFloat(columns))
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                repeatingSubitem: NSCollectionLayoutItem(layoutSize: cardSize),
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
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(28)
            )
            section.boundarySupplementaryItems = [
                NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
            ]
            return section
        }
    }

    func makeDataSource() -> UICollectionViewDiffableDataSource<Int, SearchModel.DisplayedGenre> {
        typealias CardRegistration = UICollectionView.CellRegistration<GenreCardCell, SearchModel.DisplayedGenre>
        let cardRegistration = CardRegistration { cell, _, genre in
            cell.configure(name: genre.name, genreID: genre.id)
        }
        let headerRegistration = UICollectionView.SupplementaryRegistration<SectionHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] header, _, _ in
            self?.configureHeader(header)
        }
        let dataSource = UICollectionViewDiffableDataSource<Int, SearchModel.DisplayedGenre>(
            collectionView: collectionView
        ) { collectionView, indexPath, genre in
            collectionView.dequeueConfiguredReusableCell(using: cardRegistration, for: indexPath, item: genre)
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        return dataSource
    }

    func makeRefreshControl() -> UIRefreshControl {
        let refreshControl = UIRefreshControl()
        refreshControl.addAction(
            UIAction { [weak self] _ in
                self?.refreshGenres()
            },
            for: .valueChanged
        )
        return refreshControl
    }

    func configureHeader(_ header: SectionHeaderView) {
        header.configure(title: content?.sectionTitle ?? "", count: content?.count)
    }

    func refreshVisibleHeader() {
        guard let header = collectionView.supplementaryView(
            forElementKind: UICollectionView.elementKindSectionHeader,
            at: IndexPath(item: 0, section: 0)
        ) as? SectionHeaderView else { return }
        configureHeader(header)
    }
}
