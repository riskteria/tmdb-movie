@testable import MovieApp
import Testing

@MainActor
struct ProfilePresenterTests {
    private let viewController = ProfileViewControllerSpy()
    private let sut = ProfilePresenter()

    init() {
        sut.viewController = viewController
        sut.presentProfile(response: ProfileModel.LoadProfile.Response(appInfo: AppInfo(version: "1.0", build: "7")))
    }

    @Test
    func presentProfileOrdersSectionsWithHeaders() {
        // Assert
        let sections = viewController.displayedViewData.last?.sections ?? []
        #expect(sections.map(\.section) == [.account, .data, .preferences, .about])
        #expect(sections.map(\.header) == [nil, "Data", "Preferences", "About"])
    }

    @Test
    func presentProfileShowsVersionAndBuild() {
        // Assert
        let aboutRows = viewController.displayedViewData.last?.sections.last?.rows ?? []
        #expect(aboutRows.first == .version(title: "Version", value: "1.0 (7)"))
    }

    @Test
    func presentProfileOffersClearSavedData() {
        // Assert
        let dataRows = viewController.displayedViewData.last?.sections.first { $0.section == .data }?.rows ?? []
        let expected: [ProfileModel.Row] = [
            .clearSavedData(title: "Clear Saved data"),
            .clearWatchHistory(title: "Clear watch history")
        ]
        #expect(dataRows == expected)
    }
}

@MainActor
private final class ProfileViewControllerSpy: IProfileViewController {
    private(set) var displayedViewData: [ProfileModel.LoadProfile.ViewData] = []

    func displayProfile(viewData: ProfileModel.LoadProfile.ViewData) {
        displayedViewData.append(viewData)
    }
}
