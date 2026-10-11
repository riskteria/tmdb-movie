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
                rows: [
                    .guest(
                        title: String(localized: "Browsing as guest"),
                        message: String(localized: "Saved movies and watch history stay on this device.")
                    )
                ]
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
