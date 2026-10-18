protocol IProfileInteractor {
    func loadProfile(request: ProfileModel.LoadProfile.Request) async
    func changeAppearance(request: ProfileModel.ChangeAppearance.Request) async
    func signIn(request: ProfileModel.SignIn.Request) async
    func signOut(request: ProfileModel.SignOut.Request) async
    func clearSavedData(request: ProfileModel.ClearSavedData.Request) async
    func clearWatchHistory(request: ProfileModel.ClearWatchHistory.Request) async
}

final class ProfileInteractor {
    private let presenter: any IProfilePresenter
    private let worker: any IProfileWorker
    private let appInfo: AppInfo
    private var theme: AppTheme?
    private var accountState: ProfileModel.AccountState?
    private var isSessionEnded = false

    init(presenter: any IProfilePresenter, worker: any IProfileWorker, appInfo: AppInfo) {
        self.presenter = presenter
        self.worker = worker
        self.appInfo = appInfo
    }
}

// MARK: - IProfileInteractor
extension ProfileInteractor: IProfileInteractor {
    func loadProfile(request: ProfileModel.LoadProfile.Request) async {
        async let themes: Void = observeThemes()
        async let authStates: Void = observeAuthStates()
        async let refresh: Void = refreshAccount()
        _ = await (themes, authStates, refresh)
    }

    func changeAppearance(request: ProfileModel.ChangeAppearance.Request) async {
        await worker.saveTheme(request.theme)
    }

    func signIn(request: ProfileModel.SignIn.Request) async {
        isSessionEnded = false
        update(accountState: .signInPending)
        do {
            let account = try await worker.signIn()
            update(accountState: .signedIn(account))
        } catch is CancellationError {
            update(accountState: .guest)
        } catch {
            update(accountState: .signInFailed)
        }
    }

    func signOut(request: ProfileModel.SignOut.Request) async {
        await worker.signOut()
    }

    func clearSavedData(request: ProfileModel.ClearSavedData.Request) async {
        do {
            try await worker.clearSavedMovies()
        } catch is CancellationError {
            return
        } catch {
            presenter.presentClearSavedData(response: ProfileModel.ClearSavedData.Response())
        }
    }

    func clearWatchHistory(request: ProfileModel.ClearWatchHistory.Request) async {
        do {
            try await worker.clearWatchHistory()
        } catch is CancellationError {
            return
        } catch {
            presenter.presentClearWatchHistory(response: ProfileModel.ClearWatchHistory.Response())
        }
    }
}

private extension ProfileInteractor {
    func observeThemes() async {
        for await theme in await worker.observeTheme() {
            self.theme = theme
            presentProfileIfReady()
        }
    }

    func observeAuthStates() async {
        for await state in await worker.observeAuthState() {
            switch state {
            case .signedOut:
                update(accountState: isSessionEnded ? .sessionEnded : .guest)
            case .signedIn(let account):
                update(accountState: .signedIn(account))
            }
        }
    }

    func refreshAccount() async {
        guard await worker.refreshAccount() == .sessionEnded else { return }
        isSessionEnded = true
        update(accountState: .sessionEnded)
    }

    func update(accountState: ProfileModel.AccountState) {
        self.accountState = accountState
        presentProfileIfReady()
    }

    func presentProfileIfReady() {
        guard let theme, let accountState else { return }
        presenter.presentProfile(
            response: ProfileModel.LoadProfile.Response(appInfo: appInfo, theme: theme, accountState: accountState)
        )
    }
}
