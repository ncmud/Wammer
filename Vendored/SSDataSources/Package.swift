// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "SSDataSources",
    platforms: [.iOS(.v26)],
    products: [.library(name: "SSDataSources", targets: ["SSDataSources"])],
    targets: [
        .target(
            name: "SSDataSources",
            path: "Sources",
            publicHeadersPath: "include",
            cSettings: [.unsafeFlags(["-w"])]
        )
    ]
)
