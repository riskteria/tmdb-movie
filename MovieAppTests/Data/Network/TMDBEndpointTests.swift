import Foundation
@testable import MovieApp
import Testing

struct TMDBEndpointTests {
    @Test(arguments: TMDBEndpointExpectation.all)
    func buildsRequest(expectation: TMDBEndpointExpectation) throws {
        // When
        let request = try expectation.endpoint.asURLRequest()

        // Assert
        #expect(request.httpMethod == expectation.method)
        #expect(request.url?.absoluteString == expectation.url)
        #expect(request.httpBody.flatMap { String(bytes: $0, encoding: .utf8) } == expectation.body)
    }

    @Test
    func requestWithBodySendsJSONContentType() throws {
        // Given
        let endpoint = TMDBEndpoint.createAccessToken(request: .init(requestToken: "request-token"))

        // When
        let request = try endpoint.asURLRequest()

        // Assert
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test
    func accountMoviesRequiresUserAccessToken() {
        // Given
        let endpoint = TMDBEndpoint.accountMovies(accountObjectID: "4bc889", category: .watchlist, parameters: .init())

        // Assert
        #expect(endpoint.authorization == .userAccessToken)
    }

    @Test
    func sessionBasedWriteUsesReadAccessToken() {
        // Given
        let endpoint = TMDBEndpoint.addFavorite(
            accountID: 548,
            parameters: .init(sessionID: "session"),
            request: .init(mediaID: 550, favorite: true)
        )

        // Assert
        #expect(endpoint.authorization == .readAccessToken)
    }
}

struct TMDBEndpointExpectation: Sendable, CustomTestStringConvertible {
    let endpoint: TMDBEndpoint
    let method: String
    let url: String
    var body: String?

    var testDescription: String {
        "\(method) \(url)"
    }
}

extension TMDBEndpointExpectation {
    private static let baseURL = "https://api.themoviedb.org"

    static let all: [TMDBEndpointExpectation] = content + auth + account

    private static let content = [
        TMDBEndpointExpectation(endpoint: .configuration, method: "GET", url: "\(baseURL)/3/configuration"),
        TMDBEndpointExpectation(
            endpoint: .movieGenres(parameters: .init(language: "en-US")),
            method: "GET",
            url: "\(baseURL)/3/genre/movie/list?language=en-US"
        ),
        TMDBEndpointExpectation(
            endpoint: .trendingMovies(timeWindow: .week, parameters: .init()),
            method: "GET",
            url: "\(baseURL)/3/trending/movie/week"
        ),
        TMDBEndpointExpectation(
            endpoint: .movieList(category: .nowPlaying, parameters: .init(page: 2, region: "ID")),
            method: "GET",
            url: "\(baseURL)/3/movie/now_playing?page=2&region=ID"
        ),
        TMDBEndpointExpectation(
            endpoint: .discoverMovies(
                parameters: .init(sortBy: .voteAverageDescending, minimumVoteCount: 200, withGenres: "28|12")
            ),
            method: "GET",
            url: "\(baseURL)/3/discover/movie"
                + "?include_adult=false&include_video=false&sort_by=vote_average.desc&vote_count.gte=200"
                + "&with_genres=28%7C12"
        ),
        TMDBEndpointExpectation(
            endpoint: .searchMovies(parameters: .init(query: "dune part two", page: 1)),
            method: "GET",
            url: "\(baseURL)/3/search/movie?include_adult=false&page=1&query=dune%20part%20two"
        ),
        TMDBEndpointExpectation(
            endpoint: .movieDetails(
                movieID: 693134,
                parameters: .init(appendToResponse: [.credits, .watchProviders, .accountStates], sessionID: "session")
            ),
            method: "GET",
            url: "\(baseURL)/3/movie/693134?append_to_response=credits%2Cwatch/providers%2Caccount_states"
                + "&session_id=session"
        ),
        TMDBEndpointExpectation(
            endpoint: .personDetails(personID: 287, parameters: .init(appendToResponse: [.movieCredits, .images])),
            method: "GET",
            url: "\(baseURL)/3/person/287?append_to_response=movie_credits%2Cimages"
        )
    ]

    private static let auth = [
        TMDBEndpointExpectation(
            endpoint: .createRequestToken(request: .init(redirectTo: "movieapp://auth")),
            method: "POST",
            url: "\(baseURL)/4/auth/request_token",
            body: #"{"redirect_to":"movieapp://auth"}"#
        ),
        TMDBEndpointExpectation(
            endpoint: .createAccessToken(request: .init(requestToken: "request-token")),
            method: "POST",
            url: "\(baseURL)/4/auth/access_token",
            body: #"{"request_token":"request-token"}"#
        ),
        TMDBEndpointExpectation(
            endpoint: .deleteAccessToken(request: .init(accessToken: "access-token")),
            method: "DELETE",
            url: "\(baseURL)/4/auth/access_token",
            body: #"{"access_token":"access-token"}"#
        ),
        TMDBEndpointExpectation(
            endpoint: .createSessionFromAccessToken(request: .init(accessToken: "access-token")),
            method: "POST",
            url: "\(baseURL)/3/authentication/session/convert/4",
            body: #"{"access_token":"access-token"}"#
        ),
        TMDBEndpointExpectation(
            endpoint: .deleteSession(request: .init(sessionID: "session")),
            method: "DELETE",
            url: "\(baseURL)/3/authentication/session",
            body: #"{"session_id":"session"}"#
        )
    ]

    private static let account = [
        TMDBEndpointExpectation(
            endpoint: .accountMovies(
                accountObjectID: "4bc889",
                category: .rated,
                parameters: .init(page: 1, sortBy: .createdAtDescending)
            ),
            method: "GET",
            url: "\(baseURL)/4/account/4bc889/movie/rated?page=1&sort_by=created_at.desc"
        ),
        TMDBEndpointExpectation(
            endpoint: .accountDetails(accountID: 548, parameters: .init(sessionID: "session")),
            method: "GET",
            url: "\(baseURL)/3/account/548?session_id=session"
        ),
        TMDBEndpointExpectation(
            endpoint: .addFavorite(
                accountID: 548,
                parameters: .init(sessionID: "session"),
                request: .init(mediaID: 550, favorite: true)
            ),
            method: "POST",
            url: "\(baseURL)/3/account/548/favorite?session_id=session",
            body: #"{"favorite":true,"media_id":550,"media_type":"movie"}"#
        ),
        TMDBEndpointExpectation(
            endpoint: .addToWatchlist(
                accountID: 548,
                parameters: .init(sessionID: "session"),
                request: .init(mediaID: 550, watchlist: false)
            ),
            method: "POST",
            url: "\(baseURL)/3/account/548/watchlist?session_id=session",
            body: #"{"media_id":550,"media_type":"movie","watchlist":false}"#
        ),
        TMDBEndpointExpectation(
            endpoint: .addRating(movieID: 550, parameters: .init(sessionID: "session"), request: .init(value: 8.5)),
            method: "POST",
            url: "\(baseURL)/3/movie/550/rating?session_id=session",
            body: #"{"value":8.5}"#
        ),
        TMDBEndpointExpectation(
            endpoint: .deleteRating(movieID: 550, parameters: .init(sessionID: "session")),
            method: "DELETE",
            url: "\(baseURL)/3/movie/550/rating?session_id=session"
        )
    ]
}
