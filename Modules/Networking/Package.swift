// swift-tools-version: 6.2
import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances")
]

let package = Package(
    name: "Networking",
    platforms: [.iOS("26.5")],
    products: [
        .library(name: "Networking", targets: ["Networking"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.12.2")
    ],
    targets: [
        .target(
            name: "Networking",
            dependencies: ["Alamofire"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "NetworkingTests",
            dependencies: ["Networking", "Alamofire"],
            swiftSettings: swiftSettings
        )
    ]
)
