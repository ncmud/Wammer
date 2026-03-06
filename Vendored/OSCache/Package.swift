// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "OSCache",
    platforms: [.iOS(.v26)],
    products: [.library(name: "OSCache", targets: ["OSCache"])],
    targets: [
        .target(
            name: "OSCache",
            path: "Sources",
            publicHeadersPath: "include"
        )
    ]
)
