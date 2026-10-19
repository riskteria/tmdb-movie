import Foundation
import SwiftData

@ModelActor
actor SavedMovieStore {
    private var revision = 0

    func movies(for accountID: Account.ID) throws -> StoreResult<[SavedMovie]> {
        let savedMovies = try fetchRecords(for: accountID).map { record in makeSavedMovie(from: record) }
        return StoreResult(revision: revision, value: savedMovies)
    }

    func save(
        _ movie: Movie,
        for accountID: Account.ID,
        evictionPolicy: any ISavedFirstEvictionPolicy
    ) throws -> StoreResult<[SavedMovie]> {
        try write(for: accountID) {
            if let record = try fetchRecord(movie.id, for: accountID) {
                record.savedAt = .now
            } else {
                modelContext.insert(SavedMovieRecord(movie: movie, accountID: accountID, savedAt: .now))
            }
            let records = try fetchRecords(for: accountID)
            let savedMovies = records.map { record in makeSavedMovie(from: record) }
            let evictedIDs = Set(evictionPolicy.moviesToEvict(from: savedMovies, capacity: SavedMovie.capacity))
            records.filter { evictedIDs.contains($0.movieID) }.forEach { record in modelContext.delete(record) }
        }
    }

    func remove(_ movieID: Movie.ID, for accountID: Account.ID) throws -> StoreResult<[SavedMovie]> {
        try write(for: accountID) {
            if let record = try fetchRecord(movieID, for: accountID) {
                modelContext.delete(record)
            }
        }
    }

    func removeAll(for accountID: Account.ID) throws -> StoreResult<[SavedMovie]> {
        try write(for: accountID) {
            try fetchRecords(for: accountID).forEach { record in modelContext.delete(record) }
        }
    }
}

private extension SavedMovieStore {
    func write(for accountID: Account.ID, _ changes: () throws -> Void) throws -> StoreResult<[SavedMovie]> {
        do {
            try changes()
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
        revision += 1
        return try movies(for: accountID)
    }

    func fetchRecords(for accountID: Account.ID) throws -> [SavedMovieRecord] {
        let descriptor = FetchDescriptor<SavedMovieRecord>(
            predicate: #Predicate { $0.accountID == accountID },
            sortBy: [SortDescriptor(\.savedAt, order: .reverse), SortDescriptor(\.movieID)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchRecord(_ movieID: Movie.ID, for accountID: Account.ID) throws -> SavedMovieRecord? {
        var descriptor = FetchDescriptor<SavedMovieRecord>(
            predicate: #Predicate { $0.accountID == accountID && $0.movieID == movieID }
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
