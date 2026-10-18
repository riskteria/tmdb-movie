import MovieAppDS
import UIKit

protocol IProfileViewController: AnyObject {
    func displayProfile(viewData: ProfileModel.LoadProfile.ViewData)
}

final class ProfileViewController: UIViewController {
    private let interactor: any IProfileInteractor
    private let router: any IProfileRouter
    private let imageLoader: any IImageLoader
    private var headers: [ProfileModel.Section: String] = [:]
    private var loadTask: Task<Void, Never>?
    private var changeAppearanceTask: Task<Void, Never>?
    private var accountTask: Task<Void, Never>?

    private lazy var collectionView = makeCollectionView()
    private lazy var dataSource = makeDataSource()

    init(interactor: any IProfileInteractor, router: any IProfileRouter, imageLoader: any IImageLoader) {
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
        changeAppearanceTask?.cancel()
        accountTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Profile")
        setUpLayout()
        loadProfile()
    }
}

private extension ProfileViewController {
    func loadProfile() {
        loadTask?.cancel()
        loadTask = Task { [interactor] in
            await interactor.loadProfile(request: ProfileModel.LoadProfile.Request())
        }
    }

    func changeAppearance(to theme: AppTheme) {
        changeAppearanceTask?.cancel()
        changeAppearanceTask = Task { [interactor] in
            await interactor.changeAppearance(request: ProfileModel.ChangeAppearance.Request(theme: theme))
        }
    }

    func signIn() {
        accountTask?.cancel()
        accountTask = Task { [interactor] in
            await interactor.signIn(request: ProfileModel.SignIn.Request())
        }
    }

    func signOut() {
        accountTask?.cancel()
        accountTask = Task { [interactor] in
            await interactor.signOut(request: ProfileModel.SignOut.Request())
        }
    }

    func isActionRow(at indexPath: IndexPath) -> Bool {
        switch dataSource.itemIdentifier(for: indexPath) {
        case .signIn(_, let isEnabled):
            isEnabled
        case .signOut:
            true
        default:
            false
        }
    }

    func makeAccessibilityTraits(for row: ProfileModel.Row) -> UIAccessibilityTraits {
        switch row {
        case .signIn(_, let isEnabled):
            isEnabled ? .button : [.button, .notEnabled]
        case .signOut:
            .button
        default:
            .none
        }
    }

    func makeAccessories(for row: ProfileModel.Row) -> [UICellAccessory] {
        guard case let .appearance(_, options) = row else { return [] }
        let actions = options.map { option in
            UIAction(title: option.title, state: option.isSelected ? .on : .off) { [weak self] _ in
                self?.changeAppearance(to: option.theme)
            }
        }
        return [.popUpMenu(UIMenu(children: actions))]
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

// MARK: - UICollectionViewDelegate
extension ProfileViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        isActionRow(at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        isActionRow(at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        switch dataSource.itemIdentifier(for: indexPath) {
        case .signIn(_, isEnabled: true):
            signIn()
        case .signOut(_, let confirmation):
            router.routeToSignOutConfirmation(confirmation) { [weak self] in
                self?.signOut()
            }
        default:
            break
        }
    }
}

// MARK: - Layout
private extension ProfileViewController {
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
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.headerMode = .supplementary
        configuration.backgroundColor = .MVColor(.backgroundPrimary)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .MVColor(.backgroundPrimary)
        collectionView.delegate = self
        return collectionView
    }

    func makeDataSource() -> UICollectionViewDiffableDataSource<ProfileModel.Section, ProfileModel.Row> {
        typealias RowRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, ProfileModel.Row>
        typealias AccountRegistration = UICollectionView.CellRegistration<ProfileAccountCell, ProfileModel.Row>
        let background = makeCellBackground()
        let rowRegistration = RowRegistration { [weak self] cell, _, row in
            cell.contentConfiguration = Self.makeContentConfiguration(for: row)
            cell.accessories = self?.makeAccessories(for: row) ?? []
            cell.accessibilityTraits = self?.makeAccessibilityTraits(for: row) ?? .none
            cell.backgroundConfiguration = background
        }
        let accountRegistration = AccountRegistration { [imageLoader] cell, _, row in
            guard case let .account(name, username, avatar) = row else { return }
            cell.configure(name: name, username: username, avatar: avatar, imageLoader: imageLoader)
            cell.backgroundConfiguration = background
        }
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] header, _, indexPath in
            var configuration = UIListContentConfiguration.header()
            if let section = self?.dataSource.sectionIdentifier(for: indexPath.section) {
                configuration.text = self?.headers[section]
            }
            configuration.textProperties.font = .MVFont(.footnote)
            configuration.textProperties.color = .MVColor(.textSecondary)
            header.contentConfiguration = configuration
        }
        let dataSource = UICollectionViewDiffableDataSource<ProfileModel.Section, ProfileModel.Row>(
            collectionView: collectionView
        ) { collectionView, indexPath, row in
            switch row {
            case .account:
                return collectionView.dequeueConfiguredReusableCell(
                    using: accountRegistration,
                    for: indexPath,
                    item: row
                )
            default:
                return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: row)
            }
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        return dataSource
    }

    static func makeContentConfiguration(for row: ProfileModel.Row) -> UIListContentConfiguration {
        switch row {
        case let .guest(title, subtitle), let .account(title, subtitle, _):
            var configuration = UIListContentConfiguration.subtitleCell()
            configuration.image = UIImage(systemName: "person.crop.circle.fill")
            configuration.imageProperties.tintColor = .MVColor(.brand)
            let symbolConfiguration = UIImage.SymbolConfiguration(textStyle: .largeTitle)
            configuration.imageProperties.preferredSymbolConfiguration = symbolConfiguration
            configuration.text = title
            configuration.secondaryText = subtitle
            return styled(configuration)
        case let .signIn(title, isEnabled):
            var configuration = styled(makeCell(title: title, systemImage: "person.badge.key"))
            let color: UIColor = isEnabled ? .MVColor(.brand) : .MVColor(.textSecondary)
            configuration.textProperties.color = color
            configuration.imageProperties.tintColor = color
            return configuration
        case .signOut(let title, _):
            let configuration = makeCell(title: title, systemImage: "rectangle.portrait.and.arrow.right")
            return styled(configuration, isDestructive: true)
        case .clearSavedData(let title):
            return styled(makeCell(title: title, systemImage: "trash"), isDestructive: true)
        case .clearWatchHistory(let title):
            return styled(makeCell(title: title, systemImage: "clock.arrow.circlepath"), isDestructive: true)
        case .appearance(let title, _):
            return styled(makeCell(title: title, systemImage: "circle.lefthalf.filled"))
        case let .version(title, value):
            return styled(makeCell(title: title, value: value, systemImage: "info.circle"))
        case .attribution(let text):
            var configuration = UIListContentConfiguration.cell()
            configuration.text = text
            configuration.textProperties.font = .MVFont(.caption)
            configuration.textProperties.color = .MVColor(.textSecondary)
            return configuration
        }
    }

    func makeCellBackground() -> UIBackgroundConfiguration {
        var background = UIBackgroundConfiguration.listCell()
        background.backgroundColor = .MVColor(.backgroundSecondary)
        return background
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
        let tintColor: UIColor = isDestructive ? .systemRed : .MVColor(.brand)
        configuration.imageProperties.tintColor = tintColor
        configuration.textProperties.font = .MVFont(.body)
        configuration.textProperties.color = isDestructive ? tintColor : .MVColor(.textPrimary)
        configuration.secondaryTextProperties.font = .MVFont(.footnote)
        configuration.secondaryTextProperties.color = .MVColor(.textSecondary)
        return configuration
    }
}
