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
        // When
        sut.presentProfile(response: makeResponse(accountState: .signedIn(account)))

        // Assert
        let sections = viewController.displayedViewData.last?.sections ?? []
        #expect(sections.map(\.section) == [.account, .data, .preferences, .about])
        #expect(sections.map(\.header) == [nil, "Data", "Preferences", "About"])
    }

    @Test
    func signedOutHasNoDataSection() {
        // Assert
        let sections = viewController.displayedViewData.last?.sections ?? []
        #expect(sections.map(\.section) == [.account, .preferences, .about])
    }

    @Test
    func signedInShowsDataSection() {
        // When
        sut.presentProfile(response: makeResponse(accountState: .signedIn(account)))

        // Assert
        let sections = viewController.displayedViewData.last?.sections ?? []
        #expect(sections.contains { $0.section == .data })
    }

    @Test
    func presentProfileShowsVersionAndBuild() {
        // Assert
        let aboutRows = viewController.displayedViewData.last?.sections.last?.rows ?? []
        #expect(aboutRows.first == .version(title: "Version", value: "1.0 (7)"))
    }

    @Test
    func clearRowsCarryConfirmations() {
        // When
        sut.presentProfile(response: makeResponse(accountState: .signedIn(account)))

        // Assert
        let dataRows = viewController.displayedViewData.last?.sections.first { $0.section == .data }?.rows ?? []
        let expected: [ProfileModel.Row] = [
            .clearSavedData(
                title: "Clear Saved data",
                confirmation: ProfileModel.DisplayedConfirmation(
                    title: "Clear Saved data?",
                    message: "Your saved movies on this device will be removed. This can't be undone.",
                    confirmTitle: "Clear",
                    cancelTitle: "Cancel"
                )
            ),
            .clearWatchHistory(
                title: "Clear watch history",
                confirmation: ProfileModel.DisplayedConfirmation(
                    title: "Clear watch history?",
                    message: "Continue Watching on this device will be emptied. This can't be undone.",
                    confirmTitle: "Clear",
                    cancelTitle: "Cancel"
                )
            )
        ]
        #expect(dataRows == expected)
    }

    @Test
    func clearFailureAlerts() {
        // When
        sut.presentClearSavedData(response: ProfileModel.ClearSavedData.Response())
        sut.presentClearWatchHistory(response: ProfileModel.ClearWatchHistory.Response())

        // Assert
        let message = "Nothing was deleted. Try again."
        #expect(viewController.displayedAlerts == [
            ProfileModel.DisplayedAlert(title: "Couldn't clear Saved data", message: message, actionTitle: "OK"),
            ProfileModel.DisplayedAlert(title: "Couldn't clear watch history", message: message, actionTitle: "OK")
        ])
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
    func guestStateShowsSignInMessage() {
        // Assert
        #expect(
            accountRows().first == .guest(
                title: "Browsing as guest",
                message: "Sign in to save movies and keep your watch history."
            )
        )
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
    private(set) var displayedAlerts: [ProfileModel.DisplayedAlert] = []

    func displayProfile(viewData: ProfileModel.LoadProfile.ViewData) {
        displayedViewData.append(viewData)
    }

    func displayClearSavedData(viewData: ProfileModel.ClearSavedData.ViewData) {
        displayedAlerts.append(viewData.alert)
    }

    func displayClearWatchHistory(viewData: ProfileModel.ClearWatchHistory.ViewData) {
        displayedAlerts.append(viewData.alert)
    }
}
