import Foundation
@testable import MovieApp
import Testing

@MainActor
struct ProfilePresenterTests {
    private let viewController = ProfileViewControllerSpy()
    private let account = Account(id: 548, username: "moviefan", name: "Movie Fan", avatarPath: nil)
    private let sut: any IProfilePresenter

    init() {
        let presenter = ProfilePresenter(imageURLProvider: ImageURLProviderStub())
        presenter.viewController = viewController
        sut = presenter
        sut.presentProfile(response: makeResponse(accountState: .guest))
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

    @Test
    func presentProfileListsEveryTheme() throws {
        // Assert
        let options = try appearanceOptions()
        #expect(options.map(\.title) == ["System", "Light", "Dark"])
    }

    @Test
    func presentProfileMarksSelectedTheme() throws {
        // Assert
        let options = try appearanceOptions()
        #expect(options.filter(\.isSelected).map(\.theme) == [.dark])
    }

    @Test
    func guestStateShowsSignInRow() {
        // Assert
        #expect(accountRows().last == .signIn(title: "Sign in with TMDB", isEnabled: true))
    }

    @Test
    func pendingStateDisablesSignInRow() {
        // When
        sut.presentProfile(response: makeResponse(accountState: .signInPending))

        // Assert
        #expect(accountRows().last == .signIn(title: "Signing in…", isEnabled: false))
    }

    @Test
    func failedStateShowsFailureMessage() {
        // When
        sut.presentProfile(response: makeResponse(accountState: .signInFailed))

        // Assert
        let expected = ProfileModel.Row.guest(
            title: "Browsing as guest",
            message: "Couldn't sign in. Check your connection and try again."
        )
        #expect(accountRows().first == expected)
    }

    @Test
    func signedInStateShowsAccountAndSignOut() {
        // When
        sut.presentProfile(response: makeResponse(accountState: .signedIn(account)))

        // Assert
        let confirmation = ProfileModel.DisplayedConfirmation(
            title: "Sign out of TMDB?",
            message: "Saved movies and watch history stay on this device.",
            confirmTitle: "Sign Out",
            cancelTitle: "Cancel"
        )
        let expected: [ProfileModel.Row] = [
            .account(
                name: "Movie Fan",
                username: "@moviefan",
                avatar: DisplayedArtwork(url: nil, placeholderSeed: 548, placeholderTitle: "MF")
            ),
            .signOut(title: "Sign out", confirmation: confirmation)
        ]
        #expect(accountRows() == expected)
    }

    @Test
    func emptyNameFallsBackToUsername() {
        // Given
        let unnamedAccount = Account(id: 548, username: "moviefan", name: "", avatarPath: nil)

        // When
        sut.presentProfile(response: makeResponse(accountState: .signedIn(unnamedAccount)))

        // Assert
        let expected = ProfileModel.Row.account(
            name: "moviefan",
            username: "@moviefan",
            avatar: DisplayedArtwork(url: nil, placeholderSeed: 548, placeholderTitle: "M")
        )
        #expect(accountRows().first == expected)
    }

    @Test
    func accountRowCarriesAvatarURL() {
        // Given
        let accountWithPhoto = Account(
            id: 548,
            username: "moviefan",
            name: "Movie Fan",
            avatarPath: ImagePath(rawValue: "/avatar.jpg")
        )

        // When
        sut.presentProfile(response: makeResponse(accountState: .signedIn(accountWithPhoto)))

        // Assert
        #expect(accountAvatar()?.url == URL(string: "https://images.test/profile/avatar.jpg"))
    }

    @Test
    func accountWithoutPhotoUsesInitials() {
        // When
        sut.presentProfile(response: makeResponse(accountState: .signedIn(account)))

        // Assert
        #expect(accountAvatar()?.placeholderTitle == "MF")
    }

    @Test
    func emptyNameInitialsUseUsername() {
        // Given
        let unnamedAccount = Account(id: 548, username: "moviefan", name: "", avatarPath: nil)

        // When
        sut.presentProfile(response: makeResponse(accountState: .signedIn(unnamedAccount)))

        // Assert
        #expect(accountAvatar()?.placeholderTitle == "M")
    }

    @Test
    func sessionEndedStateShowsMessage() {
        // When
        sut.presentProfile(response: makeResponse(accountState: .sessionEnded))

        // Assert
        let expected = ProfileModel.Row.guest(
            title: "Browsing as guest",
            message: "Your TMDB session ended. Sign in again."
        )
        #expect(accountRows().first == expected)
    }
}

private extension ProfilePresenterTests {
    func makeResponse(accountState: ProfileModel.AccountState) -> ProfileModel.LoadProfile.Response {
        ProfileModel.LoadProfile.Response(
            appInfo: AppInfo(version: "1.0", build: "7"),
            theme: .dark,
            accountState: accountState
        )
    }

    func accountRows() -> [ProfileModel.Row] {
        viewController.displayedViewData.last?.sections.first { $0.section == .account }?.rows ?? []
    }

    func accountAvatar() -> DisplayedArtwork? {
        guard case let .account(_, _, avatar) = accountRows().first else { return nil }
        return avatar
    }

    func appearanceOptions() throws -> [ProfileModel.DisplayedThemeOption] {
        let rows = viewController.displayedViewData.last?.sections.first { $0.section == .preferences }?.rows ?? []
        guard case let .appearance(_, options) = try #require(rows.first) else { return [] }
        return options
    }
}

@MainActor
private final class ProfileViewControllerSpy: IProfileViewController {
    private(set) var displayedViewData: [ProfileModel.LoadProfile.ViewData] = []

    func displayProfile(viewData: ProfileModel.LoadProfile.ViewData) {
        displayedViewData.append(viewData)
    }
}
