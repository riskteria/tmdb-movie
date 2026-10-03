import Alamofire
import Foundation
@testable import MovieApp

extension APIService {
    static func makeStub() -> APIService {
        let configuration = URLSessionConfiguration.af.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = Session(configuration: configuration)
        return APIService(session: session)
    }
}
