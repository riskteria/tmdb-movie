import UIKit

enum ProfileSceneFactory {
    static func make(appInfo: AppInfo) -> UIViewController {
        let presenter = ProfilePresenter()
        let interactor = ProfileInteractor(presenter: presenter, appInfo: appInfo)
        let viewController = ProfileViewController(interactor: interactor)
        presenter.viewController = viewController
        return viewController
    }
}
