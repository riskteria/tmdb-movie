protocol IProfileInteractor {
    func loadProfile(request: ProfileModel.LoadProfile.Request) async
    func changeAppearance(request: ProfileModel.ChangeAppearance.Request) async
}

final class ProfileInteractor {
    private let presenter: any IProfilePresenter
    private let worker: any IProfileWorker
    private let appInfo: AppInfo

    init(presenter: any IProfilePresenter, worker: any IProfileWorker, appInfo: AppInfo) {
        self.presenter = presenter
        self.worker = worker
        self.appInfo = appInfo
    }
}

// MARK: - IProfileInteractor
extension ProfileInteractor: IProfileInteractor {
    func loadProfile(request: ProfileModel.LoadProfile.Request) async {
        for await theme in await worker.observeTheme() {
            presenter.presentProfile(response: ProfileModel.LoadProfile.Response(appInfo: appInfo, theme: theme))
        }
    }

    func changeAppearance(request: ProfileModel.ChangeAppearance.Request) async {
        await worker.saveTheme(request.theme)
    }
}
