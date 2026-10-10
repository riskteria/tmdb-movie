import Foundation

protocol IHomePresenter {
    func presentHome(response: HomeModel.LoadHome.Response)
}

final class HomePresenter {
    private static let bannerCount = 5

    weak var viewController: (any IHomeViewController)?
    private let imageURLProvider: any ImageURLProvider

    init(imageURLProvider: any ImageURLProvider) {
        self.imageURLProvider = imageURLProvider
    }
}

// MARK: - IHomePresenter
extension HomePresenter: IHomePresenter {
    // A failed or empty section is hidden. Only when every section fails does the screen show an error.
    func presentHome(response: HomeModel.LoadHome.Response) {
        if everySectionFailed(in: response) {
            viewController?.displayHome(viewData: .failure(message: String(localized: "Unable to load movies")))
            return
        }
        let genreNames = Dictionary(((try? response.genres.get()) ?? []).map { ($0.id, $0.name) }) { first, _ in first }
        let sections = [
            makeHeroSection(from: response.trending, genreNames: genreNames),
            makeContinueWatchingSection(from: response.continueWatching),
            makePosterSection(.popular, title: String(localized: "Popular"), from: response.popular),
            makePosterSection(.topRated, title: String(localized: "Top Rated"), from: response.topRated),
            makePosterSection(.upcoming, title: String(localized: "Upcoming"), from: response.upcoming)
        ].compactMap(\.self)
        if sections.isEmpty {
            viewController?.displayHome(viewData: .empty(message: String(localized: "No movies to show yet")))
        } else {
            viewController?.displayHome(viewData: .content(sections))
        }
    }
}

private extension HomePresenter {
    func everySectionFailed(in response: HomeModel.LoadHome.Response) -> Bool {
        [
            (try? response.trending.get()) == nil,
            (try? response.continueWatching.get()) == nil,
            (try? response.popular.get()) == nil,
            (try? response.topRated.get()) == nil,
            (try? response.upcoming.get()) == nil
        ].allSatisfy(\.self)
    }

    func makeHeroSection(
        from result: Result<[Movie], any Error>,
        genreNames: [Genre.ID: String]
    ) -> HomeModel.DisplayedSection? {
        let movies = (try? result.get()) ?? []
        guard !movies.isEmpty else { return nil }
        let banners = movies.prefix(Self.bannerCount).map { makeBanner(from: $0, genreNames: genreNames) }
        return HomeModel.DisplayedSection(section: .hero, title: nil, items: [.hero(banners)])
    }

    func makeContinueWatchingSection(from result: Result<[ContinueWatchingItem], any Error>) -> HomeModel.DisplayedSection? {
        let items = (try? result.get()) ?? []
        guard !items.isEmpty else { return nil }
        return HomeModel.DisplayedSection(
            section: .continueWatching,
            title: String(localized: "Continue Watching"),
            items: items.map { .continueWatching(makeContinueWatching(from: $0)) }
        )
    }

    func makePosterSection(
        _ section: HomeModel.Section,
        title: String,
        from result: Result<Page<Movie>, any Error>
    ) -> HomeModel.DisplayedSection? {
        let movies = (try? result.get())?.items ?? []
        guard !movies.isEmpty else { return nil }
        return HomeModel.DisplayedSection(
            section: section,
            title: title,
            items: movies.map { .poster(makePoster(from: $0), section: section) }
        )
    }

    func makeBanner(from movie: Movie, genreNames: [Genre.ID: String]) -> HomeModel.DisplayedBanner {
        let genres = movie.genreIDs.prefix(2).compactMap { genreNames[$0] }.joined(separator: ", ")
        let year = movie.releaseDate?.formatted(.dateTime.year()) ?? ""
        let metadata = [year, genres, String(localized: "Movie")].filter { !$0.isEmpty }.joined(separator: " • ")
        return HomeModel.DisplayedBanner(
            movie: movie,
            title: movie.title,
            metadata: metadata,
            artwork: artwork(for: movie.backdropPath, size: .backdropLarge, movie: movie, showsTitle: false)
        )
    }

    func makeContinueWatching(from item: ContinueWatchingItem) -> HomeModel.DisplayedContinueWatching {
        let movie = item.details.movie
        let remaining = item.progress.remaining.formatted(.time(pattern: .minuteSecond))
        return HomeModel.DisplayedContinueWatching(
            movie: movie,
            title: movie.title,
            subtitle: String(localized: "Trailer · \(remaining) left"),
            progress: item.progress.progress,
            artwork: artwork(for: movie.backdropPath, size: .backdropMedium, movie: movie, showsTitle: false)
        )
    }

    func makePoster(from movie: Movie) -> HomeModel.DisplayedPoster {
        HomeModel.DisplayedPoster(
            movie: movie,
            title: movie.title,
            artwork: artwork(for: movie.posterPath, size: .posterMedium, movie: movie, showsTitle: true)
        )
    }

    func artwork(for path: ImagePath?, size: ImageSize, movie: Movie, showsTitle: Bool) -> DisplayedArtwork {
        DisplayedArtwork(
            path: path,
            size: size,
            placeholderSeed: movie.id,
            placeholderTitle: showsTitle ? movie.title : nil,
            imageURLProvider: imageURLProvider
        )
    }
}
