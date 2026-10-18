import Foundation
@testable import MovieApp

extension Date {
    static func fixture(year: Int, month: Int, day: Int) -> Date? {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
    }
}

extension Movie {
    static func fixture(
        id: Int = 693134,
        title: String = "Dune: Part Two",
        releaseDate: Date? = .fixture(year: 2024, month: 2, day: 27),
        posterPath: ImagePath? = nil,
        backdropPath: ImagePath? = nil,
        genreIDs: [Genre.ID] = [878, 12],
        voteAverage: Double = 8.2
    ) -> Movie {
        Movie(
            id: id,
            title: title,
            overview: "Paul Atreides unites with the Fremen.",
            releaseDate: releaseDate,
            posterPath: posterPath,
            backdropPath: backdropPath,
            genreIDs: genreIDs,
            voteAverage: voteAverage
        )
    }
}

extension Genre {
    static let scienceFiction = Genre(id: 878, name: "Science Fiction")
    static let adventure = Genre(id: 12, name: "Adventure")
    static let drama = Genre(id: 18, name: "Drama")
    static let action = Genre(id: 28, name: "Action")
}

extension MovieDetails {
    static func fixture(
        movie: Movie = .fixture(),
        runtime: Duration? = .seconds(166 * 60),
        genres: [Genre] = [.scienceFiction, .adventure],
        voteCount: Int = 6123,
        certification: String? = "PG-13",
        cast: [CastMember] = [],
        videos: [Video] = [],
        recommendations: [Movie] = []
    ) -> MovieDetails {
        MovieDetails(
            movie: movie,
            runtime: runtime,
            genres: genres,
            voteCount: voteCount,
            tagline: nil,
            certification: certification,
            cast: cast,
            videos: videos,
            recommendations: recommendations
        )
    }
}

extension CastMember {
    static func fixture(
        id: Int = 1190667,
        name: String = "Timothée Chalamet",
        character: String = "Paul Atreides",
        profilePath: ImagePath? = nil
    ) -> CastMember {
        CastMember(id: id, name: name, character: character, profilePath: profilePath)
    }
}

extension Video {
    static func fixture(
        key: String = "trailer-key",
        name: String = "Official Trailer",
        kind: Kind = .trailer,
        isOfficial: Bool = true,
        publishedAt: Date? = .fixture(year: 2023, month: 12, day: 21)
    ) -> Video {
        Video(id: key, key: key, name: name, kind: kind, isOfficial: isOfficial, publishedAt: publishedAt)
    }
}

extension WatchProgress {
    static func fixture(
        contentID: Int = 693134,
        mediaType: MediaType = .movie,
        position: Duration = .seconds(95),
        duration: Duration = .seconds(153),
        lastWatchedAt: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> WatchProgress {
        WatchProgress(
            userID: UserID(rawValue: "local:test"),
            contentID: contentID,
            mediaType: mediaType,
            position: position,
            duration: duration,
            videoKey: "trailer-\(contentID)",
            lastWatchedAt: lastWatchedAt
        )
    }
}

extension Page where Item == Movie {
    static func fixture(_ movies: [Movie]) -> Page<Movie> {
        Page(number: 1, items: movies, totalPages: 1, totalResults: movies.count)
    }
}
