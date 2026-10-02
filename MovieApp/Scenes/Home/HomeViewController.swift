import UIKit

protocol IHomeViewController: AnyObject {
    func displayHome(viewData: HomeModel.LoadHome.ViewData)
}

final class HomeViewController: UIViewController {
    private static let autoAdvanceInterval = Duration.seconds(6)

    private let interactor: any IHomeInteractor
    private let router: any IHomeRouter
    private let imageLoader: any ImageLoading
    private var loadTask: Task<Void, Never>?
    private var autoAdvanceTask: Task<Void, Never>?
    private var sectionTitles: [HomeModel.Section: String] = [:]
    private var zoomSourceMovieID: Movie.ID?
    private weak var zoomSourceView: UIView?
    private var isHeroBehindStatusBar = true

    private lazy var collectionView = makeCollectionView()
    private lazy var dataSource = makeDataSource()

    init(interactor: any IHomeInteractor, router: any IHomeRouter, imageLoader: any ImageLoading) {
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
        autoAdvanceTask?.cancel()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        isHeroBehindStatusBar ? .lightContent : .default
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Home")
        setUpLayout()
        loadHome()
    }

    // Home draws its hero under the status bar, so it has no navigation bar of its own.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAutoAdvance()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        autoAdvanceTask?.cancel()
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        collectionView.contentInset.bottom = view.safeAreaInsets.bottom
        collectionView.verticalScrollIndicatorInsets.bottom = view.safeAreaInsets.bottom
    }
}

private extension HomeViewController {
    var heroCell: HeroCarouselCell? {
        collectionView.visibleCells.lazy.compactMap { $0 as? HeroCarouselCell }.first
    }

    func loadHome() {
        loadTask?.cancel()
        if dataSource.snapshot().numberOfItems == 0 {
            contentUnavailableConfiguration = UIContentUnavailableConfiguration.loading()
        }
        
        Task {
            await interactor.loadHome(request: HomeModel.LoadHome.Request())
        }
        
        Task { [interactor] in
            await interactor.loadHome(request: HomeModel.LoadHome.Request())
        }
        
        loadTask = Task { [interactor] in
            await interactor.loadHome(request: HomeModel.LoadHome.Request())
        }
    }

    func selectMovie(_ movie: Movie, sourceView: UIView?) {
        zoomSourceMovieID = movie.id
        zoomSourceView = sourceView
        router.routeToMovieDetail(movie: movie)
    }

    // Restarted whenever the user changes page, so a banner always gets a full interval on screen.
    func startAutoAdvance() {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.autoAdvanceInterval)
                guard let self, !Task.isCancelled else { return }
                advanceHeroIfIdle()
            }
        }
    }

    func advanceHeroIfIdle() {
        let isMotionAllowed = !UIAccessibility.isReduceMotionEnabled && !UIAccessibility.isVoiceOverRunning
        let isUserScrolling = collectionView.isDragging || collectionView.isDecelerating
        guard isMotionAllowed, !isUserScrolling else { return }
        heroCell?.showNextPage()
    }

    func updateStatusBarStyle(forOffset offset: CGFloat) {
        let isBehind = offset < (heroCell?.bounds.height ?? 0) - view.safeAreaInsets.top
        guard isBehind != isHeroBehindStatusBar else { return }
        isHeroBehindStatusBar = isBehind
        #if os(iOS)
        setNeedsStatusBarAppearanceUpdate()
        #endif
    }

    func sectionTitle(at sectionIndex: Int) -> String {
        guard let section = dataSource.sectionIdentifier(for: sectionIndex) else { return "" }
        return sectionTitles[section] ?? ""
    }
}

// MARK: - IHomeViewController
extension HomeViewController: IHomeViewController {
    func displayHome(viewData: HomeModel.LoadHome.ViewData) {
        switch viewData {
        case .content(let sections):
            contentUnavailableConfiguration = nil
            sectionTitles = Dictionary(
                sections.compactMap { section in section.title.map { (section.section, $0) } }
            ) { first, _ in first }
            var snapshot = NSDiffableDataSourceSnapshot<HomeModel.Section, HomeModel.Item>()
            for section in sections {
                snapshot.appendSections([section.section])
                snapshot.appendItems(section.items, toSection: section.section)
            }
            dataSource.apply(snapshot)
        case .empty(let message):
            contentUnavailableConfiguration = UIContentUnavailableConfiguration.message(message, systemImage: "film")
        case .failure(let message):
            let retryTitle = String(localized: "Retry")
            let configuration = UIContentUnavailableConfiguration.failure(
                message: message,
                retryTitle: retryTitle
            ) { [weak self] in
                self?.loadHome()
            }
            contentUnavailableConfiguration = configuration
        }
    }
}

// MARK: - ZoomTransitionSourceProviding
extension HomeViewController: ZoomTransitionSourceProviding {
    func zoomTransitionSourceView(for movieID: Movie.ID) -> UIView? {
        movieID == zoomSourceMovieID ? zoomSourceView : nil
    }
}

// MARK: - UICollectionViewDelegate
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard case .hero = dataSource.itemIdentifier(for: indexPath) else { return true }
        return false
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        switch dataSource.itemIdentifier(for: indexPath) {
        case .continueWatching(let item):
            selectMovie(item.movie, sourceView: (cell as? ContinueWatchingCell)?.artworkView)
        case .poster(let poster, _):
            selectMovie(poster.movie, sourceView: (cell as? PosterCell)?.artworkView)
        case .hero, nil:
            return
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        updateStatusBarStyle(forOffset: offset)
    }
}

// MARK: - Layout
private extension HomeViewController {
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
        let layout = HomeLayout.make { [weak self] sectionIndex in
            self?.dataSource.sectionIdentifier(for: sectionIndex)
        }
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .backgroundPrimary
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.delegate = self
        return collectionView
    }

    func makeDataSource() -> UICollectionViewDiffableDataSource<HomeModel.Section, HomeModel.Item> {
        let heroRegistration = makeHeroRegistration()
        let continueWatchingRegistration = makeContinueWatchingRegistration()
        let posterRegistration = makePosterRegistration()
        let headerRegistration = UICollectionView.SupplementaryRegistration<SectionHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] header, _, indexPath in
            header.configure(title: self?.sectionTitle(at: indexPath.section) ?? "")
        }
        let dataSource = UICollectionViewDiffableDataSource<HomeModel.Section, HomeModel.Item>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            switch item {
            case .hero(let banners):
                collectionView.dequeueConfiguredReusableCell(using: heroRegistration, for: indexPath, item: banners)
            case .continueWatching(let movie):
                collectionView.dequeueConfiguredReusableCell(
                    using: continueWatchingRegistration,
                    for: indexPath,
                    item: movie
                )
            case .poster(let poster, _):
                collectionView.dequeueConfiguredReusableCell(using: posterRegistration, for: indexPath, item: poster)
            }
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        return dataSource
    }

    func makeHeroRegistration() -> UICollectionView.CellRegistration<HeroCarouselCell, [HomeModel.DisplayedBanner]> {
        UICollectionView.CellRegistration { [weak self] cell, _, banners in
            guard let self else { return }
            cell.configure(banners: banners, imageLoader: imageLoader)
            cell.onSelectBanner = { [weak self] movie, sourceView in
                self?.selectMovie(movie, sourceView: sourceView)
            }
            cell.onUserPageChange = { [weak self] in
                self?.startAutoAdvance()
            }
        }
    }

    func makeContinueWatchingRegistration() -> UICollectionView.CellRegistration<ContinueWatchingCell, HomeModel.DisplayedContinueWatching> {
        UICollectionView.CellRegistration { [imageLoader] cell, _, item in
            cell.configure(
                title: item.title,
                subtitle: item.subtitle,
                progress: item.progress,
                artwork: item.artwork,
                imageLoader: imageLoader
            )
        }
    }

    func makePosterRegistration() -> UICollectionView.CellRegistration<PosterCell, HomeModel.DisplayedPoster> {
        UICollectionView.CellRegistration { [imageLoader] cell, _, poster in
            cell.configure(title: poster.title, artwork: poster.artwork, showsPlayBadge: true, imageLoader: imageLoader)
        }
    }
}
