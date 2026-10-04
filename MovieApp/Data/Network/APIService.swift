import Alamofire
import Foundation
import os

nonisolated protocol IAPIService: Sendable {
    func request<Response: Decodable & Sendable>(_ endpoint: TMDBEndpoint) async throws -> Response
}

nonisolated final class APIService: Sendable {
    static let shared = APIService(
        interceptor: ReadAccessTokenInterceptor(token: AppConfigs.shared.tmdbReadAccessToken)
    )

    private let session: Session
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: "com.enkidu.MovieApp", category: "network")

    init(configuration: URLSessionConfiguration = .af.default, interceptor: (any RequestInterceptor)? = nil) {
        session = Session(configuration: configuration, interceptor: interceptor)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }
}

nonisolated extension APIService: IAPIService {
    func request<Response: Decodable & Sendable>(_ endpoint: TMDBEndpoint) async throws -> Response {
        let response = await session.request(endpoint)
            .validate()
            .serializingDecodable(Response.self, decoder: decoder)
            .response
        log(response, for: endpoint)

        switch response.result {
        case .success(let value):
            return value
        case .failure(let error) where error.isExplicitlyCancelledError:
            throw CancellationError()
        case .failure(let error):
            throw NetworkError(error)
        }
    }
}

private nonisolated extension APIService {
    func log<Value>(_ response: DataResponse<Value, AFError>, for endpoint: TMDBEndpoint) {
        #if DEBUG
        let request = response.request
        let method = request?.httpMethod ?? endpoint.method.rawValue
        let url = request?.url?.absoluteString ?? endpoint.path
        let status = response.response.map { String($0.statusCode) } ?? "-"
        let requestLog = """
            [Request] \(method) \(url)
            Headers: \(Self.describe(request?.headers))
            Body: \(Self.describe(request?.httpBody))
            """
        let responseLog = """
            [Response] \(status) \(method) \(url)
            Headers: \(Self.describe(response.response?.headers))
            Body: \(Self.describe(response.data))
            """
        logger.debug("\(requestLog, privacy: .public)")
        logger.debug("\(responseLog, privacy: .public)")
        #endif
    }

    static func describe(_ headers: HTTPHeaders?) -> String {
        guard let headers, !headers.isEmpty else { return "-" }
        return headers
            .map { header in
                let isSecret = header.name.caseInsensitiveCompare("Authorization") == .orderedSame
                return "\(header.name): \(isSecret ? "<redacted>" : header.value)"
            }
            .joined(separator: ", ")
    }

    static func describe(_ body: Data?) -> String {
        guard let body, !body.isEmpty else { return "-" }
        return String(bytes: body, encoding: .utf8) ?? "<\(body.count) bytes, not UTF-8>"
    }
}
