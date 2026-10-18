nonisolated protocol SavedMoviesEvictionPolicy: Sendable {
    func moviesToEvict(from savedMovies: [SavedMovie], capacity: Int) -> [Movie.ID]
}
