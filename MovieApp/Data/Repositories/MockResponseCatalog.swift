import Foundation

nonisolated enum MockResponseCatalog {
    static let genres = [
        Genre(id: 28, name: "Action"),
        Genre(id: 12, name: "Adventure"),
        Genre(id: 16, name: "Animation"),
        Genre(id: 35, name: "Comedy"),
        Genre(id: 80, name: "Crime"),
        Genre(id: 99, name: "Documentary"),
        Genre(id: 18, name: "Drama"),
        Genre(id: 10751, name: "Family"),
        Genre(id: 14, name: "Fantasy"),
        Genre(id: 36, name: "History"),
        Genre(id: 27, name: "Horror"),
        Genre(id: 10402, name: "Music"),
        Genre(id: 9648, name: "Mystery"),
        Genre(id: 10749, name: "Romance"),
        Genre(id: 878, name: "Science Fiction"),
        Genre(id: 10770, name: "TV Movie"),
        Genre(id: 53, name: "Thriller"),
        Genre(id: 10752, name: "War"),
        Genre(id: 37, name: "Western")
    ]

    static let duneTwo = movie(693134, "Dune: Part Two", "2024-02-27", [878, 12], 8.2)
    static let wildRobot = movie(1184918, "The Wild Robot", "2024-09-12", [16, 10751], 8.3)
    static let furiosa = movie(786892, "Furiosa: A Mad Max Saga", "2024-05-22", [28, 12], 7.5)
    static let insideOutTwo = movie(1022789, "Inside Out 2", "2024-06-11", [16, 35], 7.6)
    static let deadpool = movie(533535, "Deadpool & Wolverine", "2024-07-24", [28, 35], 7.7)
    static let wicked = movie(402431, "Wicked", "2024-11-20", [14, 10749], 7.4)
    static let gladiatorTwo = movie(558449, "Gladiator II", "2024-11-13", [28, 18], 6.8)
    static let kungFuPanda = movie(1011985, "Kung Fu Panda 4", "2024-03-02", [16, 28], 7.1)
    static let darkKnight = movie(155, "The Dark Knight", "2008-07-16", [28, 80], 8.5)
    static let interstellar = movie(157336, "Interstellar", "2014-11-05", [878, 18], 8.4)
    static let parasite = movie(496243, "Parasite", "2019-05-30", [53, 18], 8.5)
    static let spiritedAway = movie(129, "Spirited Away", "2001-07-20", [16, 14], 8.5)
    static let challengers = movie(937287, "Challengers", "2024-04-18", [18, 10749], 7.0)
    static let civilWar = movie(929590, "Civil War", "2024-04-10", [10752, 28], 6.9)
    static let alienRomulus = movie(945961, "Alien: Romulus", "2024-08-13", [27, 878], 7.2)
    static let godzillaKong = movie(823464, "Godzilla x Kong: The New Empire", "2024-03-27", [878, 28], 7.2)
    static let oppenheimer = movie(872585, "Oppenheimer", "2023-07-19", [18, 36], 8.1)
    static let poorThings = movie(792307, "Poor Things", "2023-12-07", [878, 10749], 7.7)

    static let trending = [duneTwo, wildRobot, furiosa, insideOutTwo, deadpool, oppenheimer]
    static let popular = [insideOutTwo, deadpool, wicked, gladiatorTwo, kungFuPanda]
    static let topRated = [darkKnight, interstellar, parasite, spiritedAway, gladiatorTwo, kungFuPanda]
    static let upcoming = [challengers, civilWar, alienRomulus, godzillaKong]

    static let allMovies = trending + popular + topRated + upcoming + [poorThings]

    static var savedMovies: [SavedMovie] {
        [duneTwo, furiosa, civilWar, challengers, wildRobot, poorThings]
            .enumerated()
            .map { index, movie in SavedMovie(movie: movie, savedAt: .now.addingTimeInterval(Double(-index) * 3_600)) }
    }

    static func watchProgress(for userID: UserID) -> [WatchProgress] {
        [
            progress(of: oppenheimer, position: .seconds(95), duration: .seconds(153), minutesAgo: 10, userID: userID),
            progress(of: challengers, position: .seconds(54), duration: .seconds(154), minutesAgo: 90, userID: userID),
            progress(of: wildRobot, position: .seconds(84), duration: .seconds(105), minutesAgo: 600, userID: userID)
        ]
    }

    static func details(for movie: Movie) -> MovieDetails {
        let runtimeMinutes = [693134: 166, 872585: 181, 157336: 169, 155: 152, 1184918: 102]
        return MovieDetails(
            movie: movie,
            runtime: .seconds((runtimeMinutes[movie.id] ?? 118) * 60),
            genres: movie.genreIDs.compactMap { genreID in genres.first { $0.id == genreID } },
            voteCount: 0,
            tagline: nil,
            certification: "PG-13",
            cast: [],
            videos: [],
            recommendations: []
        )
    }

    private static func movie(
        _ id: Int,
        _ title: String,
        _ releaseDate: String,
        _ genreIDs: [Genre.ID],
        _ voteAverage: Double
    ) -> Movie {
        Movie(
            id: id,
            title: title,
            overview: "A preview summary for \(title). Real overviews arrive with TMDB data in Week 2.",
            releaseDate: try? Date(releaseDate, strategy: .iso8601.year().month().day()),
            posterPath: nil,
            backdropPath: nil,
            genreIDs: genreIDs,
            voteAverage: voteAverage
        )
    }

    private static func progress(
        of movie: Movie,
        position: Duration,
        duration: Duration,
        minutesAgo: Double,
        userID: UserID
    ) -> WatchProgress {
        WatchProgress(
            userID: userID,
            contentID: movie.id,
            mediaType: .movie,
            position: position,
            duration: duration,
            videoKey: "preview-\(movie.id)",
            lastWatchedAt: .now.addingTimeInterval(-minutesAgo * 60)
        )
    }
}
