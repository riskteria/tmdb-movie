@testable import MovieApp

@MainActor
final class MovieDetailViewControllerSpy: IMovieDetailViewController {
    private(set) var displayedViewData: [MovieDetailModel.LoadDetails.ViewData] = []
    private(set) var displayedSavedStates: [MovieDetailModel.ObserveSavedState.ViewData] = []
    private(set) var displayedToggleSaves: [MovieDetailModel.ToggleSave.ViewData] = []
    private(set) var displayedWatches: [MovieDetailModel.Watch.ViewData] = []

    func displayDetails(viewData: MovieDetailModel.LoadDetails.ViewData) {
        displayedViewData.append(viewData)
    }

    func displaySavedState(viewData: MovieDetailModel.ObserveSavedState.ViewData) {
        displayedSavedStates.append(viewData)
    }

    func displayToggleSave(viewData: MovieDetailModel.ToggleSave.ViewData) {
        displayedToggleSaves.append(viewData)
    }

    func displayWatch(viewData: MovieDetailModel.Watch.ViewData) {
        displayedWatches.append(viewData)
    }
}
