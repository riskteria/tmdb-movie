import MovieAppDS
import UIKit

protocol IMovieDetailViewController: AnyObject {
    func displayDetails(viewData: MovieDetailModel.LoadDetails.ViewData)
    func displaySavedState(viewData: MovieDetailModel.ObserveSavedState.ViewData)
    func displayToggleSave(viewData: MovieDetailModel.ToggleSave.ViewData)
    func displayWatch(viewData: MovieDetailModel.Watch.ViewData)
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
    private var observeTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?
    private var watchTask: Task<Void, Never>?
    private var savedState: MovieDetailModel.ObserveSavedState.ViewData?
    private var isSaveTapPending = false
    private var detail: MovieDetailModel.DisplayedDetail?
    private var extras: MovieDetailModel.DisplayedExtras?
    private var selectedTab = Tab.moreLikeThis
    private var isSynopsisExpanded = false

    private lazy var collectionView = makeCollectionView()
    private lazy var dataSource = makeDataSource()
    private lazy var toastView = StatusToastView()

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
        observeTask?.cancel()
        saveTask?.cancel()
        watchTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        setUpLayout()
        loadDetails()
        observeSavedState()
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

    func observeSavedState() {
        observeTask?.cancel()
        observeTask = Task { [interactor] in
            await interactor.observeSavedState(request: MovieDetailModel.ObserveSavedState.Request())
        }
    }

    func toggleSave() {
        isSaveTapPending = true
        saveTask = Task { [interactor] in
            await interactor.toggleSave(request: MovieDetailModel.ToggleSave.Request())
        }
    }

    func watch(_ video: Video) {
        watchTask?.cancel()
        watchTask = Task { [interactor] in
            await interactor.watch(request: MovieDetailModel.Watch.Request(video: video))
        }
    }

    var actionsCell: MovieDetailActionsCell? {
        guard let indexPath = dataSource.indexPath(for: .actions) else { return nil }
        return collectionView.cellForItem(at: indexPath) as? MovieDetailActionsCell
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
        snapshot.append([.header], to: .header)
        snapshot.append([.actions], to: .actions)
        if extras?.rating != nil {
            snapshot.append([.rating], to: .rating)
        }
        if !detail.overview.isEmpty {
            snapshot.append([.synopsis], to: .synopsis)
        }
        if let extras {
            appendExtras(extras, to: &snapshot)
        } else {
            snapshot.append([.status(.loading)], to: .status)
        }
        let currentItems = Set(dataSource.snapshot().itemIdentifiers)
        let newItems = Set(snapshot.itemIdentifiers)
        snapshot.reconfigureItems(fixedItems.filter { currentItems.contains($0) && newItems.contains($0) })
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    func appendExtras(_ extras: MovieDetailModel.DisplayedExtras, to snapshot: inout Snapshot) {
        if !extras.cast.isEmpty {
            snapshot.append(extras.cast.map(Item.castMember), to: .cast)
        }
        snapshot.append([.tabs], to: .tabs)
        switch selectedTab {
        case .moreLikeThis:
            snapshot.appendTabContent(extras.moreLikeThis, as: .moreLikeThis, makeItem: Item.movie)
        case .trailers:
            snapshot.appendTabContent(extras.trailers, as: .trailers, makeItem: Item.trailer)
        }
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

    func displaySavedState(viewData: MovieDetailModel.ObserveSavedState.ViewData) {
        savedState = viewData
        actionsCell?.configure(savedState: viewData, shareTitle: String(localized: "Share"), animated: isSaveTapPending)
        isSaveTapPending = false
    }

    func displayToggleSave(viewData: MovieDetailModel.ToggleSave.ViewData) {
        isSaveTapPending = false
        toastView.show(message: viewData.message, in: view)
    }

    func displayWatch(viewData: MovieDetailModel.Watch.ViewData) {
        switch viewData {
        case .trailer(let video):
            router.routeToTrailer(video: video)
        case .failure(let message):
            toastView.show(message: message, in: view)
        }
    }
}

// MARK: - ShareSourceProvider
extension MovieDetailViewController: ShareSourceProvider {
    var shareSourceItem: (any UIPopoverPresentationControllerSourceItem)? {
        actionsCell?.shareButton
    }
}

// MARK: - MovieDetailHeaderCellDelegate
extension MovieDetailViewController: MovieDetailHeaderCellDelegate {
    func movieDetailHeaderCellDidTapWatch(_ cell: MovieDetailHeaderCell) {
        guard case .available(let video)? = detail?.watch else { return }
        watch(video)
    }
}

// MARK: - MovieDetailActionsCellDelegate
extension MovieDetailViewController: MovieDetailActionsCellDelegate {
    func movieDetailActionsCellDidTapSave(_ cell: MovieDetailActionsCell) {
        toggleSave()
    }

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
            watch(trailer.video)
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
        let registrations = MovieDetailCellRegistrations(imageLoader: imageLoader)
        let castMember = registrations.makeCastMemberRegistration()
        let poster = registrations.makePosterRegistration()
        let trailer = registrations.makeTrailerRegistration()
        let status = registrations.makeStatusRegistration()
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
            cell.configure(savedState: self?.savedState, shareTitle: String(localized: "Share"), animated: false)
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
}
