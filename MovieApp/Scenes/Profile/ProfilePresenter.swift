import Foundation

protocol IProfilePresenter {
    func presentProfile(response: ProfileModel.LoadProfile.Response)
    func presentClearSavedData(response: ProfileModel.ClearSavedData.Response)
    func presentClearWatchHistory(response: ProfileModel.ClearWatchHistory.Response)
}

final class ProfilePresenter {
    weak var viewController: (any IProfileViewController)?
    private let imageURLProvider: any ImageURLProvider

    init(imageURLProvider: any ImageURLProvider) {
        self.imageURLProvider = imageURLProvider
    }
}

// MARK: - IProfilePresenter
extension ProfilePresenter: IProfilePresenter {
    func presentProfile(response: ProfileModel.LoadProfile.Response) {
        let appInfo = response.appInfo
        let clearSavedMessage = String(
            localized: "Your saved movies on this device will be removed. This can't be undone."
        )
        let clearHistoryMessage = String(
            localized: "Continue Watching on this device will be emptied. This can't be undone."
        )
        let attribution = String(localized: "This product uses the TMDB API but is not endorsed or certified by TMDB.")
        let sections = [
            ProfileModel.DisplayedSection(
                section: .account,
                header: nil,
                rows: makeAccountRows(for: response.accountState)
            ),
            ProfileModel.DisplayedSection(
                section: .data,
                header: String(localized: "Data"),
                rows: [
                    .clearSavedData(
                        title: String(localized: "Clear Saved data"),
                        confirmation: makeClearConfirmation(
                            title: String(localized: "Clear Saved data?"),
                            message: clearSavedMessage
                        )
                    ),
                    .clearWatchHistory(
                        title: String(localized: "Clear watch history"),
                        confirmation: makeClearConfirmation(
                            title: String(localized: "Clear watch history?"),
                            message: clearHistoryMessage
                        )
                    )
                ]
            ),
            ProfileModel.DisplayedSection(
                section: .preferences,
                header: String(localized: "Preferences"),
                rows: [makeAppearanceRow(selected: response.theme)]
            ),
            ProfileModel.DisplayedSection(
                section: .about,
                header: String(localized: "About"),
                rows: [
                    .version(title: String(localized: "Version"), value: "\(appInfo.version) (\(appInfo.build))"),
                    .attribution(text: attribution)
                ]
            )
        ]
        viewController?.displayProfile(viewData: ProfileModel.LoadProfile.ViewData(sections: sections))
    }

    func presentClearSavedData(response: ProfileModel.ClearSavedData.Response) {
        let alert = makeClearFailureAlert(title: String(localized: "Couldn't clear Saved data"))
        viewController?.displayClearSavedData(viewData: ProfileModel.ClearSavedData.ViewData(alert: alert))
    }

    func presentClearWatchHistory(response: ProfileModel.ClearWatchHistory.Response) {
        let alert = makeClearFailureAlert(title: String(localized: "Couldn't clear watch history"))
        viewController?.displayClearWatchHistory(viewData: ProfileModel.ClearWatchHistory.ViewData(alert: alert))
    }
}

private extension ProfilePresenter {
    func makeAccountRows(for state: ProfileModel.AccountState) -> [ProfileModel.Row] {
        let guestTitle = String(localized: "Browsing as guest")
        let guestMessage = String(localized: "Saved movies and watch history stay on this device.")
        let signInTitle = String(localized: "Sign in with TMDB")
        switch state {
        case .guest:
            return [
                .guest(title: guestTitle, message: guestMessage),
                .signIn(title: signInTitle, isEnabled: true)
            ]
        case .signInPending:
            return [
                .guest(title: guestTitle, message: guestMessage),
                .signIn(title: String(localized: "Signing in…"), isEnabled: false)
            ]
        case .signInFailed:
            let failureMessage = String(localized: "Couldn't sign in. Check your connection and try again.")
            return [
                .guest(title: guestTitle, message: failureMessage),
                .signIn(title: signInTitle, isEnabled: true)
            ]
        case .sessionEnded:
            let sessionEndedMessage = String(localized: "Your TMDB session ended. Sign in again.")
            return [
                .guest(title: guestTitle, message: sessionEndedMessage),
                .signIn(title: signInTitle, isEnabled: true)
            ]
        case .signedIn(let account):
            let displayName = account.name.isEmpty ? account.username : account.name
            return [
                .account(name: displayName, username: "@\(account.username)", avatar: makeAvatar(for: account)),
                .signOut(title: String(localized: "Sign out"), confirmation: makeSignOutConfirmation())
            ]
        }
    }

    func makeAvatar(for account: Account) -> DisplayedArtwork {
        DisplayedArtwork(
            path: account.avatarPath,
            size: .profile,
            placeholderSeed: account.id,
            placeholderTitle: makeInitials(for: account),
            imageURLProvider: imageURLProvider
        )
    }

    func makeInitials(for account: Account) -> String {
        let words = account.name.split(separator: " ").prefix(2)
        guard !words.isEmpty else { return String(account.username.prefix(1)).uppercased() }
        return String(words.compactMap(\.first)).uppercased()
    }

    func makeSignOutConfirmation() -> ProfileModel.DisplayedConfirmation {
        ProfileModel.DisplayedConfirmation(
            title: String(localized: "Sign out of TMDB?"),
            message: String(localized: "Saved movies and watch history stay on this device."),
            confirmTitle: String(localized: "Sign Out"),
            cancelTitle: String(localized: "Cancel")
        )
    }

    func makeClearConfirmation(title: String, message: String) -> ProfileModel.DisplayedConfirmation {
        ProfileModel.DisplayedConfirmation(
            title: title,
            message: message,
            confirmTitle: String(localized: "Clear"),
            cancelTitle: String(localized: "Cancel")
        )
    }

    func makeClearFailureAlert(title: String) -> ProfileModel.DisplayedAlert {
        ProfileModel.DisplayedAlert(
            title: title,
            message: String(localized: "Nothing was deleted. Try again."),
            actionTitle: String(localized: "OK")
        )
    }

    func makeAppearanceRow(selected: AppTheme) -> ProfileModel.Row {
        .appearance(
            title: String(localized: "Appearance"),
            options: AppTheme.allCases.map { theme in
                ProfileModel.DisplayedThemeOption(
                    theme: theme,
                    title: title(for: theme),
                    isSelected: theme == selected
                )
            }
        )
    }

    func title(for theme: AppTheme) -> String {
        switch theme {
        case .system:
            String(localized: "System")
        case .light:
            String(localized: "Light")
        case .dark:
            String(localized: "Dark")
        }
    }
}
