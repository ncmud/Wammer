// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "Masonry",
    platforms: [.iOS(.v26), .visionOS(.v26)],
    products: [.library(name: "Masonry", targets: ["Masonry"])],
    targets: [
        .target(
            name: "Masonry",
            path: "Sources",
            publicHeadersPath: "include",
            cSettings: [.unsafeFlags(["-Wmost"])]
        )
    ]
)
