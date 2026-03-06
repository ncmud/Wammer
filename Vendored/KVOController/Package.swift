// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "KVOController",
    platforms: [.iOS(.v26)],
    products: [.library(name: "KVOController", targets: ["KVOController"])],
    targets: [
        .target(
            name: "KVOController",
            path: "Sources",
            publicHeadersPath: "include"
        )
    ]
)
