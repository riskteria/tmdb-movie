import Foundation
import SwiftData

@ModelActor
actor SavedMovieStore {
    private var revision = 0

    func movies(for userID: UserID) throws -> StoreResult<[SavedMovie]> {
        let savedMovies = try fetchRecords(for: userID).map { record in makeSavedMovie(from: record) }
        return StoreResult(revision: revision, value: savedMovies)
    }

    func save(
        _ movie: Movie,
        for userID: UserID,
        evictionPolicy: any SavedMoviesEvictionPolicy
    ) throws -> StoreResult<[SavedMovie]> {
        try write(for: userID) {
            if let record = try fetchRecord(movie.id, for: userID) {
                record.savedAt = .now
            } else {
                modelContext.insert(SavedMovieRecord(movie: movie, userID: userID.rawValue, savedAt: .now))
            }
            let records = try fetchRecords(for: userID)
            let savedMovies = records.map { record in makeSavedMovie(from: record) }
            let evictedIDs = Set(evictionPolicy.moviesToEvict(from: savedMovies, capacity: SavedMovie.capacity))
            records.filter { evictedIDs.contains($0.movieID) }.forEach { record in modelContext.delete(record) }
        }
    }

    func remove(_ movieID: Movie.ID, for userID: UserID) throws -> StoreResult<[SavedMovie]> {
        try write(for: userID) {
            if let record = try fetchRecord(movieID, for: userID) {
                modelContext.delete(record)
            }
        }
    }

    func removeAll(for userID: UserID) throws -> StoreResult<[SavedMovie]> {
        try write(for: userID) {
            try fetchRecords(for: userID).forEach { record in modelContext.delete(record) }
        }
    }
}

private extension SavedMovieStore {
    func write(for userID: UserID, _ changes: () throws -> Void) throws -> StoreResult<[SavedMovie]> {
        do {
            try changes()
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
        revision += 1
        return try movies(for: userID)
    }

    func fetchRecords(for userID: UserID) throws -> [SavedMovieRecord] {
        let owner = userID.rawValue
        let descriptor = FetchDescriptor<SavedMovieRecord>(
            predicate: #Predicate { $0.userID == owner },
            sortBy: [SortDescriptor(\.savedAt, order: .reverse), SortDescriptor(\.movieID)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchRecord(_ movieID: Movie.ID, for userID: UserID) throws -> SavedMovieRecord? {
        let owner = userID.rawValue
        var descriptor = FetchDescriptor<SavedMovieRecord>(
            predicate: #Predicate { $0.userID == owner && $0.movieID == movieID }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func makeSavedMovie(from record: SavedMovieRecord) -> SavedMovie {
        SavedMovie(
            movie: Movie(
                id: record.movieID,
                title: record.title,
                overview: record.overview,
                releaseDate: record.releaseDate,
                posterPath: record.posterPath.map(ImagePath.init(rawValue:)),
                backdropPath: record.backdropPath.map(ImagePath.init(rawValue:)),
                genreIDs: record.genreIDs,
                voteAverage: record.voteAverage
            ),
            savedAt: record.savedAt
        )
    }
}
