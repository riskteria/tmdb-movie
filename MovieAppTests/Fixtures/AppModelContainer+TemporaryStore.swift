import Foundation
@testable import MovieApp

extension AppModelContainer {
    init(temporaryStoreID: UUID) {
        self.init(storeURL: .temporaryDirectory.appending(path: "MovieAppTests/\(temporaryStoreID.uuidString).store"))
    }
}
