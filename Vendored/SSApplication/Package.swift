// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "SSApplication",
    platforms: [.iOS(.v26)],
    products: [.library(name: "SSApplication", targets: ["SSApplication"])],
    targets: [
        .target(
            name: "SSApplication",
            path: "Sources",
            publicHeadersPath: "include"
        )
    ]
)
