import UIKit

enum ProfileSceneFactory {
    static func make(
        appInfo: AppInfo,
        appearanceRepository: any IAppearanceRepository,
        authRepository: any IAuthRepository,
        onRequestSignOut: @escaping (ProfileModel.DisplayedConfirmation, @escaping () -> Void) -> Void
    ) -> UIViewController {
        let worker = ProfileWorker(appearanceRepository: appearanceRepository, authRepository: authRepository)
        let presenter = ProfilePresenter()
        let interactor = ProfileInteractor(presenter: presenter, worker: worker, appInfo: appInfo)
        let router = ProfileRouter(onRequestSignOut: onRequestSignOut)
        let viewController = ProfileViewController(interactor: interactor, router: router)
        presenter.viewController = viewController
        return viewController
    }
}
