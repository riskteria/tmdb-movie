import Foundation
@testable import MovieApp
@testable import Networking
import Testing

struct APIServiceStub: IAPIService {
    let endpoint: TMDBEndpoint
    let result: Result<String, any Error>

    func request<Response: Decodable & Sendable>(_ requestedEndpoint: TMDBEndpoint) async throws -> Response {
        let request = try requestedEndpoint.asURLRequest()
        let expected = try endpoint.asURLRequest()

        try #require(request.httpMethod == expected.httpMethod)
        try #require(request.url == expected.url)
        try #require(request.httpBody == expected.httpBody)

        return try TMDBJSON.decode(Response.self, from: result.get())
    }
}
