import Foundation

protocol IProfilePresenter {
    func presentProfile(response: ProfileModel.LoadProfile.Response)
}

final class ProfilePresenter {
    weak var viewController: (any IProfileViewController)?
}

// MARK: - IProfilePresenter
extension ProfilePresenter: IProfilePresenter {
    func presentProfile(response: ProfileModel.LoadProfile.Response) {
        let appInfo = response.appInfo
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
                    .clearSavedData(title: String(localized: "Clear Saved data")),
                    .clearWatchHistory(title: String(localized: "Clear watch history"))
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
        case .signedIn(let account):
            let displayName = account.name.isEmpty ? account.username : account.name
            return [
                .account(name: displayName, username: "@\(account.username)"),
                .signOut(title: String(localized: "Sign out"), confirmation: makeSignOutConfirmation())
            ]
        }
    }

    func makeSignOutConfirmation() -> ProfileModel.DisplayedConfirmation {
        ProfileModel.DisplayedConfirmation(
            title: String(localized: "Sign out of TMDB?"),
            message: String(localized: "Saved movies and watch history stay on this device."),
            confirmTitle: String(localized: "Sign Out"),
            cancelTitle: String(localized: "Cancel")
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
