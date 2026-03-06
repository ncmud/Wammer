// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "MagicalRecord",
    platforms: [.iOS(.v26)],
    products: [.library(name: "MagicalRecord", targets: ["MagicalRecord"])],
    targets: [
        .target(
            name: "MagicalRecord",
            path: "Sources",
            publicHeadersPath: "include",
            cSettings: [.unsafeFlags(["-w"])]
        )
    ]
)
