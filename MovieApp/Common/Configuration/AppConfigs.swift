import ArkanaKeys

nonisolated struct AppConfigs: Sendable {
    static let shared = AppConfigs()

    var tmdbReadAccessToken: String {
        Keys.Global().tmdbReadAccessToken
    }
}
