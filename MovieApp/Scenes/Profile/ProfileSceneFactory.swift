import UIKit

enum ProfileSceneFactory {
    struct Dependencies {
        let appInfo: AppInfo
        let appearanceRepository: any IAppearanceRepository
        let authRepository: any IAuthRepository
        let savedMoviesRepository: any ISavedMoviesRepository
        let watchProgressRepository: any IWatchProgressRepository
        let imageURLProvider: any ImageURLProvider
        let imageLoader: any IImageLoader
    }

    static func make(
        dependencies: Dependencies,
        onRequestSignIn: @escaping (@escaping () -> Void) -> Void,
        onRequestConfirmation: @escaping (ProfileModel.DisplayedConfirmation, @escaping () -> Void) -> Void,
        onShowAlert: @escaping (ProfileModel.DisplayedAlert) -> Void
    ) -> UIViewController {
        let worker = ProfileWorker(
            appearanceRepository: dependencies.appearanceRepository,
            authRepository: dependencies.authRepository,
            savedMoviesRepository: dependencies.savedMoviesRepository,
            watchProgressRepository: dependencies.watchProgressRepository
        )
        let presenter = ProfilePresenter(imageURLProvider: dependencies.imageURLProvider)
        let interactor = ProfileInteractor(presenter: presenter, worker: worker, appInfo: dependencies.appInfo)
        let router = ProfileRouter(
            onRequestSignIn: onRequestSignIn,
            onRequestConfirmation: onRequestConfirmation,
            onShowAlert: onShowAlert
        )
        let viewController = ProfileViewController(
            interactor: interactor,
            router: router,
            imageLoader: dependencies.imageLoader
        )
        presenter.viewController = viewController
        return viewController
    }
}
