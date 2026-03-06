// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "JTSImageViewController",
    platforms: [.iOS(.v26)],
    products: [.library(name: "JTSImageViewController", targets: ["JTSImageViewController"])],
    targets: [
        .target(
            name: "JTSImageViewController",
            path: "Sources",
            publicHeadersPath: "include"
        )
    ]
)
