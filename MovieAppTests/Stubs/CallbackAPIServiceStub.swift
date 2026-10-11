import Foundation
@testable import Networking
import Testing

struct CallbackAPIServiceStub: ICallbackAPIService {
    let endpoint: TMDBEndpoint
    let result: Result<String, any Error>

    func request<Response: Decodable & Sendable>(
        _ requestedEndpoint: TMDBEndpoint,
        completion: @escaping @Sendable (Result<Response, any Error>) -> Void
    ) -> APIRequestHandle {
        let request = try? requestedEndpoint.asURLRequest()
        let expected = try? endpoint.asURLRequest()

        #expect(request?.httpMethod == expected?.httpMethod)
        #expect(request?.url == expected?.url)
        #expect(request?.httpBody == expected?.httpBody)

        completion(Result { try TMDBJSON.decode(Response.self, from: result.get()) })
        return APIRequestHandle {}
    }
}
