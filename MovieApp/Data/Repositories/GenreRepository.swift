import Networking

nonisolated struct GenreRepository {
    private let apiService: any IAPIService
    private let language: String

    init(apiService: any IAPIService, language: String = "en-US") {
        self.apiService = apiService
        self.language = language
    }
}

// MARK: - IGenreRepository
nonisolated extension GenreRepository: IGenreRepository {
    func movieGenres() async throws -> [Genre] {
        let response: MovieGenresDTO.Response = try await apiService.request(
            .movieGenres(parameters: .init(language: language))
        )

        let genres = response.genres.map { Genre(id: $0.id, name: $0.name) }

        return genres
    }
}
