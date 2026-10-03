import Alamofire
import Foundation
@testable import MovieApp

struct APIServiceStub: IAPIService {
    let endpoint: TMDBEndpoint
    let result: Result<String, any Error>
    
    func request<Response: Decodable & Sendable>(_ endpoint: MovieApp.TMDBEndpoint) async throws -> Response {
        let request = try endpoint.asURLRequest()
        let expected = try request.asURLRequest()
        
        guard
            request.httpMethod == expected.httpMethod,
            request.url == expected.url,
            request.httpBody == expected.httpBody
        else {
            throw StubError.failed
        }
        
        return try TMDBJSON.decode(Response.self, from: result.get())
    }
}
