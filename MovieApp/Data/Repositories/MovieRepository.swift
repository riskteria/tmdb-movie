nonisolated struct MovieRepository {
    private let apiService: any IAPIService
    private let language: String
    private let region: String

    init(apiService: any IAPIService, language: String = "en-US", region: String = "US") {
        self.apiService = apiService
        self.language = language
        self.region = region
    }
}

// MARK: - IMovieRepository
nonisolated extension MovieRepository: IMovieRepository {
    func trending(window: TrendingWindow) async throws -> [Movie] {
        let response: TrendingMoviesDTO.Response = try await apiService.request(
            .trendingMovies(timeWindow: window.dto, parameters: .init(language: language))
        )
        return response.results.map(makeMovie(from:))
    }

    func movies(in category: MovieCategory, page: Int) async throws -> Page<Movie> {
        let parameters = MovieListDTO.Parameters(
            language: language,
            page: page,
            region: category.isRegional ? region : nil
        )
        let response: MovieListDTO.Response = try await apiService.request(
            .movieList(category: category.dto, parameters: parameters)
        )
        return makePage(from: response)
    }

    func discover(genreIDs: [Genre.ID], page: Int) async throws -> Page<Movie> {
        let parameters = DiscoverMoviesDTO.Parameters(
            language: language,
            page: page,
            sortBy: .popularityDescending,
            withGenres: genreIDs.map(String.init).joined(separator: ",")
        )
        let response: DiscoverMoviesDTO.Response = try await apiService.request(.discoverMovies(parameters: parameters))
        return makePage(from: response)
    }

    func search(query: String, page: Int) async throws -> Page<Movie> {
        let parameters = SearchMoviesDTO.Parameters(query: query, language: language, page: page)
        let response: SearchMoviesDTO.Response = try await apiService.request(.searchMovies(parameters: parameters))
        return makePage(from: response)
    }

    func details(movieID: Movie.ID) async throws -> MovieDetails {
        let parameters = MovieDetailsDTO.Parameters(
            appendToResponse: [.credits, .videos, .releaseDates, .recommendations],
            language: language
        )
        let response: MovieDetailsDTO.Response = try await apiService.request(
            .movieDetails(movieID: movieID, parameters: parameters)
        )
        return makeMovieDetails(from: response)
    }
}

// MARK: - Mapping
private nonisolated extension MovieRepository {
    func makePage(from response: PageDTO<MovieSummaryDTO>) -> Page<Movie> {
        Page(
            number: response.page,
            items: response.results.map(makeMovie(from:)),
            totalPages: response.totalPages,
            totalResults: response.totalResults
        )
    }

    func makeMovie(from summary: MovieSummaryDTO) -> Movie {
        Movie(
            id: summary.id,
            title: summary.title,
            overview: summary.overview,
            releaseDate: summary.releaseDate?.tmdbDate(),
            posterPath: makeImagePath(from: summary.posterPath),
            backdropPath: makeImagePath(from: summary.backdropPath),
            genreIDs: summary.genreIDs,
            voteAverage: summary.voteAverage
        )
    }

    func makeMovieDetails(from response: MovieDetailsDTO.Response) -> MovieDetails {
        let castLimit = 15
        return MovieDetails(
            movie: Movie(
                id: response.id,
                title: response.title,
                overview: response.overview,
                releaseDate: response.releaseDate?.tmdbDate(),
                posterPath: makeImagePath(from: response.posterPath),
                backdropPath: makeImagePath(from: response.backdropPath),
                genreIDs: response.genres.map(\.id),
                voteAverage: response.voteAverage
            ),
            runtime: response.runtime.flatMap { minutes in minutes > 0 ? .seconds(minutes * 60) : nil },
            genres: response.genres.map { genre in Genre(id: genre.id, name: genre.name) },
            tagline: response.tagline?.nonEmpty,
            certification: makeCertification(from: response.releaseDates, countryCode: region),
            cast: (response.credits?.cast ?? [])
                .sorted { $0.order < $1.order }
                .prefix(castLimit)
                .map(makeCastMember(from:)),
            videos: (response.videos?.results ?? []).filter { $0.site == "YouTube" }.map(makeVideo(from:)),
            recommendations: response.recommendations?.results.map(makeMovie(from:)) ?? []
        )
    }

    func makeCertification(from releaseDates: MovieDetailsDTO.ReleaseDates?, countryCode: String) -> String? {
        let theatricalReleaseType = 3
        let country = releaseDates?.results.first { $0.countryCode == countryCode }
        let rated = (country?.releaseDates ?? []).filter { !$0.certification.isEmpty }
        return (rated.first { $0.type == theatricalReleaseType } ?? rated.first)?.certification
    }

    func makeCastMember(from member: MovieDetailsDTO.CastMember) -> CastMember {
        CastMember(
            id: member.id,
            name: member.name,
            character: member.character,
            profilePath: makeImagePath(from: member.profilePath)
        )
    }

    func makeVideo(from video: MovieDetailsDTO.Video) -> Video {
        Video(
            id: video.id,
            key: video.key,
            name: video.name,
            kind: makeVideoKind(from: video.type),
            publishedAt: video.publishedAt.tmdbTimestamp()
        )
    }

    func makeVideoKind(from type: String) -> Video.Kind {
        switch type {
        case "Trailer":
            .trailer
        case "Teaser":
            .teaser
        case "Clip":
            .clip
        case "Featurette":
            .featurette
        case "Behind the Scenes":
            .behindTheScenes
        default:
            .other
        }
    }

    func makeImagePath(from path: String?) -> ImagePath? {
        path?.nonEmpty.map(ImagePath.init(rawValue:))
    }
}

private nonisolated extension TrendingWindow {
    var dto: TrendingMoviesDTO.TimeWindow {
        switch self {
        case .day:
            .day
        case .week:
            .week
        }
    }
}

private nonisolated extension MovieCategory {
    var dto: MovieListDTO.Category {
        switch self {
        case .nowPlaying:
            .nowPlaying
        case .popular:
            .popular
        case .topRated:
            .topRated
        case .upcoming:
            .upcoming
        }
    }

    var isRegional: Bool {
        switch self {
        case .nowPlaying, .upcoming:
            true
        case .popular, .topRated:
            false
        }
    }
}
