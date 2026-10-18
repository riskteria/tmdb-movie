import UIKit

enum ProfileSceneFactory {
    struct Dependencies {
        let appInfo: AppInfo
        let appearanceRepository: any IAppearanceRepository
        let authRepository: any IAuthRepository
        let imageURLProvider: any ImageURLProvider
        let imageLoader: any IImageLoader
    }

    static func make(
        dependencies: Dependencies,
        onRequestSignIn: @escaping (@escaping () -> Void) -> Void,
        onRequestSignOut: @escaping (ProfileModel.DisplayedConfirmation, @escaping () -> Void) -> Void
    ) -> UIViewController {
        let worker = ProfileWorker(
            appearanceRepository: dependencies.appearanceRepository,
            authRepository: dependencies.authRepository
        )
        let presenter = ProfilePresenter(imageURLProvider: dependencies.imageURLProvider)
        let interactor = ProfileInteractor(presenter: presenter, worker: worker, appInfo: dependencies.appInfo)
        let router = ProfileRouter(onRequestSignIn: onRequestSignIn, onRequestSignOut: onRequestSignOut)
        let viewController = ProfileViewController(
            interactor: interactor,
            router: router,
            imageLoader: dependencies.imageLoader
        )
        presenter.viewController = viewController
        return viewController
    }
}
