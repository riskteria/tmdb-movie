import UIKit

protocol IDiscoverViewController: AnyObject {
    func displayGenres(viewData: DiscoverModel.LoadGenres.ViewData)
}

// The Search tab's root, and the requirement's Discover area: a search field, then every genre.
// Typing (Week 3) and opening Genre Movies (Week 2) aren't wired yet.
final class DiscoverViewController: UIViewController {
    private let interactor: any IDiscoverInteractor
    private var loadTask: Task<Void, Never>?
    private var content: DiscoverModel.DisplayedContent?

    private lazy var collectionView = makeCollectionView()
    private lazy var dataSource = makeDataSource()

    init(interactor: any IDiscoverInteractor) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
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

private extension DiscoverViewController {
    func loadGenres() {
        loadTask?.cancel()
        contentUnavailableConfiguration = UIContentUnavailableConfiguration.loading()
        loadTask = Task { [interactor] in
            await interactor.loadGenres(request: DiscoverModel.LoadGenres.Request())
        }
    }
}

// MARK: - IDiscoverViewController
extension DiscoverViewController: IDiscoverViewController {
    func displayGenres(viewData: DiscoverModel.LoadGenres.ViewData) {
        switch viewData {
        case .content(let content):
            self.content = content
            contentUnavailableConfiguration = nil
            var snapshot = NSDiffableDataSourceSnapshot<Int, DiscoverModel.DisplayedGenre>()
            snapshot.appendSections([0])
            snapshot.appendItems(content.genres)
            dataSource.apply(snapshot)
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

// MARK: - Layout
private extension DiscoverViewController {
    func setUpSearch() {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = String(localized: "Search movies")
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.preferredSearchBarPlacement = .stacked
    }

    func setUpLayout() {
        view.backgroundColor = .backgroundPrimary
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
        collectionView.backgroundColor = .backgroundPrimary
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

    func makeDataSource() -> UICollectionViewDiffableDataSource<Int, DiscoverModel.DisplayedGenre> {
        typealias CardRegistration = UICollectionView.CellRegistration<GenreCardCell, DiscoverModel.DisplayedGenre>
        let cardRegistration = CardRegistration { cell, _, genre in
            cell.configure(name: genre.name, genreID: genre.id)
        }
        let headerRegistration = UICollectionView.SupplementaryRegistration<SectionHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] header, _, _ in
            header.configure(title: self?.content?.sectionTitle ?? "", count: self?.content?.count)
        }
        let dataSource = UICollectionViewDiffableDataSource<Int, DiscoverModel.DisplayedGenre>(
            collectionView: collectionView
        ) { collectionView, indexPath, genre in
            collectionView.dequeueConfiguredReusableCell(using: cardRegistration, for: indexPath, item: genre)
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        return dataSource
    }
}
