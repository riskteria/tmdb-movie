import Networking

nonisolated struct CallbackGenreRepository {
    private let apiService: any ICallbackAPIService
    private let language: String

    init(apiService: any ICallbackAPIService, language: String = "en-US") {
        self.apiService = apiService
        self.language = language
    }
}

// MARK: - ICallbackGenreRepository
nonisolated extension CallbackGenreRepository: ICallbackGenreRepository {
    func movieGenres(completion: @escaping @Sendable (Result<[Genre], any Error>) -> Void) {
        let endpoint = TMDBEndpoint.movieGenres(parameters: .init(language: language))
        apiService.request(endpoint) { (result: Result<MovieGenresDTO.Response, any Error>) in
            completion(result.map { response in response.genres.map { Genre(id: $0.id, name: $0.name) } })
        }
    }
}
