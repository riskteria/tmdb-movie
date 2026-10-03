import MovieAppDS
import UIKit

// The trending banners in their own paging collection view, so the page control and auto-advance
// can read and set the page on a scroll view of their own.
final class HeroCarouselCell: UICollectionViewCell {
    var onSelectBanner: ((Movie, UIView) -> Void)?
    var onUserPageChange: (() -> Void)?
    private var imageLoader: (any ImageLoading)?

    private lazy var collectionView = makeCollectionView()
    private lazy var dataSource = makeDataSource()
    private lazy var pageControl = makePageControl()

    private var currentPage: Int {
        let pageWidth = collectionView.bounds.width
        guard pageWidth > 0 else { return 0 }
        let page = Int((collectionView.contentOffset.x / pageWidth).rounded())
        return min(max(page, 0), max(pageControl.numberOfPages - 1, 0))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(banners: [HomeModel.DisplayedBanner], imageLoader: any ImageLoading) {
        self.imageLoader = imageLoader
        var snapshot = NSDiffableDataSourceSnapshot<Int, HomeModel.DisplayedBanner>()
        snapshot.appendSections([0])
        snapshot.appendItems(banners)
        dataSource.apply(snapshot, animatingDifferences: false)
        pageControl.numberOfPages = banners.count
        pageControl.currentPage = currentPage
    }

    // Skipped while the user is touching or flicking the banners.
    func showNextPage() {
        let pageCount = pageControl.numberOfPages
        let isUserScrolling = collectionView.isTracking || collectionView.isDragging || collectionView.isDecelerating
        guard pageCount > 1, !isUserScrolling else { return }
        scrollToPage((currentPage + 1) % pageCount, animated: true)
    }
}

private extension HeroCarouselCell {
    func scrollToPage(_ page: Int, animated: Bool) {
        guard page < dataSource.snapshot().numberOfItems else { return }
        let indexPath = IndexPath(item: page, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }

    static func makeDashImage(width: CGFloat) -> UIImage {
        let size = CGSize(width: width, height: 4)
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 2).fill()
        }
        return image.withRenderingMode(.alwaysTemplate)
    }
}

// MARK: - UICollectionViewDelegate
extension HeroCarouselCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let banner = dataSource.itemIdentifier(for: indexPath) else { return }
        guard let cell = collectionView.cellForItem(at: indexPath) as? HeroBannerCell else { return }
        onSelectBanner?(banner.movie, cell.artworkView)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pageControl.currentPage = currentPage
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        onUserPageChange?()
    }
}

// MARK: - Layout
private extension HeroCarouselCell {
    func setUpLayout() {
        [collectionView, pageControl].forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(subview)
        }
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            pageControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.xSmall),
            pageControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.xSmall)
        ])
    }

    func makeCollectionView() -> UICollectionView {
        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.scrollDirection = .horizontal
        let layout = UICollectionViewCompositionalLayout(
            section: NSCollectionLayoutSection(group: group),
            configuration: configuration
        )
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        // Only one scroll view may handle a status bar tap, and that's Home's.
        collectionView.scrollsToTop = false
        collectionView.delegate = self
        return collectionView
    }

    func makeDataSource() -> UICollectionViewDiffableDataSource<Int, HomeModel.DisplayedBanner> {
        typealias Registration = UICollectionView.CellRegistration<HeroBannerCell, HomeModel.DisplayedBanner>
        let registration = Registration { [weak self] cell, _, banner in
            guard let self, let imageLoader else { return }
            cell.configure(
                title: banner.title,
                metadata: banner.metadata,
                artwork: banner.artwork,
                imageLoader: imageLoader
            )
        }
        return UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, banner in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: banner)
        }
    }

    func makePageControl() -> UIPageControl {
        let pageControl = UIPageControl()
        pageControl.hidesForSinglePage = true
        pageControl.currentPageIndicatorTintColor = .MVColor(.brand)
        pageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.45)
        pageControl.preferredIndicatorImage = Self.makeDashImage(width: 6)
        pageControl.preferredCurrentPageIndicatorImage = Self.makeDashImage(width: 22)
        pageControl.addAction(
            UIAction { [weak self, weak pageControl] _ in
                guard let self, let pageControl else { return }
                scrollToPage(pageControl.currentPage, animated: true)
                onUserPageChange?()
            },
            for: .valueChanged
        )
        return pageControl
    }
}
