// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "SAMRateLimit",
    platforms: [.iOS(.v26)],
    products: [.library(name: "SAMRateLimit", targets: ["SAMRateLimit"])],
    targets: [
        .target(
            name: "SAMRateLimit",
            path: "Sources",
            publicHeadersPath: "include",
            cSettings: [.unsafeFlags(["-Wmost"])]
        )
    ]
)
