nonisolated protocol IHomeWorker: Sendable {
    func fetchTrendingMovies(window: TrendingWindow) async throws -> [Movie]
    func fetchMovies(in category: MovieCategory, page: Int) async throws -> Page<Movie>
    func fetchContinueWatching(limit: Int) async throws -> [ContinueWatchingItem]
    func fetchGenres() async throws -> [Genre]
}

nonisolated struct HomeWorker {
    let movieRepository: any IMovieRepository
    let genreRepository: any IGenreRepository
    let watchProgressRepository: any IWatchProgressRepository
}

// MARK: - IHomeWorker
nonisolated extension HomeWorker: IHomeWorker {
    func fetchTrendingMovies(window: TrendingWindow) async throws -> [Movie] {
        try await movieRepository.trending(window: window)
    }

    func fetchMovies(in category: MovieCategory, page: Int) async throws -> Page<Movie> {
        try await movieRepository.movies(in: category, page: page)
    }

    // Merges the most recent unfinished records with their TMDB details, keeping recency order.
    // A movie whose details fail to load is skipped so one bad request doesn't hide the whole row.
    func fetchContinueWatching(limit: Int) async throws -> [ContinueWatchingItem] {
        let records = try await watchProgressRepository.recent(limit: limit).filter { !$0.isFinished }
        let items = await withTaskGroup(of: (Int, ContinueWatchingItem?).self) { group in
            for (index, record) in records.enumerated() {
                group.addTask {
                    let details = try? await movieRepository.details(movieID: record.contentID)
                    return (index, details.map { ContinueWatchingItem(progress: record, details: $0) })
                }
            }
            var merged: [(index: Int, item: ContinueWatchingItem)] = []
            for await (index, item) in group {
                if let item {
                    merged.append((index, item))
                }
            }
            return merged.sorted { $0.index < $1.index }.map(\.item)
        }
        try Task.checkCancellation()
        return items
    }

    func fetchGenres() async throws -> [Genre] {
        try await genreRepository.movieGenres()
    }
}
