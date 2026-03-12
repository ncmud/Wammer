// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "SSOperations",
    platforms: [.iOS(.v26), .visionOS(.v26)],
    products: [.library(name: "SSOperations", targets: ["SSOperations"])],
    targets: [
        .target(
            name: "SSOperations",
            path: "Sources",
            publicHeadersPath: "include",
            cSettings: [.unsafeFlags(["-Wmost"])]
        )
    ]
)
