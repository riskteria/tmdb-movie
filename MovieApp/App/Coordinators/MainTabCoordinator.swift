import UIKit

// Home, Saved and Profile are regular tabs. The Search tab, which iOS shows as the separate
// trailing circle, hosts the requirement's Discover area.
final class MainTabCoordinator {
    typealias Dependencies = HomeCoordinator.Dependencies
        & SearchCoordinator.Dependencies
        & SavedCoordinator.Dependencies
        & ProfileCoordinator.Dependencies

    private enum TabIdentifier {
        static let home = "home"
        static let saved = "saved"
        static let profile = "profile"
    }

    let tabBarController = UITabBarController()
    private let homeCoordinator: HomeCoordinator
    private let searchCoordinator: SearchCoordinator
    private let savedCoordinator: SavedCoordinator
    private let profileCoordinator: ProfileCoordinator

    init(dependencies: any Dependencies) {
        homeCoordinator = HomeCoordinator(dependencies: dependencies)
        searchCoordinator = SearchCoordinator(dependencies: dependencies)
        savedCoordinator = SavedCoordinator(dependencies: dependencies)
        profileCoordinator = ProfileCoordinator(dependencies: dependencies)
    }
}

// MARK: - Coordinator
extension MainTabCoordinator: Coordinator {
    func start() {
        let coordinators: [any Coordinator] = [homeCoordinator, searchCoordinator, savedCoordinator, profileCoordinator]
        coordinators.forEach { coordinator in coordinator.start() }
        let homeController = homeCoordinator.navigationController
        let searchController = searchCoordinator.navigationController
        let savedController = savedCoordinator.navigationController
        let profileController = profileCoordinator.navigationController
        tabBarController.tabs = [
            UITab(
                title: String(localized: "Home"),
                image: UIImage(systemName: "house"),
                identifier: TabIdentifier.home
            ) { _ in homeController },
            UITab(
                title: String(localized: "Saved"),
                image: UIImage(systemName: "bookmark"),
                identifier: TabIdentifier.saved
            ) { _ in savedController },
            UITab(
                title: String(localized: "Profile"),
                image: UIImage(systemName: "person"),
                identifier: TabIdentifier.profile
            ) { _ in profileController },
            UISearchTab { _ in searchController }
        ]
        #if os(iOS)
        tabBarController.tabBarMinimizeBehavior = .onScrollDown
        #endif
    }
}
