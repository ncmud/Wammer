// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "libextobjc",
    platforms: [.iOS(.v26)],
    products: [.library(name: "libextobjc", targets: ["libextobjc"])],
    targets: [
        .target(
            name: "libextobjc",
            path: "Sources",
            publicHeadersPath: "include",
            cSettings: [.unsafeFlags(["-Wmost"])]
        )
    ]
)
