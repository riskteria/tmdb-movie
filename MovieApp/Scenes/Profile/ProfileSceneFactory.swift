import UIKit

enum ProfileSceneFactory {
    static func make(appInfo: AppInfo, appearanceRepository: any IAppearanceRepository) -> UIViewController {
        let worker = ProfileWorker(appearanceRepository: appearanceRepository)
        let presenter = ProfilePresenter()
        let interactor = ProfileInteractor(presenter: presenter, worker: worker, appInfo: appInfo)
        let viewController = ProfileViewController(interactor: interactor)
        presenter.viewController = viewController
        return viewController
    }
}
