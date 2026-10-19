import Foundation

protocol IMovieDetailPresenter {
    func presentDetails(response: MovieDetailModel.LoadDetails.Response)
    func presentSavedState(response: MovieDetailModel.ObserveSavedState.Response)
    func presentToggleSave(response: MovieDetailModel.ToggleSave.Response)
    func presentWatch(response: MovieDetailModel.Watch.Response)
}

final class MovieDetailPresenter {
    weak var viewController: (any IMovieDetailViewController)?
    private let imageURLProvider: any ImageURLProvider
    private let videoURLProvider: any VideoURLProvider

    init(imageURLProvider: any ImageURLProvider, videoURLProvider: any VideoURLProvider) {
        self.imageURLProvider = imageURLProvider
        self.videoURLProvider = videoURLProvider
    }
}

// MARK: - IMovieDetailPresenter
extension MovieDetailPresenter: IMovieDetailPresenter {
    func presentDetails(response: MovieDetailModel.LoadDetails.Response) {
        switch response.details {
        case nil:
            viewController?.displayDetails(viewData: .loading(makeDetail(from: response.movie, details: nil)))
        case .success(let details):
            let detail = makeDetail(from: details.movie, details: details)
            viewController?.displayDetails(viewData: .content(detail, makeExtras(from: details)))
        case .failure:
            viewController?.displayDetails(viewData: .failure(message: String(localized: "Unable to load this movie")))
        }
    }

    func presentSavedState(response: MovieDetailModel.ObserveSavedState.Response) {
        let viewData: MovieDetailModel.ObserveSavedState.ViewData = switch response.savedState {
        case .signedOut:
            .hidden
        case .signedIn(let isSaved):
            .visible(title: isSaved ? String(localized: "Saved") : String(localized: "Save"), isSaved: isSaved)
        }
        viewController?.displaySavedState(viewData: viewData)
    }

    func presentToggleSave(response: MovieDetailModel.ToggleSave.Response) {
        let title = response.movie.title
        let message = switch response.action {
        case .save:
            String(localized: "Couldn't save “\(title)”")
        case .remove:
            String(localized: "Couldn't remove “\(title)”")
        }
        viewController?.displayToggleSave(viewData: MovieDetailModel.ToggleSave.ViewData(message: message))
    }

    func presentWatch(response: MovieDetailModel.Watch.Response) {
        switch response.result {
        case .success(let video):
            viewController?.displayWatch(viewData: .trailer(video))
        case .failure:
            let title = response.movie.title
            viewController?.displayWatch(
                viewData: .failure(message: String(localized: "Couldn't add “\(title)” to Continue Watching"))
            )
        }
    }
}

private extension MovieDetailPresenter {
    // "2024 • Science Fiction, Adventure • 2h 46m • PG-13". Only the year is known before details load.
    func makeDetail(from movie: Movie, details: MovieDetails?) -> MovieDetailModel.DisplayedDetail {
        let parts = [
            movie.releaseDate?.formatted(.dateTime.year()),
            details.map { $0.genres.prefix(2).map(\.name).joined(separator: ", ") },
            details?.runtime?.formatted(.units(allowed: [.hours, .minutes], width: .narrow)),
            details?.certification
        ]
        return MovieDetailModel.DisplayedDetail(
            movie: movie,
            title: movie.title,
            metadata: parts.compactMap(\.self).filter { !$0.isEmpty }.joined(separator: " • "),
            overview: movie.overview,
            artwork: DisplayedArtwork(
                path: movie.backdropPath,
                size: .backdropLarge,
                placeholderSeed: movie.id,
                placeholderTitle: nil,
                imageURLProvider: imageURLProvider
            ),
            watch: makeWatchAvailability(from: details)
        )
    }

    func makeWatchAvailability(from details: MovieDetails?) -> MovieDetailModel.WatchAvailability {
        guard let details else { return .pending }
        return details.mainTrailer.map(MovieDetailModel.WatchAvailability.available) ?? .unavailable
    }

    func makeExtras(from details: MovieDetails) -> MovieDetailModel.DisplayedExtras {
        MovieDetailModel.DisplayedExtras(
            rating: makeRating(from: details),
            cast: removingDuplicates(details.cast.map(makeCastMember(from:)), by: \.self),
            moreLikeThis: makeMoreLikeThis(from: details.recommendations),
            trailers: makeTrailers(from: details.videos, movieID: details.movie.id)
        )
    }
}

// MARK: - Rating and Cast
private extension MovieDetailPresenter {
    func makeRating(from details: MovieDetails) -> MovieDetailModel.DisplayedRating? {
        guard details.voteCount > 0 else { return nil }
        let score = details.movie.voteAverage.formatted(.number.precision(.fractionLength(1)))
        let shortCount = details.voteCount.formatted(.number.notation(.compactName))
        let fullCount = details.voteCount.formatted()
        let isSingleVote = details.voteCount == 1
        return MovieDetailModel.DisplayedRating(
            score: score,
            votes: isSingleVote ? String(localized: "TMDB · 1 vote") : String(localized: "TMDB · \(shortCount) votes"),
            accessibilityLabel: isSingleVote
                ? String(localized: "Rated \(score) out of 10, 1 vote")
                : String(localized: "Rated \(score) out of 10, \(fullCount) votes")
        )
    }

    func makeCastMember(from member: CastMember) -> MovieDetailModel.DisplayedCastMember {
        let initials = makeInitials(from: member.name)
        return MovieDetailModel.DisplayedCastMember(
            id: member.id,
            name: member.name,
            character: member.character,
            artwork: DisplayedArtwork(
                path: member.profilePath,
                size: .profile,
                placeholderSeed: member.id,
                placeholderTitle: initials.isEmpty ? nil : initials,
                imageURLProvider: imageURLProvider
            )
        )
    }

    func makeInitials(from name: String) -> String {
        let words = name.split(whereSeparator: \.isWhitespace)
        let initialWords = words.count > 1 ? [words.first, words.last] : [words.first]
        return String(initialWords.compactMap { $0?.first }).uppercased()
    }
}

// MARK: - Tabs
private extension MovieDetailPresenter {
    func makeMoreLikeThis(
        from recommendations: [Movie]
    ) -> MovieDetailModel.DisplayedTabContent<MovieDetailModel.DisplayedMovie> {
        let movies = removingDuplicates(recommendations, by: \.id).map(makeDisplayedMovie(from:))
        guard !movies.isEmpty else { return .empty(message: String(localized: "No similar movies yet")) }
        return .items(movies)
    }

    func makeDisplayedMovie(from movie: Movie) -> MovieDetailModel.DisplayedMovie {
        MovieDetailModel.DisplayedMovie(
            movie: movie,
            title: movie.title,
            rating: movie.voteAverage > 0 ? movie.voteAverage.formatted(.number.precision(.fractionLength(1))) : nil,
            artwork: DisplayedArtwork(
                path: movie.posterPath,
                size: .posterMedium,
                placeholderSeed: movie.id,
                placeholderTitle: movie.title,
                imageURLProvider: imageURLProvider
            )
        )
    }

    func makeTrailers(
        from videos: [Video],
        movieID: Movie.ID
    ) -> MovieDetailModel.DisplayedTabContent<MovieDetailModel.DisplayedTrailer> {
        let trailers = videos
            .filter { $0.kind == .trailer || $0.kind == .teaser }
            .sorted { ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast) }
            .map { video in makeDisplayedTrailer(from: video, movieID: movieID) }
        guard !trailers.isEmpty else { return .empty(message: String(localized: "No trailers yet")) }
        return .items(trailers)
    }

    func makeDisplayedTrailer(from video: Video, movieID: Movie.ID) -> MovieDetailModel.DisplayedTrailer {
        let kindName = video.kind == .teaser ? String(localized: "Teaser") : String(localized: "Trailer")
        let metadata = video.publishedAt.map { date in
            String(localized: "\(kindName) • \(date.formatted(date: .abbreviated, time: .omitted))")
        }
        let accessibilityValue = video.publishedAt.map { date in
            String(localized: "\(kindName), \(date.formatted(date: .long, time: .omitted))")
        }
        return MovieDetailModel.DisplayedTrailer(
            video: video,
            title: video.name,
            metadata: metadata ?? kindName,
            accessibilityValue: accessibilityValue ?? kindName,
            artwork: DisplayedArtwork(
                url: videoURLProvider.thumbnailURL(for: video),
                placeholderSeed: movieID,
                placeholderTitle: nil
            )
        )
    }

    func removingDuplicates<Item, Key: Hashable>(_ items: [Item], by key: (Item) -> Key) -> [Item] {
        var seenKeys = Set<Key>()
        return items.filter { item in seenKeys.insert(key(item)).inserted }
    }
}
