import Foundation

nonisolated struct SavedFirstEvictionPolicy {}

// MARK: - ISavedFirstEvictionPolicy
nonisolated extension SavedFirstEvictionPolicy: ISavedFirstEvictionPolicy {
    func moviesToEvict(from savedMovies: [SavedMovie], capacity: Int) -> [Movie.ID] {
        let overflow = savedMovies.count - capacity
        guard overflow > 0 else { return [] }
        return savedMovies
            .sorted { ($0.savedAt, $0.id) < ($1.savedAt, $1.id) }
            .prefix(overflow)
            .map(\.id)
    }
}
