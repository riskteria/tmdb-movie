import UIKit

protocol IProfileViewController: AnyObject {
    func displayProfile(viewData: ProfileModel.LoadProfile.ViewData)
}

// The rows are sliced but not interactive yet: the clear actions and Appearance land in Week 4.
final class ProfileViewController: UIViewController {
    private let interactor: any IProfileInteractor
    private var headers: [ProfileModel.Section: String] = [:]

    private lazy var collectionView = makeCollectionView()
    private lazy var dataSource = makeDataSource()

    init(interactor: any IProfileInteractor) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Profile")
        setUpLayout()
        interactor.loadProfile(request: ProfileModel.LoadProfile.Request())
    }
}

// MARK: - IProfileViewController
extension ProfileViewController: IProfileViewController {
    func displayProfile(viewData: ProfileModel.LoadProfile.ViewData) {
        headers = Dictionary(
            viewData.sections.compactMap { section in section.header.map { (section.section, $0) } }
        ) { first, _ in first }
        var snapshot = NSDiffableDataSourceSnapshot<ProfileModel.Section, ProfileModel.Row>()
        for section in viewData.sections {
            snapshot.appendSections([section.section])
            snapshot.appendItems(section.rows, toSection: section.section)
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Layout
private extension ProfileViewController {
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
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.headerMode = .supplementary
        configuration.backgroundColor = .backgroundPrimary
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .backgroundPrimary
        collectionView.allowsSelection = false
        return collectionView
    }

    func makeDataSource() -> UICollectionViewDiffableDataSource<ProfileModel.Section, ProfileModel.Row> {
        typealias RowRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, ProfileModel.Row>
        let rowRegistration = RowRegistration { cell, _, row in
            cell.contentConfiguration = Self.makeContentConfiguration(for: row)
            var background = UIBackgroundConfiguration.listCell()
            background.backgroundColor = .backgroundSecondary
            cell.backgroundConfiguration = background
        }
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] header, _, indexPath in
            var configuration = UIListContentConfiguration.header()
            if let section = self?.dataSource.sectionIdentifier(for: indexPath.section) {
                configuration.text = self?.headers[section]
            }
            configuration.textProperties.font = Typography.footnote
            configuration.textProperties.color = .textSecondary
            header.contentConfiguration = configuration
        }
        let dataSource = UICollectionViewDiffableDataSource<ProfileModel.Section, ProfileModel.Row>(
            collectionView: collectionView
        ) { collectionView, indexPath, row in
            collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: row)
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        return dataSource
    }

    static func makeContentConfiguration(for row: ProfileModel.Row) -> UIListContentConfiguration {
        switch row {
        case let .guest(title, message):
            var configuration = UIListContentConfiguration.subtitleCell()
            configuration.image = UIImage(systemName: "person.crop.circle.fill")
            configuration.imageProperties.tintColor = .brand
            let symbolConfiguration = UIImage.SymbolConfiguration(textStyle: .largeTitle)
            configuration.imageProperties.preferredSymbolConfiguration = symbolConfiguration
            configuration.text = title
            configuration.secondaryText = message
            return styled(configuration)
        case .clearSavedData(let title):
            return styled(makeCell(title: title, systemImage: "trash"), isDestructive: true)
        case .clearWatchHistory(let title):
            return styled(makeCell(title: title, systemImage: "clock.arrow.circlepath"), isDestructive: true)
        case let .appearance(title, value):
            return styled(makeCell(title: title, value: value, systemImage: "circle.lefthalf.filled"))
        case let .version(title, value):
            return styled(makeCell(title: title, value: value, systemImage: "info.circle"))
        case .attribution(let text):
            var configuration = UIListContentConfiguration.cell()
            configuration.text = text
            configuration.textProperties.font = Typography.caption
            configuration.textProperties.color = .textSecondary
            return configuration
        }
    }

    static func makeCell(title: String, value: String? = nil, systemImage: String) -> UIListContentConfiguration {
        var configuration = value == nil ? UIListContentConfiguration.cell() : UIListContentConfiguration.valueCell()
        configuration.image = UIImage(systemName: systemImage)
        configuration.text = title
        configuration.secondaryText = value
        return configuration
    }

    static func styled(_ configuration: UIListContentConfiguration, isDestructive: Bool = false) -> UIListContentConfiguration {
        var configuration = configuration
        let tintColor: UIColor = isDestructive ? .systemRed : .brand
        configuration.imageProperties.tintColor = tintColor
        configuration.textProperties.font = Typography.body
        configuration.textProperties.color = isDestructive ? tintColor : .textPrimary
        configuration.secondaryTextProperties.font = Typography.footnote
        configuration.secondaryTextProperties.color = .textSecondary
        return configuration
    }
}
