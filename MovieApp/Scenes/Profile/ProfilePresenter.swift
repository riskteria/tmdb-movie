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
                rows: [.appearance(title: String(localized: "Appearance"), value: String(localized: "System"))]
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
