protocol IProfileInteractor {
    func loadProfile(request: ProfileModel.LoadProfile.Request)
}

// Week 4 adds Clear Saved data, Clear watch history and the Appearance setting.
final class ProfileInteractor {
    private let presenter: any IProfilePresenter
    private let appInfo: AppInfo

    init(presenter: any IProfilePresenter, appInfo: AppInfo) {
        self.presenter = presenter
        self.appInfo = appInfo
    }
}

// MARK: - IProfileInteractor
extension ProfileInteractor: IProfileInteractor {
    func loadProfile(request: ProfileModel.LoadProfile.Request) {
        presenter.presentProfile(response: ProfileModel.LoadProfile.Response(appInfo: appInfo))
    }
}
