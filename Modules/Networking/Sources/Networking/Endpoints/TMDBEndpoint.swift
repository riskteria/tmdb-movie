import Alamofire
import Foundation

public nonisolated enum TMDBEndpoint {
    enum Authorization: Sendable {
        case readAccessToken
        case userAccessToken
    }

    case configuration
    case movieGenres(parameters: MovieGenresDTO.Parameters)
    case trendingMovies(timeWindow: TrendingMoviesDTO.TimeWindow, parameters: TrendingMoviesDTO.Parameters)
    case movieList(category: MovieListDTO.Category, parameters: MovieListDTO.Parameters)
    case discoverMovies(parameters: DiscoverMoviesDTO.Parameters)
    case searchMovies(parameters: SearchMoviesDTO.Parameters)
    case movieDetails(movieID: Int, parameters: MovieDetailsDTO.Parameters)
    case personDetails(personID: Int, parameters: PersonDetailsDTO.Parameters)

    case createRequestToken(request: CreateRequestTokenDTO.Request)
    case createAccessToken(request: CreateAccessTokenDTO.Request)
    case deleteAccessToken(request: DeleteAccessTokenDTO.Request)
    case createSessionFromAccessToken(request: CreateSessionFromAccessTokenDTO.Request)
    case deleteSession(request: DeleteSessionDTO.Request)

    case accountMovies(
        accountObjectID: String,
        category: AccountMoviesDTO.Category,
        parameters: AccountMoviesDTO.Parameters
    )
    // v4 has no favorite, watchlist or rating writes. These v3 endpoints take the session ID
    // from `createSessionFromAccessToken`.
    case accountDetails(accountID: Int, parameters: AccountDetailsDTO.Parameters)
    case addFavorite(accountID: Int, parameters: AddFavoriteDTO.Parameters, request: AddFavoriteDTO.Request)
    case addToWatchlist(accountID: Int, parameters: AddToWatchlistDTO.Parameters, request: AddToWatchlistDTO.Request)
    case addRating(movieID: Int, parameters: AddRatingDTO.Parameters, request: AddRatingDTO.Request)
    case deleteRating(movieID: Int, parameters: DeleteRatingDTO.Parameters)
}

nonisolated extension TMDBEndpoint {
    private static let baseURL = "https://api.themoviedb.org"

    private static let queryEncoder = URLEncodedFormParameterEncoder(
        encoder: URLEncodedFormEncoder(boolEncoding: .literal, keyEncoding: .convertToSnakeCase),
        destination: .queryString
    )

    private static let bodyEncoder: JSONParameterEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return JSONParameterEncoder(encoder: encoder)
    }()

    var method: HTTPMethod {
        switch self {
        case .configuration, .movieGenres, .trendingMovies, .movieList, .discoverMovies, .searchMovies,
            .movieDetails, .personDetails, .accountMovies, .accountDetails:
            .get
        case .createRequestToken, .createAccessToken, .createSessionFromAccessToken, .addFavorite,
            .addToWatchlist, .addRating:
            .post
        case .deleteAccessToken, .deleteSession, .deleteRating:
            .delete
        }
    }

    var path: String {
        switch self {
        case .configuration:
            "/3/configuration"
        case .movieGenres:
            "/3/genre/movie/list"
        case .trendingMovies(let timeWindow, _):
            "/3/trending/movie/\(timeWindow.rawValue)"
        case .movieList(let category, _):
            "/3/movie/\(category.rawValue)"
        case .discoverMovies:
            "/3/discover/movie"
        case .searchMovies:
            "/3/search/movie"
        case .movieDetails(let movieID, _):
            "/3/movie/\(movieID)"
        case .personDetails(let personID, _):
            "/3/person/\(personID)"
        case .createRequestToken:
            "/4/auth/request_token"
        case .createAccessToken, .deleteAccessToken:
            "/4/auth/access_token"
        case .createSessionFromAccessToken:
            "/3/authentication/session/convert/4"
        case .deleteSession:
            "/3/authentication/session"
        case let .accountMovies(accountObjectID, category, _):
            "/4/account/\(accountObjectID)/movie/\(category.rawValue)"
        case .accountDetails(let accountID, _):
            "/3/account/\(accountID)"
        case .addFavorite(let accountID, _, _):
            "/3/account/\(accountID)/favorite"
        case .addToWatchlist(let accountID, _, _):
            "/3/account/\(accountID)/watchlist"
        case .addRating(let movieID, _, _), .deleteRating(let movieID, _):
            "/3/movie/\(movieID)/rating"
        }
    }

    var parameters: (any Encodable & Sendable)? {
        switch self {
        case .configuration, .createRequestToken, .createAccessToken, .deleteAccessToken,
            .createSessionFromAccessToken, .deleteSession:
            nil
        case .movieGenres(let parameters):
            parameters
        case .trendingMovies(_, let parameters):
            parameters
        case .movieList(_, let parameters):
            parameters
        case .discoverMovies(let parameters):
            parameters
        case .searchMovies(let parameters):
            parameters
        case .movieDetails(_, let parameters):
            parameters
        case .personDetails(_, let parameters):
            parameters
        case .accountMovies(_, _, let parameters):
            parameters
        case .accountDetails(_, let parameters),
            .addFavorite(_, let parameters, _),
            .addToWatchlist(_, let parameters, _),
            .addRating(_, let parameters, _),
            .deleteRating(_, let parameters):
            parameters
        }
    }

    var body: (any Encodable & Sendable)? {
        switch self {
        case .configuration, .movieGenres, .trendingMovies, .movieList, .discoverMovies, .searchMovies,
            .movieDetails, .personDetails, .accountMovies, .accountDetails, .deleteRating:
            nil
        case .createRequestToken(let request):
            request
        case .createAccessToken(let request):
            request
        case .deleteAccessToken(let request):
            request
        case .createSessionFromAccessToken(let request):
            request
        case .deleteSession(let request):
            request
        case .addFavorite(_, _, let request):
            request
        case .addToWatchlist(_, _, let request):
            request
        case .addRating(_, _, let request):
            request
        }
    }

    // v4 account endpoints need the signed-in user's access token. Everything else, including the v4
    // auth calls and the session-based v3 writes, uses the app's API read access token.
    var authorization: Authorization {
        switch self {
        case .accountMovies:
            .userAccessToken
        case .configuration, .movieGenres, .trendingMovies, .movieList, .discoverMovies, .searchMovies,
            .movieDetails, .personDetails, .createRequestToken, .createAccessToken, .deleteAccessToken,
            .createSessionFromAccessToken, .deleteSession, .accountDetails, .addFavorite, .addToWatchlist,
            .addRating, .deleteRating:
            .readAccessToken
        }
    }
}

// MARK: - URLRequestConvertible
nonisolated extension TMDBEndpoint: URLRequestConvertible {
    public func asURLRequest() throws -> URLRequest {
        var request = try URLRequest(url: Self.baseURL + path, method: method)
        if let parameters {
            request = try Self.queryEncoder.encode(parameters, into: request)
        }
        if let body {
            request = try Self.bodyEncoder.encode(body, into: request)
        }
        return request
    }
}
