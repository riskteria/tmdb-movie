import MovieAppDS
import UIKit

protocol IMovieDetailViewController: AnyObject {
    func displayDetails(viewData: MovieDetailModel.LoadDetails.ViewData)
}

final class MovieDetailViewController: UIViewController {
    typealias Section = MovieDetailLayout.Section
    typealias Item = MovieDetailLayout.Item
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    private enum Tab: Int {
        case moreLikeThis
        case trailers
    }

    private let interactor: any IMovieDetailInteractor
    private let router: any IMovieDetailRouter
    private let imageLoader: any IImageLoader
    private let layout = MovieDetailLayout()
    private let fixedItems: [Item] = [.header, .actions, .rating, .synopsis, .tabs]
    private var loadTask: Task<Void, Never>?
    private var detail: MovieDetailModel.DisplayedDetail?
    private var extras: MovieDetailModel.DisplayedExtras?
    private var selectedTab = Tab.moreLikeThis
    private var isSynopsisExpanded = false

    private lazy var collectionView = makeCollectionView()
    private lazy var dataSource = makeDataSource()

    init(interactor: any IMovieDetailInteractor, router: any IMovieDetailRouter, imageLoader: any IImageLoader) {
        self.interactor = interactor
        self.router = router
        self.imageLoader = imageLoader
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
        navigationItem.largeTitleDisplayMode = .never
        setUpLayout()
        loadDetails()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        collectionView.contentInset.bottom = view.safeAreaInsets.bottom + Spacing.xLarge
        collectionView.verticalScrollIndicatorInsets.bottom = view.safeAreaInsets.bottom
    }
}

private extension MovieDetailViewController {
    func loadDetails() {
        loadTask?.cancel()
        loadTask = Task { [interactor] in
            await interactor.loadDetails(request: MovieDetailModel.LoadDetails.Request())
        }
    }

    func show(detail: MovieDetailModel.DisplayedDetail, extras: MovieDetailModel.DisplayedExtras?) {
        contentUnavailableConfiguration = nil
        self.detail = detail
        self.extras = extras
        applySnapshot()
    }

    func applySnapshot() {
        guard let detail else { return }
        var snapshot = Snapshot()
        append([.header], to: .header, in: &snapshot)
        append([.actions], to: .actions, in: &snapshot)
        if extras?.rating != nil {
            append([.rating], to: .rating, in: &snapshot)
        }
        if !detail.overview.isEmpty {
            append([.synopsis], to: .synopsis, in: &snapshot)
        }
        if let extras {
            appendExtras(extras, to: &snapshot)
        } else {
            append([.status(.loading)], to: .status, in: &snapshot)
        }
        let currentItems = Set(dataSource.snapshot().itemIdentifiers)
        let newItems = Set(snapshot.itemIdentifiers)
        snapshot.reconfigureItems(fixedItems.filter { currentItems.contains($0) && newItems.contains($0) })
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    func appendExtras(_ extras: MovieDetailModel.DisplayedExtras, to snapshot: inout Snapshot) {
        if !extras.cast.isEmpty {
            append(extras.cast.map(Item.castMember), to: .cast, in: &snapshot)
        }
        append([.tabs], to: .tabs, in: &snapshot)
        switch selectedTab {
        case .moreLikeThis:
            appendTabContent(extras.moreLikeThis, as: .moreLikeThis, makeItem: Item.movie, to: &snapshot)
        case .trailers:
            appendTabContent(extras.trailers, as: .trailers, makeItem: Item.trailer, to: &snapshot)
        }
    }

    func appendTabContent<Content: Hashable & Sendable>(
        _ content: MovieDetailModel.DisplayedTabContent<Content>,
        as section: Section,
        makeItem: (Content) -> Item,
        to snapshot: inout Snapshot
    ) {
        switch content {
        case .items(let items):
            append(items.map(makeItem), to: section, in: &snapshot)
        case .empty(let message):
            append([.status(.empty(message: message))], to: .status, in: &snapshot)
        }
    }

    func append(_ items: [Item], to section: Section, in snapshot: inout Snapshot) {
        snapshot.appendSections([section])
        snapshot.appendItems(items, toSection: section)
    }

    func sectionTitle(at sectionIndex: Int) -> String {
        switch dataSource.sectionIdentifier(for: sectionIndex) {
        case .synopsis:
            String(localized: "Synopsis")
        case .cast:
            String(localized: "Cast")
        default:
            ""
        }
    }
}

// MARK: - IMovieDetailViewController
extension MovieDetailViewController: IMovieDetailViewController {
    func displayDetails(viewData: MovieDetailModel.LoadDetails.ViewData) {
        switch viewData {
        case .loading(let detail):
            show(detail: detail, extras: nil)
        case let .content(detail, extras):
            show(detail: detail, extras: extras)
        case .failure(let message):
            dataSource.apply(Snapshot(), animatingDifferences: false)
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

// MARK: - ShareSourceProvider
extension MovieDetailViewController: ShareSourceProvider {
    var shareSourceItem: (any UIPopoverPresentationControllerSourceItem)? {
        guard let indexPath = dataSource.indexPath(for: .actions) else { return nil }
        return (collectionView.cellForItem(at: indexPath) as? MovieDetailActionsCell)?.shareButton
    }
}

// MARK: - MovieDetailHeaderCellDelegate
extension MovieDetailViewController: MovieDetailHeaderCellDelegate {
    func movieDetailHeaderCellDidTapWatch(_ cell: MovieDetailHeaderCell) {
        guard case .available(let video)? = detail?.watch else { return }
        router.routeToTrailer(video: video)
    }
}

// MARK: - MovieDetailActionsCellDelegate
extension MovieDetailViewController: MovieDetailActionsCellDelegate {
    func movieDetailActionsCellDidTapShare(_ cell: MovieDetailActionsCell) {
        guard let movie = detail?.movie else { return }
        router.routeToShare(movie: movie)
    }
}

// MARK: - MovieDetailSynopsisCellDelegate
extension MovieDetailViewController: MovieDetailSynopsisCellDelegate {
    func movieDetailSynopsisCellDidTapToggle(_ cell: MovieDetailSynopsisCell) {
        isSynopsisExpanded.toggle()
        var snapshot = dataSource.snapshot()
        snapshot.reconfigureItems([.synopsis])
        dataSource.apply(snapshot, animatingDifferences: !UIAccessibility.isReduceMotionEnabled)
    }
}

// MARK: - MovieDetailTabsCellDelegate
extension MovieDetailViewController: MovieDetailTabsCellDelegate {
    func movieDetailTabsCell(_ cell: MovieDetailTabsCell, didSelectTabAt index: Int) {
        guard let tab = Tab(rawValue: index), tab != selectedTab else { return }
        selectedTab = tab
        applySnapshot()
    }
}

// MARK: - UICollectionViewDelegate
extension MovieDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        switch dataSource.itemIdentifier(for: indexPath) {
        case .movie, .trailer:
            true
        default:
            false
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        switch dataSource.itemIdentifier(for: indexPath) {
        case .movie(let displayedMovie):
            router.routeToMovieDetail(movie: displayedMovie.movie)
        case .trailer(let trailer):
            router.routeToTrailer(video: trailer.video)
        default:
            return
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let indexPath = dataSource.indexPath(for: .header) else { return }
        let offset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        let parallaxOffset = UIAccessibility.isReduceMotionEnabled ? min(offset, 0) : offset
        (collectionView.cellForItem(at: indexPath) as? MovieDetailHeaderCell)?.applyParallax(offset: parallaxOffset)
    }
}

// MARK: - Layout
private extension MovieDetailViewController {
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
        let collectionLayout = layout.make { [weak self] sectionIndex in
            self?.dataSource.sectionIdentifier(for: sectionIndex)
        }
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)
        collectionView.backgroundColor = .MVColor(.backgroundPrimary)
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.delegate = self
        return collectionView
    }

    func makeDataSource() -> DataSource {
        let header = makeHeaderRegistration()
        let actions = makeActionsRegistration()
        let rating = makeRatingRegistration()
        let synopsis = makeSynopsisRegistration()
        let tabs = makeTabsRegistration()
        let castMember = makeCastMemberRegistration()
        let poster = makePosterRegistration()
        let trailer = makeTrailerRegistration()
        let status = makeStatusRegistration()
        let sectionHeader = UICollectionView.SupplementaryRegistration<SectionHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] view, _, indexPath in
            view.configure(title: self?.sectionTitle(at: indexPath.section) ?? "")
        }
        let dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .header:
                collectionView.dequeueConfiguredReusableCell(using: header, for: indexPath, item: item)
            case .actions:
                collectionView.dequeueConfiguredReusableCell(using: actions, for: indexPath, item: item)
            case .rating:
                collectionView.dequeueConfiguredReusableCell(using: rating, for: indexPath, item: item)
            case .synopsis:
                collectionView.dequeueConfiguredReusableCell(using: synopsis, for: indexPath, item: item)
            case .tabs:
                collectionView.dequeueConfiguredReusableCell(using: tabs, for: indexPath, item: item)
            case .castMember(let member):
                collectionView.dequeueConfiguredReusableCell(using: castMember, for: indexPath, item: member)
            case .movie(let movie):
                collectionView.dequeueConfiguredReusableCell(using: poster, for: indexPath, item: movie)
            case .trailer(let video):
                collectionView.dequeueConfiguredReusableCell(using: trailer, for: indexPath, item: video)
            case .status(let state):
                collectionView.dequeueConfiguredReusableCell(using: status, for: indexPath, item: state)
            }
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: sectionHeader, for: indexPath)
        }
        return dataSource
    }
}

// MARK: - Cell Registrations
private extension MovieDetailViewController {
    func makeHeaderRegistration() -> UICollectionView.CellRegistration<MovieDetailHeaderCell, Item> {
        UICollectionView.CellRegistration { [weak self] cell, _, _ in
            guard let self, let detail else { return }
            cell.configure(with: detail, watchTitle: String(localized: "Watch"), imageLoader: imageLoader)
            cell.delegate = self
        }
    }

    func makeActionsRegistration() -> UICollectionView.CellRegistration<MovieDetailActionsCell, Item> {
        UICollectionView.CellRegistration { [weak self] cell, _, _ in
            cell.configure(shareTitle: String(localized: "Share"))
            cell.delegate = self
        }
    }

    func makeRatingRegistration() -> UICollectionView.CellRegistration<MovieDetailRatingCell, Item> {
        UICollectionView.CellRegistration { [weak self] cell, _, _ in
            guard let rating = self?.extras?.rating else { return }
            cell.configure(with: rating)
        }
    }

    func makeSynopsisRegistration() -> UICollectionView.CellRegistration<MovieDetailSynopsisCell, Item> {
        UICollectionView.CellRegistration { [weak self] cell, _, _ in
            guard let self, let detail else { return }
            let toggleTitle = isSynopsisExpanded ? String(localized: "Show Less") : String(localized: "Read More")
            cell.configure(text: detail.overview, isExpanded: isSynopsisExpanded, toggleTitle: toggleTitle)
            cell.delegate = self
        }
    }

    func makeTabsRegistration() -> UICollectionView.CellRegistration<MovieDetailTabsCell, Item> {
        UICollectionView.CellRegistration { [weak self] cell, _, _ in
            guard let self else { return }
            let titles = [String(localized: "More Like This"), String(localized: "Trailers")]
            cell.configure(titles: titles, selectedIndex: selectedTab.rawValue)
            cell.delegate = self
        }
    }

    func makeCastMemberRegistration() -> UICollectionView.CellRegistration<
        CastMemberCell,
        MovieDetailModel.DisplayedCastMember
    > {
        UICollectionView.CellRegistration { [imageLoader] cell, _, member in
            cell.configure(with: member, imageLoader: imageLoader)
        }
    }

    func makePosterRegistration() -> UICollectionView.CellRegistration<PosterCell, MovieDetailModel.DisplayedMovie> {
        UICollectionView.CellRegistration { [imageLoader] cell, _, movie in
            cell.configure(
                title: movie.title,
                artwork: movie.artwork,
                showsPlayBadge: false,
                rating: movie.rating,
                imageLoader: imageLoader
            )
        }
    }

    func makeTrailerRegistration() -> UICollectionView.CellRegistration<MediaRowCell, MovieDetailModel.DisplayedTrailer> {
        UICollectionView.CellRegistration { [imageLoader] cell, _, trailer in
            cell.configure(
                title: trailer.title,
                metadata: trailer.metadata,
                rating: nil,
                artwork: trailer.artwork,
                imageLoader: imageLoader
            )
            cell.showsPlayBadge = true
            cell.accessibilityValue = trailer.accessibilityValue
        }
    }

    func makeStatusRegistration() -> UICollectionView.CellRegistration<UICollectionViewCell, MovieDetailLayout.Status> {
        UICollectionView.CellRegistration { cell, _, status in
            switch status {
            case .loading:
                cell.contentConfiguration = UIContentUnavailableConfiguration.loading()
            case .empty(let message):
                var configuration = UIContentUnavailableConfiguration.empty()
                configuration.text = message
                configuration.textProperties.font = .MVFont(.body)
                configuration.textProperties.color = .MVColor(.textSecondary)
                cell.contentConfiguration = configuration
            }
        }
    }
}
