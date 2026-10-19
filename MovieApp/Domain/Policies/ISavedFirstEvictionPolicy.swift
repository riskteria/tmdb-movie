nonisolated protocol ISavedFirstEvictionPolicy: Sendable {
    func moviesToEvict(from savedMovies: [SavedMovie], capacity: Int) -> [Movie.ID]
}
